import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var locationService: LocationService
    let apartments: [Apartment]
    @Binding var selectedApartment: Apartment?
    @Binding var showingRoute: Bool
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var route: MKRoute?
    @State private var isCalculatingRoute = false
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, userTrackingMode: .none, annotationItems: apartments) { apartment in
                MapAnnotation(coordinate: apartment.coordinate) {
                    ApartmentAnnotationView(
                        apartment: apartment,
                        isSelected: selectedApartment?.id == apartment.id
                    ) {
                        selectedApartment = apartment
                        showingRoute = true
                    }
                }
            }
            .overlay(
                RouteOverlay(route: route)
            )
            .onAppear {
                updateRegionToUserLocation()
            }
            .onChange(of: locationService.userLocation) { _ in
                updateRegionToUserLocation()
            }
            .onChange(of: selectedApartment) { apartment in
                if let apartment = apartment, showingRoute {
                    calculateRoute(to: apartment)
                } else {
                    route = nil
                }
            }
            .onChange(of: showingRoute) { showing in
                if !showing {
                    route = nil
                    selectedApartment = nil
                }
            }
            
            // Route control buttons
            if showingRoute && selectedApartment != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Button(action: {
                                showingRoute = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(Color.red)
                                    .clipShape(Circle())
                            }
                            
                            if isCalculatingRoute {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
    }
    
    private func updateRegionToUserLocation() {
        if let userLocation = locationService.userLocation {
            withAnimation(.easeInOut(duration: 1.0)) {
                region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            }
        }
    }
    
    private func calculateRoute(to apartment: Apartment) {
        guard let userLocation = locationService.userLocation else { return }
        
        isCalculatingRoute = true
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: apartment.coordinate))
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                isCalculatingRoute = false
                
                if let route = response?.routes.first {
                    self.route = route
                    
                    // Adjust map region to show the entire route
                    let routeRect = route.polyline.boundingMapRect
                    let region = MKCoordinateRegion(routeRect)
                    
                    withAnimation(.easeInOut(duration: 1.0)) {
                        self.region = MKCoordinateRegion(
                            center: region.center,
                            span: MKCoordinateSpan(
                                latitudeDelta: region.span.latitudeDelta * 1.4,
                                longitudeDelta: region.span.longitudeDelta * 1.4
                            )
                        )
                    }
                } else if let error = error {
                    print("Route calculation error: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct ApartmentAnnotationView: View {
    let apartment: Apartment
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.red : Color.blue)
                        .frame(width: 30, height: 30)
                    
                    Text("$\(apartment.price / 100)K")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.5)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isSelected {
                VStack(alignment: .leading, spacing: 4) {
                    Text(apartment.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(apartment.bedrooms)br/\(apartment.bathrooms)ba")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let walkingTime = apartment.walkingTimeMinutes {
                        Text("\(walkingTime) min walk")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 4)
            }
        }
    }
}

struct RouteOverlay: View {
    let route: MKRoute?
    
    var body: some View {
        if let route = route {
            MapOverlay(route: route)
        }
    }
}

struct MapOverlay: UIViewRepresentable {
    let route: MKRoute
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlay(route.polyline)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKPolyline {
                let renderer = MKPolylineRenderer(overlay: overlay)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

#Preview {
    MapView(
        apartments: [
            Apartment(
                id: UUID(),
                name: "Sample Apartment",
                address: "123 Main St",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                price: 2800,
                bedrooms: 2,
                bathrooms: 1,
                imageURL: nil,
                amenities: ["Pool", "Gym"],
                walkingTimeMinutes: 10
            )
        ],
        selectedApartment: .constant(nil),
        showingRoute: .constant(false)
    )
    .environmentObject(LocationService())
}