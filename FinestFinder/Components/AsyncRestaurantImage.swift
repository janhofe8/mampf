import SwiftUI

struct AsyncRestaurantImage: View {
    let url: URL?
    let cuisineIcon: String
    var cornerRadius: CGFloat = 12
    var showProgress: Bool = false
    var gradient: Bool = false
    /// Largest point dimension at which this image will be displayed.
    /// Used to downsample Google Places photos (often 1600px) to a RAM-friendly size.
    var targetSize: CGFloat = 400

    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?
    @State private var failed = false

    private var maxPixelSize: CGFloat {
        max(1, targetSize * displayScale)
    }

    var body: some View {
        if let url {
            let displayed = image ?? ImageCache.shared.cachedImage(for: url, maxPixelSize: maxPixelSize)
            Group {
                if let displayed {
                    Image(uiImage: displayed)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if failed {
                    placeholder
                } else if showProgress {
                    placeholder.overlay { ProgressView().tint(.white) }
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius).fill(.quaternary)
                }
            }
            .task(id: TaskKey(url: url, pixelSize: maxPixelSize)) {
                // image(for:) checks the cache internally; if hit, this returns synchronously
                // without touching the network — no need to pre-check here.
                if let loaded = await ImageCache.shared.image(for: url, maxPixelSize: maxPixelSize) {
                    image = loaded
                } else {
                    failed = true
                }
            }
        } else {
            placeholder
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if gradient {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(colors: [.ffPrimary.opacity(0.8), .ffTertiary], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay {
                    Text(cuisineIcon)
                        .font(.title)
                        .opacity(0.5)
                }
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.quaternary)
                .overlay {
                    Text(cuisineIcon)
                        .font(.title)
                }
        }
    }

    private struct TaskKey: Hashable {
        let url: URL
        let pixelSize: CGFloat
    }
}
