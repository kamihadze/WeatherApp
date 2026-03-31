import CoreLocation

protocol LocationServiceDelegate: AnyObject {
    func locationService(_ service: LocationService, didUpdateLocation latitude: Double, longitude: Double)
    func locationService(_ service: LocationService, didFailWithError error: Error)
}

final class LocationService: NSObject {

    weak var delegate: LocationServiceDelegate?

    private let locationManager = CLLocationManager()
    private let defaultLatitude = 55.7558
    private let defaultLongitude = 37.6173

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            useDefaultLocation()
        }
    }

    private func useDefaultLocation() {
        delegate?.locationService(self, didUpdateLocation: defaultLatitude, longitude: defaultLongitude)
    }
}

extension LocationService: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            useDefaultLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            useDefaultLocation()
            return
        }
        delegate?.locationService(
            self,
            didUpdateLocation: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        useDefaultLocation()
    }
}
