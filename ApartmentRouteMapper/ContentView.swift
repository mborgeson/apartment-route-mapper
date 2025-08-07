import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationService = LocationService.shared
    
    var body: some View {
        TabView {
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            
            ApartmentListView()
                .tabItem {
                    Label("Apartments", systemImage: "building.2")
                }
            
            RouteListView()
                .tabItem {
                    Label("Routes", systemImage: "arrow.triangle.turn.up.right.diamond")
                }
        }
        .onAppear {
            locationService.requestLocationPermission()
        }
    }
}

#Preview {
    ContentView()
}