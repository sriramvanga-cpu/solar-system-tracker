import Foundation
import CoreLocation
import Combine

/// Observer lat/lon. Core Location once, or manual override.
@MainActor
final class ObserverLocation: ObservableObject {
    @Published var latitude: Double = 37.7749
    @Published var longitude: Double = -122.4194
    @Published var useManual = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var statusText = "Default: San Francisco"

    private let manager = CLLocationManager()
    private var delegateBox: LocationDelegate?

    init() {
        let box = LocationDelegate(owner: self)
        delegateBox = box
        manager.delegate = box
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus
    }

    func requestLocation() {
        useManual = false
        // macOS uses always authorization (when-in-use is iOS-only).
        manager.requestAlwaysAuthorization()
        manager.requestLocation()
    }

    func applyManual(lat: Double, lon: Double) {
        useManual = true
        latitude = lat
        longitude = lon
        statusText = String(format: "Manual %.4f°, %.4f°", lat, lon)
    }

    fileprivate func update(from loc: CLLocation) {
        guard !useManual else { return }
        latitude = loc.coordinate.latitude
        longitude = loc.coordinate.longitude
        statusText = String(format: "GPS %.4f°, %.4f°", latitude, longitude)
    }
}

private final class LocationDelegate: NSObject, CLLocationManagerDelegate {
    weak var owner: ObserverLocation?
    init(owner: ObserverLocation) { self.owner = owner }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            owner?.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in owner?.update(from: loc) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in owner?.statusText = "Location failed: \(error.localizedDescription)" }
    }
}
