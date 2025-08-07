import SwiftUI

struct RouteListView: View {
    @StateObject private var viewModel = RouteListViewModel()
    @State private var showingSaveRoute = false
    @State private var selectedRoute: SavedRoute?
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.savedRoutes.isEmpty {
                    ContentUnavailableView(
                        "No Saved Routes",
                        systemImage: "map",
                        description: Text("Create and save routes from the Map tab")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.savedRoutes) { route in
                        RouteRowView(route: route)
                            .onTapGesture {
                                selectedRoute = route
                            }
                    }
                    .onDelete(perform: viewModel.deleteRoutes)
                }
            }
            .navigationTitle("Saved Routes")
            .toolbar {
                if !viewModel.savedRoutes.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            }
            .sheet(item: $selectedRoute) { route in
                SavedRouteDetailView(route: route)
            }
            .onAppear {
                viewModel.loadRoutes()
            }
        }
    }
}

struct RouteRowView: View {
    let route: SavedRoute
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(route.name)
                    .font(.headline)
                
                Spacer()
                
                if route.isOptimized {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .imageScale(.small)
                }
            }
            
            HStack(spacing: 16) {
                Label("\(route.apartments.count) stops", systemImage: "building.2")
                Label(formatDistance(route.totalDistance), systemImage: "map")
                Label(formatDuration(route.totalDuration), systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Text("Updated \(route.updatedAt, style: .relative)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        let measurement = Measurement(value: distance, unit: UnitLength.meters)
        return formatter.string(from: measurement)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

struct SavedRouteDetailView: View {
    let route: SavedRoute
    @Environment(\.dismiss) private var dismiss
    @State private var showingInMap = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Route Information") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(route.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(route.createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Distance")
                        Spacer()
                        Text(formatDistance(route.totalDistance))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Duration")
                        Spacer()
                        Text(formatDuration(route.totalDuration))
                            .foregroundColor(.secondary)
                    }
                    
                    if route.isOptimized {
                        Label("Optimized Route", systemImage: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Section("Apartments (\(route.apartments.count))") {
                    ForEach(Array(route.apartments.enumerated()), id: \.element.id) { index, apartment in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.blue))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(apartment.name)
                                    .font(.subheadline)
                                Text(apartment.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    Button(action: { showingInMap = true }) {
                        Label("View in Map", systemImage: "map")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: startNavigation) {
                        Label("Start Navigation", systemImage: "arrow.triangle.turn.up.right.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .navigationTitle("Route Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        let measurement = Measurement(value: distance, unit: UnitLength.meters)
        return formatter.string(from: measurement)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        return formatter.string(from: duration) ?? ""
    }
    
    private func startNavigation() {
        guard let firstApartment = route.apartments.first else { return }
        
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: firstApartment.coordinate))
        mapItem.name = firstApartment.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Route List View Model
@MainActor
class RouteListViewModel: ObservableObject {
    @Published var savedRoutes: [SavedRoute] = []
    
    private let coreDataService = CoreDataService.shared
    
    func loadRoutes() {
        savedRoutes = coreDataService.fetchRoutes()
    }
    
    func deleteRoutes(at offsets: IndexSet) {
        for index in offsets {
            let route = savedRoutes[index]
            coreDataService.deleteRoute(route)
        }
        savedRoutes.remove(atOffsets: offsets)
    }
}