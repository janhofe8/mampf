import UIKit
import ImageIO
import CoreImage

@MainActor
final class ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let session: URLSession

    private init() {
        memoryCache.countLimit = 300
        memoryCache.totalCostLimit = 80 * 1024 * 1024 // 80 MB of decoded pixels
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 20_000_000, diskCapacity: 200_000_000)
        session = URLSession(configuration: config)
    }

    /// Fetch a downsampled image sized for the given display bucket.
    /// The disk cache still stores the original bytes; we decode into a small thumbnail
    /// so memory stays tight and scrolling is smooth.
    func image(for url: URL, maxPixelSize: CGFloat) async -> UIImage? {
        let key = cacheKey(url: url, maxPixelSize: maxPixelSize)
        if let cached = memoryCache.object(forKey: key) {
            return cached
        }

        do {
            let (data, _) = try await session.data(from: url)
            let maxPixels = max(1, Int(maxPixelSize.rounded(.up)))
            // Apply the foodie-preset only to our own photos — Google Places photos
            // already come edited by the restaurant/owner.
            let enhance = url.path.contains("/own/")
            guard let image = await Self.downsample(data: data, maxPixelSize: maxPixels, enhance: enhance) else {
                return nil
            }
            let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
            memoryCache.setObject(image, forKey: key, cost: cost)
            return image
        } catch {
            return nil
        }
    }

    private func cacheKey(url: URL, maxPixelSize: CGFloat) -> NSString {
        "\(url.absoluteString)|\(Int(maxPixelSize.rounded(.up)))" as NSString
    }

    /// Decode off the main thread into a thumbnail at the requested pixel size.
    /// When `enhance` is true, apply the foodie preset (warmth + saturation + contrast)
    /// for a consistent look across self-shot photos.
    nonisolated private static func downsample(data: Data, maxPixelSize: Int, enhance: Bool) async -> UIImage? {
        await Task.detached(priority: .userInitiated) { () -> UIImage? in
            let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
            guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
                return nil
            }
            let downsampleOptions: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
            ]
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
                return nil
            }

            if enhance, let enhanced = applyFoodPreset(cgImage) {
                return enhanced
            }
            return UIImage(cgImage: cgImage)
        }.value
    }

    /// Adaptive exposure + foodie look for own photos.
    /// Measures each photo's average luminance, pulls it toward a common target,
    /// then lifts shadows and applies a mild warmth/saturation boost so everything
    /// reads at a consistent level — dark photos brighten, bright photos stay in check.
    nonisolated private static func applyFoodPreset(_ cgImage: CGImage) -> UIImage? {
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: [.useSoftwareRenderer: false])

        // Step 1: measure the image's average luminance (perceptual Rec. 709)
        let avgFilter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: ciImage,
            kCIInputExtentKey: CIVector(cgRect: ciImage.extent)
        ])
        var pixel = [UInt8](repeating: 0, count: 4)
        if let avg = avgFilter?.outputImage {
            context.render(avg,
                           toBitmap: &pixel,
                           rowBytes: 4,
                           bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                           format: .RGBA8,
                           colorSpace: nil)
        }
        let r = Double(pixel[0]) / 255.0
        let g = Double(pixel[1]) / 255.0
        let b = Double(pixel[2]) / 255.0
        let luminance = max(0.05, 0.2126 * r + 0.7152 * g + 0.0722 * b)

        // Slightly lower target — the highlight/saturation stack adds perceived brightness
        // on top, so we pull the midtone only part of the way to 0.5.
        let targetLuminance = 0.45

        // Step 2: gamma correction lifts midtones without clipping highlights.
        // power = log(target) / log(luminance). Clamp to a safe range.
        let rawPower = log(targetLuminance) / log(luminance)
        let gamma = max(0.55, min(1.25, rawPower))
        let gammaAdjusted = CIFilter(name: "CIGammaAdjust", parameters: [
            kCIInputImageKey: ciImage,
            "inputPower": gamma
        ])?.outputImage ?? ciImage

        // Step 3: tame highlights hard, lift shadows a touch — prevents blown whites
        // while keeping dark corners readable
        let balanced = CIFilter(name: "CIHighlightShadowAdjust", parameters: [
            kCIInputImageKey: gammaAdjusted,
            "inputHighlightAmount": 0.65,
            "inputShadowAmount": 0.25
        ])?.outputImage ?? gammaAdjusted

        // Step 4: gentle warmth — smaller shift than before
        let warmed = CIFilter(name: "CITemperatureAndTint", parameters: [
            kCIInputImageKey: balanced,
            "inputNeutral": CIVector(x: 6500, y: 0),
            "inputTargetNeutral": CIVector(x: 6650, y: 0)
        ])?.outputImage ?? balanced

        // Step 5: modest saturation + contrast — food pops without blowing out
        let final = CIFilter(name: "CIColorControls", parameters: [
            kCIInputImageKey: warmed,
            kCIInputSaturationKey: 1.13,
            kCIInputContrastKey: 1.03
        ])?.outputImage ?? warmed

        guard let rendered = context.createCGImage(final, from: ciImage.extent) else {
            return UIImage(cgImage: cgImage)
        }
        return UIImage(cgImage: rendered)
    }
}
