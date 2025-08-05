import Foundation
import MapKit
import Combine

@MainActor
class MapViewModel: ObservableObject {
    @Published var apartments: [Apartment] = []
    @Published var selectedApartments: Set<UUID> = []
    @Published var currentRoute: Route = Route()
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), // LA center
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var isCalculatingRoute = false
    @Published var routeError: Error?
    @Published var mapRoutes: [MKRoute] = []
    
    private let locationService = LocationService.shared
    private let routeService = RouteOptimizationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupLocationUpdates()
        loadApartments()
    }
    
    private func setupLocationUpdates() {
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.updateRegionIfNeeded(for: location.coordinate)
            }
            .store(in: &cancellables)
    }
    
    private func loadApartments() {
        // Load from Core Data or use sample data
        apartments = Apartment.sampleData
    }
    
    func toggleApartmentSelection(_ apartment: Apartment) {
        if selectedApartments.contains(apartment.id) {
            selectedApartments.remove(apartment.id)
            removeApartmentFromRoute(apartment)
        } else {
            selectedApartments.insert(apartment.id)
            currentRoute.addApartment(apartment)
        }
    }
    
    func optimizeAndCalculateRoute() {
        guard !selectedApartments.isEmpty,
              let startLocation = locationService.currentLocation else { return }
        
        isCalculatingRoute = true
        routeError = nil
        
        Task {
            do {
                let selectedApts = apartments.filter { selectedApartments.contains($0.id) }
                
                // Optimize route order
                let optimizedApartments = try await routeService.optimizeRoute(
                    apartments: selectedApts,
                    startingLocation: startLocation
                )
                
                // Update route with optimized order
                currentRoute.clearRoute()
                optimizedApartments.forEach { currentRoute.addApartment($0) }
                currentRoute.isOptimized = true
                
                // Calculate route details
                let (distance, duration, routes) = try await routeService.calculateRouteDetails(
                    for: optimizedApartments,
                    from: startLocation
                )
                
                currentRoute.totalDistance = distance
                currentRoute.totalDuration = duration
                mapRoutes = routes
                
                // Update map region to show full route
                if let firstRoute = routes.first {
                    updateRegionForRoute(firstRoute)
                }
                
            } catch {
                routeError = error
            }
            
            isCalculatingRoute = false
        }
    }
    
    func clearRoute() {
        currentRoute.clearRoute()
        selectedApartments.removeAll()
        mapRoutes.removeAll()
    }
    
    private func removeApartmentFromRoute(_ apartment: Apartment) {
        if let index = currentRoute.waypoints.firstIndex(where: { $0.apartment.id == apartment.id }) {
            currentRoute.removeWaypoint(at: index)
        }
    }
    
    private func updateRegionIfNeeded(for coordinate: CLLocationCoordinate2D) {
        // Update region only if user location is outside current visible area
        let currentRegion = region
        let span = currentRegion.span
        
        let latDelta = abs(coordinate.latitude - currentRegion.center.latitude)
        let lonDelta = abs(coordinate.longitude - currentRegion.center.longitude)
        
        if latDelta > span.latitudeDelta / 2 || lonDelta > span.longitudeDelta / 2 {
            region.center = coordinate
        }
    }
    
    private func updateRegionForRoute(_ route: MKRoute) {
        let rect = route.polyline.boundingMapRect
        let region = MKCoordinateRegion(rect.insetBy(dx: -rect.width * 0.1, dy: -rect.height * 0.1))
        self.region = region
    }
}