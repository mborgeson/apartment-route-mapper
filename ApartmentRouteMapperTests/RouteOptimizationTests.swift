import XCTest
import CoreLocation
@testable import ApartmentRouteMapper

final class RouteOptimizationTests: XCTestCase {
    
    var routeService: RouteOptimizationService!
    var testApartments: [Apartment]!
    var startingLocation: CLLocation!
    
    override func setUp() {
        super.setUp()
        routeService = RouteOptimizationService.shared
        
        // Create test apartments in Los Angeles area
        testApartments = [
            Apartment(
                name: "Hollywood Heights",
                address: "123 Hollywood Blvd",
                latitude: 34.1022,
                longitude: -118.3351
            ),
            Apartment(
                name: "Beverly Hills Plaza",
                address: "456 Rodeo Dr",
                latitude: 34.0669,
                longitude: -118.4020
            ),
            Apartment(
                name: "Santa Monica Beach",
                address: "789 Ocean Ave",
                latitude: 34.0094,
                longitude: -118.4959
            ),
            Apartment(
                name: "Downtown Lofts",
                address: "321 Main St",
                latitude: 34.0430,
                longitude: -118.2517
            ),
            Apartment(
                name: "Pasadena Gardens",
                address: "654 Colorado Blvd",
                latitude: 34.1458,
                longitude: -118.1445
            )
        ]
        
        // Starting location (Central LA)
        startingLocation = CLLocation(latitude: 34.0522, longitude: -118.2437)
    }
    
    override func tearDown() {
        routeService = nil
        testApartments = nil
        startingLocation = nil
        super.tearDown()
    }
    
    // MARK: - TSP Algorithm Tests
    
    func testOptimizeRouteWithSingleApartment() async throws {
        let singleApartment = [testApartments[0]]
        let optimized = try await routeService.optimizeRoute(
            apartments: singleApartment,
            startingLocation: startingLocation
        )
        
        XCTAssertEqual(optimized.count, 1)
        XCTAssertEqual(optimized[0].id, singleApartment[0].id)
    }
    
    func testOptimizeRouteWithMultipleApartments() async throws {
        let optimized = try await routeService.optimizeRoute(
            apartments: testApartments,
            startingLocation: startingLocation
        )
        
        // Should return all apartments
        XCTAssertEqual(optimized.count, testApartments.count)
        
        // All original apartments should be in the result
        let optimizedIds = Set(optimized.map { $0.id })
        let originalIds = Set(testApartments.map { $0.id })
        XCTAssertEqual(optimizedIds, originalIds)
        
        // First apartment should be closest to starting location
        let firstOptimized = optimized[0]
        let closestToStart = testApartments.min { apt1, apt2 in
            startingLocation.distance(from: apt1.location) < 
            startingLocation.distance(from: apt2.location)
        }
        XCTAssertEqual(firstOptimized.id, closestToStart?.id)
    }
    
    func testOptimizeRouteWithEmptyArray() async throws {
        let optimized = try await routeService.optimizeRoute(
            apartments: [],
            startingLocation: startingLocation
        )
        
        XCTAssertTrue(optimized.isEmpty)
    }
    
    func testOptimizeRouteProducesShortPath() async throws {
        let optimized = try await routeService.optimizeRoute(
            apartments: testApartments,
            startingLocation: startingLocation
        )
        
        // Calculate total distance of optimized route
        var optimizedDistance = startingLocation.distance(from: optimized[0].location)
        for i in 0..<optimized.count - 1 {
            optimizedDistance += optimized[i].location.distance(from: optimized[i + 1].location)
        }
        
        // Calculate total distance of original order
        var originalDistance = startingLocation.distance(from: testApartments[0].location)
        for i in 0..<testApartments.count - 1 {
            originalDistance += testApartments[i].location.distance(from: testApartments[i + 1].location)
        }
        
        // Optimized route should generally be shorter (or at least not significantly longer)
        // Allow 10% tolerance for heuristic algorithm
        XCTAssertLessThanOrEqual(optimizedDistance, originalDistance * 1.1)
    }
    
    // MARK: - 2-Opt Improvement Tests
    
    func testTwoOptImprovement() async throws {
        // Create a route that can definitely be improved
        let suboptimalRoute = [
            testApartments[0], // Hollywood
            testApartments[2], // Santa Monica (far)
            testApartments[1], // Beverly Hills (should be between Hollywood and Santa Monica)
            testApartments[3], // Downtown
            testApartments[4]  // Pasadena
        ]
        
        let optimized = try await routeService.optimizeRoute(
            apartments: suboptimalRoute,
            startingLocation: startingLocation
        )
        
        // Calculate distances
        let optimizedDistance = calculateTotalDistance(
            route: optimized,
            from: startingLocation
        )
        let originalDistance = calculateTotalDistance(
            route: suboptimalRoute,
            from: startingLocation
        )
        
        // Optimized should be shorter
        XCTAssertLessThan(optimizedDistance, originalDistance)
    }
    
    // MARK: - Performance Tests
    
    func testOptimizeRouteLargeDatasetPerformance() {
        // Create 50 random apartments in LA area
        var largeDataset: [Apartment] = []
        for i in 0..<50 {
            let lat = 34.0522 + Double.random(in: -0.2...0.2)
            let lon = -118.2437 + Double.random(in: -0.3...0.3)
            largeDataset.append(
                Apartment(
                    name: "Apartment \(i)",
                    address: "Address \(i)",
                    latitude: lat,
                    longitude: lon
                )
            )
        }
        
        measure {
            let expectation = self.expectation(description: "Route optimization")
            
            Task {
                _ = try await routeService.optimizeRoute(
                    apartments: largeDataset,
                    startingLocation: startingLocation
                )
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - Route Calculation Tests
    
    func testCalculateRouteDetailsEmpty() async throws {
        let (distance, duration, routes) = try await routeService.calculateRouteDetails(
            for: [],
            from: startingLocation
        )
        
        XCTAssertEqual(distance, 0)
        XCTAssertEqual(duration, 0)
        XCTAssertTrue(routes.isEmpty)
    }
    
    func testCalculateRouteDetailsSingleApartment() async throws {
        let singleApartment = [testApartments[0]]
        
        let (distance, duration, routes) = try await routeService.calculateRouteDetails(
            for: singleApartment,
            from: startingLocation
        )
        
        XCTAssertGreaterThan(distance, 0)
        XCTAssertGreaterThan(duration, 900) // At least visit duration
        XCTAssertEqual(routes.count, 1)
    }
    
    // MARK: - Helper Methods
    
    private func calculateTotalDistance(route: [Apartment], from start: CLLocation) -> CLLocationDistance {
        guard !route.isEmpty else { return 0 }
        
        var distance = start.distance(from: route[0].location)
        for i in 0..<route.count - 1 {
            distance += route[i].location.distance(from: route[i + 1].location)
        }
        return distance
    }
}