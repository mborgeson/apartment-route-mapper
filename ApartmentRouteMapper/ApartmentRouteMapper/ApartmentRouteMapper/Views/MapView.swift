import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var showingRouteDetails = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                MapViewRepresentable(
                    region: $viewModel.region,
                    apartments: viewModel.apartments,
                    selectedApartments: viewModel.selectedApartments,
                    routes: viewModel.mapRoutes,
                    onApartmentTap: { apartment in
                        viewModel.toggleApartmentSelection(apartment)
                    }
                )
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    if !viewModel.selectedApartments.isEmpty {
                        RouteControlsView(
                            selectedCount: viewModel.selectedApartments.count,
                            isCalculating: viewModel.isCalculatingRoute,
                            onOptimize: {
                                viewModel.optimizeAndCalculateRoute()
                            },
                            onClear: {
                                viewModel.clearRoute()
                            },
                            onShowDetails: {
                                showingRouteDetails = true
                            }
                        )
                        .padding()
                    }
                }
            }
            .navigationTitle("Route Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { LocationService.shared.startUpdatingLocation() }) {
                        Image(systemName: "location")
                    }
                }
            }
            .sheet(isPresented: $showingRouteDetails) {
                RouteDetailView(route: viewModel.currentRoute)
            }
            .alert("Route Error", isPresented: .constant(viewModel.routeError != nil)) {
                Button("OK") { viewModel.routeError = nil }
            } message: {
                Text(viewModel.routeError?.localizedDescription ?? "")
            }
        }
    }
}

struct RouteControlsView: View {
    let selectedCount: Int
    let isCalculating: Bool
    let onOptimize: () -> Void
    let onClear: () -> Void
    let onShowDetails: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(selectedCount) apartments selected")
                    .font(.headline)
                Spacer()
                Button("Clear", action: onClear)
                    .foregroundColor(.red)
            }
            
            HStack(spacing: 16) {
                Button(action: onOptimize) {
                    if isCalculating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Optimize Route")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCalculating)
                
                Button("View Details", action: onShowDetails)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
    }
}

// MARK: - MapKit UIViewRepresentable
struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let apartments: [Apartment]
    let selectedApartments: Set<UUID>
    let routes: [MKRoute]
    let onApartmentTap: (Apartment) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        if !mapView.region.isEqual(region) {
            mapView.setRegion(region, animated: true)
        }
        
        // Update annotations
        mapView.removeAnnotations(mapView.annotations)
        let annotations = apartments.map { apartment in
            ApartmentAnnotation(
                apartment: apartment,
                isSelected: selectedApartments.contains(apartment.id)
            )
        }
        mapView.addAnnotations(annotations)
        
        // Update routes
        mapView.removeOverlays(mapView.overlays)
        routes.forEach { route in
            mapView.addOverlay(route.polyline, level: .aboveRoads)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let apartmentAnnotation = annotation as? ApartmentAnnotation else {
                return nil
            }
            
            let identifier = "ApartmentAnnotation"
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            annotationView.canShowCallout = true
            annotationView.markerTintColor = apartmentAnnotation.isSelected ? .systemBlue : .systemRed
            annotationView.glyphImage = UIImage(systemName: "building.2")
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let apartmentAnnotation = view.annotation as? ApartmentAnnotation else {
                return
            }
            parent.onApartmentTap(apartmentAnnotation.apartment)
            mapView.deselectAnnotation(apartmentAnnotation, animated: true)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }
    }
}

// MARK: - Custom Annotation
class ApartmentAnnotation: NSObject, MKAnnotation {
    let apartment: Apartment
    let isSelected: Bool
    
    var coordinate: CLLocationCoordinate2D {
        apartment.coordinate
    }
    
    var title: String? {
        apartment.name
    }
    
    var subtitle: String? {
        apartment.address
    }
    
    init(apartment: Apartment, isSelected: Bool) {
        self.apartment = apartment
        self.isSelected = isSelected
        super.init()
    }
}

// MARK: - Helper Extensions
extension MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        lhs.center.latitude == rhs.center.latitude &&
        lhs.center.longitude == rhs.center.longitude &&
        lhs.span.latitudeDelta == rhs.span.latitudeDelta &&
        lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
    
    func isEqual(_ other: MKCoordinateRegion) -> Bool {
        abs(center.latitude - other.center.latitude) < 0.00001 &&
        abs(center.longitude - other.center.longitude) < 0.00001 &&
        abs(span.latitudeDelta - other.span.latitudeDelta) < 0.00001 &&
        abs(span.longitudeDelta - other.span.longitudeDelta) < 0.00001
    }
}