import CoreLocation
import Observation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var lastLocation: CLLocationCoordinate2D?

    /// Equatable token — updates whenever the coordinate changes meaningfully.
    /// SwiftUI `.onChange` can observe this where `CLLocationCoordinate2D?` isn't Equatable.
    var lastLocationToken: String {
        guard let l = lastLocation else { return "" }
        return "\((l.latitude * 1000).rounded()),\((l.longitude * 1000).rounded())"
    }

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        if isAuthorized { manager.requestLocation() }
    }

    private var isAuthorized: Bool {
        let s = manager.authorizationStatus
        return s == .authorizedWhenInUse || s == .authorizedAlways
    }

    /// Request location permission — call only from user-initiated action
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// One-shot location refresh — e.g., when user taps the map's locate button
    func refreshLocation() {
        if isAuthorized { manager.requestLocation() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silently ignore transient location errors — distance is a nice-to-have
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if isAuthorized { manager.requestLocation() }
    }
}
