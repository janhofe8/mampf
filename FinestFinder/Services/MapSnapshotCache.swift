import MapKit
import UIKit

/// Renders and caches static MapKit snapshots — avoids paying the Map() setup cost
/// every time a detail sheet opens. Keyed by coordinate + size bucket.
@MainActor
final class MapSnapshotCache {
    static let shared = MapSnapshotCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 80
        cache.totalCostLimit = 30 * 1024 * 1024
    }

    func snapshot(for coordinate: CLLocationCoordinate2D, size: CGSize, scale: CGFloat = 2) async -> UIImage? {
        let key = Self.cacheKey(coordinate: coordinate, size: size)
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        options.size = size
        options.scale = scale
        options.mapType = .standard

        let snapshotter = MKMapSnapshotter(options: options)
        do {
            let snapshot = try await snapshotter.start()
            let image = snapshot.image
            let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
            cache.setObject(image, forKey: key, cost: cost)
            return image
        } catch {
            return nil
        }
    }

    private static func cacheKey(coordinate: CLLocationCoordinate2D, size: CGSize) -> NSString {
        let lat = (coordinate.latitude * 10_000).rounded() / 10_000
        let lon = (coordinate.longitude * 10_000).rounded() / 10_000
        return "\(lat),\(lon)|\(Int(size.width))x\(Int(size.height))" as NSString
    }
}
