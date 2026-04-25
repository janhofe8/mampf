import SwiftUI
import MapKit

/// UIKit-bridged map. Replaces SwiftUI `Map { Annotation { … } }` to avoid
/// per-frame SwiftUI view recomposition for ~80+ pins. Annotations are
/// pre-rendered `UIImage`s with baked-in shadow — same approach Google/Apple
/// Maps use natively.
struct MapKitMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let pins: [Restaurant]
    let userLocation: CLLocationCoordinate2D?
    var onTap: (Restaurant) -> Void
    var onRegionChange: (MKCoordinateRegion, _ userInitiated: Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MKMapView {
        let mv = MKMapView()
        mv.delegate = context.coordinator
        mv.showsUserLocation = false
        mv.pointOfInterestFilter = .excludingAll
        mv.setRegion(region, animated: false)

        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleUserGesture(_:)))
        pan.delegate = context.coordinator
        mv.addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: context.coordinator,
                                             action: #selector(Coordinator.handleUserGesture(_:)))
        pinch.delegate = context.coordinator
        mv.addGestureRecognizer(pinch)

        return mv
    }

    func updateUIView(_ mv: MKMapView, context: Context) {
        let c = context.coordinator
        c.parent = self

        if !c.isUserInteracting && !regionsApproximatelyEqual(mv.region, region) {
            mv.setRegion(region, animated: true)
        }
        c.syncAnnotations(in: mv, with: pins, userLocation: userLocation)
    }

    private func regionsApproximatelyEqual(_ a: MKCoordinateRegion, _ b: MKCoordinateRegion) -> Bool {
        abs(a.center.latitude - b.center.latitude) < 1e-5 &&
        abs(a.center.longitude - b.center.longitude) < 1e-5 &&
        abs(a.span.latitudeDelta - b.span.latitudeDelta) < 1e-5 &&
        abs(a.span.longitudeDelta - b.span.longitudeDelta) < 1e-5
    }

    final class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: MapKitMapView
        var isUserInteracting = false
        private var userAnnotation: MKPointAnnotation?

        init(_ parent: MapKitMapView) { self.parent = parent }

        @objc func handleUserGesture(_ gr: UIGestureRecognizer) {
            switch gr.state {
            case .began, .changed: isUserInteracting = true
            default: break
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }

        func syncAnnotations(in mv: MKMapView,
                             with restaurants: [Restaurant],
                             userLocation: CLLocationCoordinate2D?) {
            var existingByID: [UUID: RestaurantAnnotation] = [:]
            for ann in mv.annotations {
                if let r = ann as? RestaurantAnnotation { existingByID[r.restaurantId] = r }
            }
            let newIds = Set(restaurants.map(\.id))

            var toRemove: [MKAnnotation] = []
            var toAdd: [RestaurantAnnotation] = []

            for (id, ann) in existingByID where !newIds.contains(id) {
                toRemove.append(ann)
            }
            for r in restaurants {
                if let existing = existingByID[r.id] {
                    if existing.rating != r.personalRating {
                        toRemove.append(existing)
                        toAdd.append(RestaurantAnnotation(restaurant: r))
                    }
                } else {
                    toAdd.append(RestaurantAnnotation(restaurant: r))
                }
            }
            if !toRemove.isEmpty { mv.removeAnnotations(toRemove) }
            if !toAdd.isEmpty { mv.addAnnotations(toAdd) }

            if let loc = userLocation {
                if let existing = userAnnotation {
                    if abs(existing.coordinate.latitude - loc.latitude) > 1e-6 ||
                       abs(existing.coordinate.longitude - loc.longitude) > 1e-6 {
                        existing.coordinate = loc
                    }
                } else {
                    let ann = MKPointAnnotation()
                    ann.coordinate = loc
                    userAnnotation = ann
                    mv.addAnnotation(ann)
                }
            } else if let existing = userAnnotation {
                mv.removeAnnotation(existing)
                userAnnotation = nil
            }
        }

        // MARK: MKMapViewDelegate

        func mapView(_ mv: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let r = annotation as? RestaurantAnnotation {
                let id = r.reuseIdentifier
                let view = mv.dequeueReusableAnnotationView(withIdentifier: id)
                    ?? MKAnnotationView(annotation: r, reuseIdentifier: id)
                view.annotation = r
                view.image = PinImageCache.image(for: r.rating)
                view.canShowCallout = false
                view.centerOffset = .zero
                return view
            }
            if annotation === userAnnotation {
                let id = "user-loc"
                let view = mv.dequeueReusableAnnotationView(withIdentifier: id)
                    ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
                view.annotation = annotation
                view.image = PinImageCache.userLocationImage()
                view.canShowCallout = false
                return view
            }
            return nil
        }

        func mapView(_ mv: MKMapView, didSelect view: MKAnnotationView) {
            guard let ann = view.annotation as? RestaurantAnnotation else { return }
            mv.deselectAnnotation(ann, animated: false)
            parent.onTap(ann.restaurant)
        }

        func mapView(_ mv: MKMapView, regionDidChangeAnimated animated: Bool) {
            let userInitiated = isUserInteracting
            let newRegion = mv.region
            isUserInteracting = false
            DispatchQueue.main.async { [parent] in
                parent.region = newRegion
                parent.onRegionChange(newRegion, userInitiated)
            }
        }
    }
}

