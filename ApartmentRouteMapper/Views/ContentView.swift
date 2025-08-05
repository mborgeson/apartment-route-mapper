import SwiftUI
import MapKit

struct ContentView: View {
    @EnvironmentObject var locationService: LocationService
    @State private var selectedTab = 0
    @State private var apartments: [Apartment] = []
    @State private var selectedApartment: Apartment?
    @State private var showingRoute = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                MapView(
                    apartments: apartments,
                    selectedApartment: $selectedApartment,
                    showingRoute: $showingRoute
                )
                .navigationTitle("Apartment Map")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: loadNearbyApartments) {
                            Image(systemName: "location.magnifyingglass")
                        }
                        .disabled(!locationService.isLocationAuthorized)
                    }
                }
            }
            .tabItem {
                Image(systemName: "map")
                Text("Map")
            }
            .tag(0)
            
            NavigationView {
                ApartmentListView(
                    apartments: apartments,
                    selectedApartment: $selectedApartment,
                    onApartmentSelected: { apartment in
                        selectedApartment = apartment
                        selectedTab = 0 // Switch to map tab
                        showingRoute = true
                    }
                )
                .navigationTitle("Apartments")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: loadNearbyApartments) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(!locationService.isLocationAuthorized)
                    }
                }
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("List")
            }
            .tag(1)
        }
        .onAppear {
            locationService.requestLocationPermission()
            loadSampleApartments()
        }
        .alert("Location Permission Required", isPresented: .constant(!locationService.isLocationAuthorized && locationService.hasRequestedPermission)) {
            Button("Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable location access in Settings to find nearby apartments and get walking directions.")
        }
    }
    
    private func loadNearbyApartments() {
        // TODO: Implement API call to load real apartment data
        // For now, load sample data based on current location
        loadSampleApartments()
    }
    
    private func loadSampleApartments() {
        // Sample apartment data for demonstration
        apartments = [
            Apartment(
                id: UUID(),
                name: "Sunset Gardens",
                address: "123 Main St, Anytown, USA",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                price: 2800,
                bedrooms: 2,
                bathrooms: 1,
                imageURL: nil,
                amenities: ["Pool", "Gym", "Parking"],
                walkingTimeMinutes: 12
            ),
            Apartment(
                id: UUID(),
                name: "Oak Ridge Apartments",
                address: "456 Oak Ave, Anytown, USA",
                coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
                price: 3200,
                bedrooms: 3,
                bathrooms: 2,
                imageURL: nil,
                amenities: ["Laundry", "Balcony", "Pet Friendly"],
                walkingTimeMinutes: 8
            ),
            Apartment(
                id: UUID(),
                name: "City View Lofts",
                address: "789 High St, Anytown, USA",
                coordinate: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294),
                price: 3800,
                bedrooms: 1,
                bathrooms: 1,
                imageURL: nil,
                amenities: ["Rooftop Deck", "Concierge", "Gym"],
                walkingTimeMinutes: 15
            )
        ]
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationService())
}