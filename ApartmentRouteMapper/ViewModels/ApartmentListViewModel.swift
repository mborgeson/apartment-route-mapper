import Foundation
import CoreLocation
import Combine

@MainActor
class ApartmentListViewModel: ObservableObject {
    @Published var apartments: [Apartment] = []
    @Published var routeApartments: Set<UUID> = []
    
    private let locationService = LocationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadApartments()
        setupLocationUpdates()
    }
    
    private func loadApartments() {
        // In a real app, load from Core Data
        apartments = Apartment.sampleData
    }
    
    private func setupLocationUpdates() {
        locationService.$currentLocation
            .sink { [weak self] _ in
                // Trigger UI update when location changes
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func filteredApartments(searchText: String) -> [Apartment] {
        if searchText.isEmpty {
            return apartments.sorted { apartment1, apartment2 in
                // Sort by distance if location available, otherwise by name
                if let dist1 = distance(to: apartment1),
                   let dist2 = distance(to: apartment2) {
                    return dist1 < dist2
                }
                return apartment1.name < apartment2.name
            }
        } else {
            return apartments.filter { apartment in
                apartment.name.localizedCaseInsensitiveContains(searchText) ||
                apartment.address.localizedCaseInsensitiveContains(searchText) ||
                (apartment.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    func distance(to apartment: Apartment) -> CLLocationDistance? {
        locationService.distance(from: apartment)
    }
    
    func isInRoute(_ apartment: Apartment) -> Bool {
        routeApartments.contains(apartment.id)
    }
    
    func toggleRouteSelection(_ apartment: Apartment) {
        if routeApartments.contains(apartment.id) {
            routeApartments.remove(apartment.id)
        } else {
            routeApartments.insert(apartment.id)
        }
    }
    
    func addApartment(_ apartment: Apartment) {
        apartments.append(apartment)
        // In a real app, save to Core Data
    }
    
    func deleteApartments(at offsets: IndexSet) {
        apartments.remove(atOffsets: offsets)
        // In a real app, delete from Core Data
    }
}