// MARK: - Annotation Model

final class RestaurantAnnotation: NSObject, MKAnnotation {
    let restaurant: Restaurant
    var coordinate: CLLocationCoordinate2D { restaurant.coordinate }
    var restaurantId: UUID { restaurant.id }
    var rating: Double? { restaurant.personalRating }
    /// One reuse pool per visual variant — 19 rated values + unrated.
    var reuseIdentifier: String {
        if let r = rating { return "rated-\(Int(r * 2))" }
        return "unrated"
    }
    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        super.init()
    }
}

// MARK: - Pin Image Cache

/// Pre-renders pin images once per rating bucket. Baked-in shadow → no live blur per frame.
enum PinImageCache {
    private static var cache: [String: UIImage] = [:]
    private static let lock = NSLock()

    static func image(for rating: Double?) -> UIImage {
        let key = rating.map { "rated-\(Int($0 * 2))" } ?? "unrated"
        lock.lock()
        if let img = cache[key] { lock.unlock(); return img }
        lock.unlock()

        let img = render(rating: rating)

        lock.lock(); cache[key] = img; lock.unlock()
        return img
    }

    static func userLocationImage() -> UIImage {
        let key = "user-loc"
        lock.lock()
        if let img = cache[key] { lock.unlock(); return img }
        lock.unlock()

        let img = renderUserLocation()

        lock.lock(); cache[key] = img; lock.unlock()
        return img
    }

    private static func render(rating: Double?) -> UIImage {
        guard let r = rating else {
            let dotSize: CGFloat = 14
            let pad: CGFloat = 2
            let total = dotSize + pad * 2
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: total, height: total))
            return renderer.image { ctx in
                let rect = CGRect(x: pad, y: pad, width: dotSize, height: dotSize)
                UIColor(Color.ffMuted).setFill()
                ctx.cgContext.fillEllipse(in: rect)
            }
        }

        let isElite = r >= 9
        let circle: CGFloat = 28
        let shadowBlur: CGFloat = isElite ? 8 : 2
        let inset: CGFloat = shadowBlur + 2
        let total = circle + inset * 2

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: total, height: total))
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let circleRect = CGRect(x: inset, y: inset, width: circle, height: circle)

            let shadowColor = isElite
                ? UIColor(Color.ffPrimary).withAlphaComponent(0.65)
                : UIColor.black.withAlphaComponent(0.18)
            cg.setShadow(offset: CGSize(width: 0, height: 1), blur: shadowBlur, color: shadowColor.cgColor)
            UIColor(Color.ratingColor(for: r)).setFill()
            cg.fillEllipse(in: circleRect)
            cg.setShadow(offset: .zero, blur: 0, color: nil)

            let text = r.formattedRating as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .black),
                .foregroundColor: UIColor(Color.ratingTextColor(for: r))
            ]
            let textSize = text.size(withAttributes: attrs)
            let origin = CGPoint(x: circleRect.midX - textSize.width / 2,
                                 y: circleRect.midY - textSize.height / 2)
            text.draw(at: origin, withAttributes: attrs)
        }
    }

    private static func renderUserLocation() -> UIImage {
        let dot: CGFloat = 14
        let stroke: CGFloat = 2.5
        let pad: CGFloat = 4
        let total = dot + stroke * 2 + pad * 2

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: total, height: total))
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let outer = CGRect(x: pad, y: pad, width: dot + stroke * 2, height: dot + stroke * 2)
            cg.setShadow(offset: CGSize(width: 0, height: 1), blur: 3,
                         color: UIColor.black.withAlphaComponent(0.25).cgColor)
            UIColor.white.setFill()
            cg.fillEllipse(in: outer)
            cg.setShadow(offset: .zero, blur: 0, color: nil)

            let inner = outer.insetBy(dx: stroke, dy: stroke)
            UIColor.systemBlue.setFill()
            cg.fillEllipse(in: inner)
        }
    }
}
