import SwiftUI
import CoreLocation

struct ApartmentListView: View {
    @StateObject private var viewModel = ApartmentListViewModel()
    @State private var showingAddApartment = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.filteredApartments(searchText: searchText)) { apartment in
                    ApartmentRowView(
                        apartment: apartment,
                        distance: viewModel.distance(to: apartment),
                        isInRoute: viewModel.isInRoute(apartment)
                    )
                    .onTapGesture {
                        viewModel.toggleRouteSelection(apartment)
                    }
                }
                .onDelete(perform: viewModel.deleteApartments)
            }
            .searchable(text: $searchText, prompt: "Search apartments")
            .navigationTitle("Apartments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddApartment = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddApartment) {
                AddApartmentView { apartment in
                    viewModel.addApartment(apartment)
                }
            }
        }
    }
}

struct ApartmentRowView: View {
    let apartment: Apartment
    let distance: CLLocationDistance?
    let isInRoute: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(apartment.name)
                    .font(.headline)
                Text(apartment.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let notes = apartment.notes {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let distance = distance {
                    Text(formatDistance(distance))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: isInRoute ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isInRoute ? .blue : .gray)
                    .imageScale(.large)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.unitOptions = .naturalScale
        let measurement = Measurement(value: distance, unit: UnitLength.meters)
        return formatter.string(from: measurement)
    }
}

// MARK: - Add Apartment View
struct AddApartmentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var address = ""
    @State private var notes = ""
    @State private var isGeocoding = false
    @State private var geocodingError: Error?
    
    let onSave: (Apartment) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Apartment Information") {
                    TextField("Name", text: $name)
                    TextField("Address", text: $address)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Apartment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveApartment()
                    }
                    .disabled(name.isEmpty || address.isEmpty || isGeocoding)
                }
            }
            .overlay {
                if isGeocoding {
                    ProgressView("Geocoding address...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(8)
                }
            }
            .alert("Geocoding Error", isPresented: .constant(geocodingError != nil)) {
                Button("OK") { geocodingError = nil }
            } message: {
                Text(geocodingError?.localizedDescription ?? "")
            }
        }
    }
    
    private func saveApartment() {
        isGeocoding = true
        
        Task {
            do {
                let geocoder = CLGeocoder()
                let placemarks = try await geocoder.geocodeAddressString(address)
                
                guard let location = placemarks.first?.location else {
                    throw GeocodingError.noLocationFound
                }
                
                let apartment = Apartment(
                    name: name,
                    address: address,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    notes: notes.isEmpty ? nil : notes
                )
                
                await MainActor.run {
                    onSave(apartment)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    geocodingError = error
                    isGeocoding = false
                }
            }
        }
    }
}

enum GeocodingError: LocalizedError {
    case noLocationFound
    
    var errorDescription: String? {
        switch self {
        case .noLocationFound:
            return "Could not find location for this address. Please check the address and try again."
        }
    }
}