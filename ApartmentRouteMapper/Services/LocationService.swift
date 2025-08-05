import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var hasRequestedPermission: Bool = false
    @Published var locationError: Error?
    
    var isLocationAuthorized: Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        guard !hasRequestedPermission else { return }
        
        hasRequestedPermission = true
        
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Handle denied state - could show alert to go to settings
            break
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    private func startLocationUpdates() {
        guard isLocationAuthorized else { return }
        
        locationManager.startUpdatingLocation()
    }
    
    private func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func calculateWalkingTime(to destination: CLLocationCoordinate2D) async -> TimeInterval? {
        guard let userLocation = userLocation else { return nil }
        
        return await withCheckedContinuation { continuation in
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            request.transportType = .walking
            
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                if let route = response?.routes.first {
                    continuation.resume(returning: route.expectedTravelTime)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func calculateDistance(to destination: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let userLocation = userLocation else { return nil }
        
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return userLocation.distance(from: destinationLocation)
    }
    
    func isLocationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.userLocation = location
            self.locationError = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error
        }
        
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startLocationUpdates()
            case .denied, .restricted:
                self.stopLocationUpdates()
                self.userLocation = nil
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Location Utilities
extension LocationService {
    static func formatDistance(_ distance: CLLocationDistance) -> String {
        let distanceInMiles = distance / 1609.344
        
        if distanceInMiles < 0.1 {
            let distanceInFeet = distance * 3.28084
            return String(format: "%.0f ft", distanceInFeet)
        } else {
            return String(format: "%.1f mi", distanceInMiles)
        }
    }
    
    static func formatWalkingTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        
        if minutes < 1 {
            return "< 1 min"
        } else {
            return "\(minutes) min"
        }
    }
}

import MapKit

// MARK: - Map Integration Helper
extension LocationService {
    func createMapItem(for apartment: Apartment) -> MKMapItem {
        let placemark = MKPlacemark(coordinate: apartment.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = apartment.name
        return mapItem
    }
    
    func openInMaps(apartment: Apartment) {
        let mapItem = createMapItem(for: apartment)
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking,
            MKLaunchOptionsShowsTrafficKey: false
        ])
    }
}