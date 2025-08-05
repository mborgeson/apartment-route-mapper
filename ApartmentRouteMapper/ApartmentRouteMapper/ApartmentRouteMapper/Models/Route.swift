import Foundation
import MapKit

class Route: ObservableObject, Identifiable {
    let id = UUID()
    @Published var waypoints: [Waypoint] = []
    @Published var totalDistance: CLLocationDistance = 0
    @Published var totalDuration: TimeInterval = 0
    @Published var isOptimized: Bool = false
    @Published var mapRoute: MKRoute?
    
    func addApartment(_ apartment: Apartment, at index: Int? = nil) {
        let waypoint = Waypoint(apartment: apartment)
        if let index = index, index <= waypoints.count {
            waypoints.insert(waypoint, at: index)
        } else {
            waypoints.append(waypoint)
        }
    }
    
    func removeWaypoint(at index: Int) {
        guard index < waypoints.count else { return }
        waypoints.remove(at: index)
    }
    
    func reorderWaypoint(from source: Int, to destination: Int) {
        guard source < waypoints.count, destination <= waypoints.count else { return }
        let waypoint = waypoints.remove(at: source)
        waypoints.insert(waypoint, at: destination > source ? destination - 1 : destination)
    }
    
    func updateRoute(with optimizedOrder: [Int]) {
        let reorderedWaypoints = optimizedOrder.compactMap { index in
            index < waypoints.count ? waypoints[index] : nil
        }
        waypoints = reorderedWaypoints
        isOptimized = true
    }
    
    func clearRoute() {
        waypoints.removeAll()
        totalDistance = 0
        totalDuration = 0
        isOptimized = false
        mapRoute = nil
    }
}

struct Waypoint: Identifiable {
    let id = UUID()
    let apartment: Apartment
    var arrivalTime: Date?
    var departureTime: Date?
    var distanceFromPrevious: CLLocationDistance?
    var durationFromPrevious: TimeInterval?
    
    init(apartment: Apartment) {
        self.apartment = apartment
    }
}