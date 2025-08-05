import SwiftUI
import MapKit

@main
struct ApartmentRouteMapperApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(LocationService())
        }
    }
}