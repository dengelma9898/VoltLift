import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var lastError: Error?

    private let locationManager: CLLocationManager
    private var isUpdatingLocation = false

    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 5
        self.authorizationStatus = self.locationManager.authorizationStatus
    }

    func requestWhenInUsePermission() {
        let status = self.locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways, .authorizedWhenInUse:
            break
        @unknown default:
            break
        }
    }

    func requestPreciseLocationIfNeeded() {
        if #available(iOS 14.0, *) {
            self.locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "PreciseLocation")
        }
    }

    func startUpdatingLocation() {
        guard !self.isUpdatingLocation else { return }
        self.isUpdatingLocation = true
        self.locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        guard self.isUpdatingLocation else { return }
        self.isUpdatingLocation = false
        self.locationManager.stopUpdatingLocation()
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if [.authorizedAlways, .authorizedWhenInUse].contains(status) {
                self.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.lastError = error
        }
    }
}
