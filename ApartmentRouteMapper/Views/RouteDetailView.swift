import SwiftUI
import MapKit

struct RouteDetailView: View {
    @ObservedObject var route: Route
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Route Summary") {
                    HStack {
                        Label("Total Distance", systemImage: "map")
                        Spacer()
                        Text(formatDistance(route.totalDistance))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Total Duration", systemImage: "clock")
                        Spacer()
                        Text(formatDuration(route.totalDuration))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Stops", systemImage: "building.2")
                        Spacer()
                        Text("\(route.waypoints.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    if route.isOptimized {
                        Label("Route Optimized", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Section("Route Order") {
                    ForEach(Array(route.waypoints.enumerated()), id: \.element.id) { index, waypoint in
                        WaypointRowView(
                            waypoint: waypoint,
                            index: index + 1,
                            isLast: index == route.waypoints.count - 1
                        )
                    }
                    .onMove { from, to in
                        route.waypoints.move(fromOffsets: from, toOffset: to)
                        route.isOptimized = false
                    }
                }
                
                if !route.waypoints.isEmpty {
                    Section {
                        Button(action: startNavigation) {
                            Label("Start Navigation", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: exportRoute) {
                            Label("Export Route", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("Route Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                if !route.waypoints.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.unitOptions = .naturalScale
        let measurement = Measurement(value: distance, unit: UnitLength.meters)
        return formatter.string(from: measurement)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
    
    private func startNavigation() {
        guard let firstWaypoint = route.waypoints.first else { return }
        
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: firstWaypoint.apartment.coordinate))
        mapItem.name = firstWaypoint.apartment.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    private func exportRoute() {
        // Create a text representation of the route
        var routeText = "Optimized Apartment Route\n"
        routeText += "========================\n\n"
        routeText += "Total Distance: \(formatDistance(route.totalDistance))\n"
        routeText += "Total Duration: \(formatDuration(route.totalDuration))\n\n"
        routeText += "Route Order:\n"
        
        for (index, waypoint) in route.waypoints.enumerated() {
            routeText += "\(index + 1). \(waypoint.apartment.name)\n"
            routeText += "   \(waypoint.apartment.address)\n"
            if let notes = waypoint.apartment.notes {
                routeText += "   Notes: \(notes)\n"
            }
            routeText += "\n"
        }
        
        // Share the route
        let activityVC = UIActivityViewController(
            activityItems: [routeText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct WaypointRowView: View {
    let waypoint: Waypoint
    let index: Int
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step indicator
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 30, height: 30)
                Text("\(index)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(waypoint.apartment.name)
                    .font(.headline)
                Text(waypoint.apartment.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let notes = waypoint.apartment.notes {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                
                if let distance = waypoint.distanceFromPrevious,
                   let duration = waypoint.durationFromPrevious {
                    HStack(spacing: 16) {
                        Label(formatDistance(distance), systemImage: "arrow.up")
                        Label(formatDuration(duration), systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
                }
            }
            
            Spacer()
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
        formatter.allowedUnits = [.minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}