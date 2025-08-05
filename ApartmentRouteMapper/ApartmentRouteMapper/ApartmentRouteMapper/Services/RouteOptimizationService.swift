import Foundation
import CoreLocation
import MapKit

class RouteOptimizationService {
    static let shared = RouteOptimizationService()
    
    private init() {}
    
    // MARK: - TSP Implementation using Nearest Neighbor Heuristic
    func optimizeRoute(apartments: [Apartment], startingLocation: CLLocation) async throws -> [Apartment] {
        guard !apartments.isEmpty else { return [] }
        
        // If only one apartment, no optimization needed
        if apartments.count == 1 { return apartments }
        
        var unvisited = apartments
        var optimizedRoute: [Apartment] = []
        var currentLocation = startingLocation
        
        // Start with nearest apartment to current location
        while !unvisited.isEmpty {
            let (nearestIndex, _) = findNearestApartment(from: currentLocation, in: unvisited)
            let nearest = unvisited.remove(at: nearestIndex)
            optimizedRoute.append(nearest)
            currentLocation = nearest.location
        }
        
        // Optional: Apply 2-opt improvement
        if optimizedRoute.count > 3 {
            optimizedRoute = try await apply2OptImprovement(route: optimizedRoute, startingLocation: startingLocation)
        }
        
        return optimizedRoute
    }
    
    // MARK: - Helper Methods
    private func findNearestApartment(from location: CLLocation, in apartments: [Apartment]) -> (index: Int, distance: CLLocationDistance) {
        var nearestIndex = 0
        var minDistance = CLLocationDistanceMax
        
        for (index, apartment) in apartments.enumerated() {
            let distance = location.distance(from: apartment.location)
            if distance < minDistance {
                minDistance = distance
                nearestIndex = index
            }
        }
        
        return (nearestIndex, minDistance)
    }
    
    // MARK: - 2-Opt Improvement Algorithm
    private func apply2OptImprovement(route: [Apartment], startingLocation: CLLocation) async throws -> [Apartment] {
        var improvedRoute = route
        var improved = true
        
        while improved {
            improved = false
            
            for i in 0..<improvedRoute.count - 1 {
                for j in i + 2..<improvedRoute.count {
                    let currentDistance = calculateSegmentDistance(
                        route: improvedRoute,
                        from: i,
                        to: j,
                        startingLocation: startingLocation
                    )
                    
                    // Try swapping
                    var testRoute = improvedRoute
                    testRoute[i+1...j].reverse()
                    
                    let newDistance = calculateSegmentDistance(
                        route: testRoute,
                        from: i,
                        to: j,
                        startingLocation: startingLocation
                    )
                    
                    if newDistance < currentDistance {
                        improvedRoute = testRoute
                        improved = true
                    }
                }
            }
        }
        
        return improvedRoute
    }
    
    private func calculateSegmentDistance(route: [Apartment], from: Int, to: Int, startingLocation: CLLocation) -> CLLocationDistance {
        var distance: CLLocationDistance = 0
        
        // Distance from starting location to first apartment if needed
        if from == 0 {
            distance += startingLocation.distance(from: route[0].location)
        }
        
        // Calculate distances between apartments in the segment
        for i in from..<min(to, route.count - 1) {
            distance += route[i].location.distance(from: route[i + 1].location)
        }
        
        return distance
    }
    
    // MARK: - Route Calculation with MapKit
    func calculateRouteDetails(for apartments: [Apartment], from startingLocation: CLLocation) async throws -> (distance: CLLocationDistance, duration: TimeInterval, routes: [MKRoute]) {
        guard !apartments.isEmpty else { return (0, 0, []) }
        
        var totalDistance: CLLocationDistance = 0
        var totalDuration: TimeInterval = 0
        var routes: [MKRoute] = []
        
        // Calculate route from starting location to first apartment
        let firstRoute = try await calculateSingleRoute(
            from: startingLocation.coordinate,
            to: apartments[0].coordinate
        )
        totalDistance += firstRoute.distance
        totalDuration += firstRoute.expectedTravelTime
        routes.append(firstRoute)
        
        // Calculate routes between consecutive apartments
        for i in 0..<apartments.count - 1 {
            let route = try await calculateSingleRoute(
                from: apartments[i].coordinate,
                to: apartments[i + 1].coordinate
            )
            totalDistance += route.distance
            totalDuration += route.expectedTravelTime
            routes.append(route)
        }
        
        // Add estimated visit duration for each apartment
        totalDuration += Double(apartments.count) * 900 // 15 minutes per apartment
        
        return (totalDistance, totalDuration, routes)
    }
    
    private func calculateSingleRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        guard let route = response.routes.first else {
            throw RouteError.noRouteFound
        }
        
        return route
    }
}

// MARK: - Route Errors
enum RouteError: LocalizedError {
    case noRouteFound
    case calculationFailed
    
    var errorDescription: String? {
        switch self {
        case .noRouteFound:
            return "No route could be found between the locations."
        case .calculationFailed:
            return "Failed to calculate the route. Please try again."
        }
    }
}