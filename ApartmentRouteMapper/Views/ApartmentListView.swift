import SwiftUI
import MapKit

struct ApartmentListView: View {
    @EnvironmentObject var locationService: LocationService
    let apartments: [Apartment]
    @Binding var selectedApartment: Apartment?
    let onApartmentSelected: (Apartment) -> Void
    
    @State private var sortOption: SortOption = .price
    @State private var filterBedrooms: Int? = nil
    @State private var maxPrice: Double = 5000
    @State private var showingFilters = false
    
    enum SortOption: String, CaseIterable {
        case price = "Price"
        case distance = "Distance"
        case bedrooms = "Bedrooms"
        
        var systemImage: String {
            switch self {
            case .price: return "dollarsign.circle"
            case .distance: return "location"
            case .bedrooms: return "bed.double"
            }
        }
    }
    
    var filteredAndSortedApartments: [Apartment] {
        var filtered = apartments
        
        // Apply filters
        if let bedrooms = filterBedrooms {
            filtered = filtered.filter { $0.bedrooms == bedrooms }
        }
        
        filtered = filtered.filter { Double($0.price) <= maxPrice }
        
        // Apply sorting
        switch sortOption {
        case .price:
            filtered.sort { $0.price < $1.price }
        case .distance:
            if let userLocation = locationService.userLocation {
                filtered.sort { apartment1, apartment2 in
                    let distance1 = userLocation.distance(from: CLLocation(latitude: apartment1.coordinate.latitude, longitude: apartment1.coordinate.longitude))
                    let distance2 = userLocation.distance(from: CLLocation(latitude: apartment2.coordinate.latitude, longitude: apartment2.coordinate.longitude))
                    return distance1 < distance2
                }
            }
        case .bedrooms:
            filtered.sort { $0.bedrooms < $1.bedrooms }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Sort and Filter Bar
            HStack {
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: {
                            sortOption = option
                        }) {
                            HStack {
                                Image(systemName: option.systemImage)
                                Text("Sort by \(option.rawValue)")
                                if sortOption == option {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: sortOption.systemImage)
                        Text("Sort")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: {
                    showingFilters.toggle()
                }) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Filter")
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // Filter Panel
            if showingFilters {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Max Price: $\(Int(maxPrice))")
                            .font(.subheadline)
                        Spacer()
                    }
                    
                    Slider(value: $maxPrice, in: 1000...5000, step: 100)
                        .accentColor(.blue)
                    
                    HStack {
                        Text("Bedrooms:")
                            .font(.subheadline)
                        
                        ForEach([nil, 1, 2, 3, 4], id: \.self) { bedrooms in
                            Button(action: {
                                filterBedrooms = bedrooms
                            }) {
                                Text(bedrooms == nil ? "Any" : "\(bedrooms!)")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(filterBedrooms == bedrooms ? Color.blue : Color(.systemGray5))
                                    .foregroundColor(filterBedrooms == bedrooms ? .white : .primary)
                                    .cornerRadius(6)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
            }
            
            // Apartment List
            List(filteredAndSortedApartments) { apartment in
                ApartmentRowView(
                    apartment: apartment,
                    userLocation: locationService.userLocation,
                    isSelected: selectedApartment?.id == apartment.id
                )
                .onTapGesture {
                    selectedApartment = apartment
                    onApartmentSelected(apartment)
                }
                .listRowSeparator(.hidden)
                .padding(.vertical, 4)
            }
            .listStyle(PlainListStyle())
        }
        .sheet(isPresented: .constant(selectedApartment != nil && showingFilters == false)) {
            if let apartment = selectedApartment {
                ApartmentDetailView(apartment: apartment) {
                    selectedApartment = nil
                }
            }
        }
    }
}

struct ApartmentRowView: View {
    let apartment: Apartment
    let userLocation: CLLocation?
    let isSelected: Bool
    
    private var distanceText: String {
        guard let userLocation = userLocation else { return "" }
        
        let apartmentLocation = CLLocation(latitude: apartment.coordinate.latitude, longitude: apartment.coordinate.longitude)
        let distance = userLocation.distance(from: apartmentLocation)
        let distanceInMiles = distance / 1609.344
        
        return String(format: "%.1f mi", distanceInMiles)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(apartment.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(apartment.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(apartment.price)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    if !distanceText.isEmpty {
                        Text(distanceText)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "bed.double")
                        .foregroundColor(.secondary)
                    Text("\(apartment.bedrooms) bed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "bathtub")
                        .foregroundColor(.secondary)
                    Text("\(apartment.bathrooms) bath")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let walkingTime = apartment.walkingTimeMinutes {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.walk")
                            .foregroundColor(.secondary)
                        Text("\(walkingTime) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Amenities
            if !apartment.amenities.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(apartment.amenities.prefix(3), id: \.self) { amenity in
                            Text(amenity)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        if apartment.amenities.count > 3 {
                            Text("+\(apartment.amenities.count - 3) more")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct ApartmentDetailView: View {
    let apartment: Apartment
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(apartment.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(apartment.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("$\(apartment.price)/month")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            
                            Spacer()
                            
                            Text("\(apartment.bedrooms) bed • \(apartment.bathrooms) bath")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Amenities
                    if !apartment.amenities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amenities")
                                .font(.headline)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(apartment.amenities, id: \.self) { amenity in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text(amenity)
                                            .font(.subheadline)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ApartmentListView(
        apartments: [
            Apartment(
                id: UUID(),
                name: "Sample Apartment",
                address: "123 Main St, Anytown, USA",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                price: 2800,
                bedrooms: 2,
                bathrooms: 1,
                imageURL: nil,
                amenities: ["Pool", "Gym", "Parking"],
                walkingTimeMinutes: 10
            )
        ],
        selectedApartment: .constant(nil),
        onApartmentSelected: { _ in }
    )
    .environmentObject(LocationService())
}