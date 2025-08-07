import Foundation
import CoreLocation

struct Apartment: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var notes: String?
    var visitOrder: Int?
    var estimatedVisitDuration: TimeInterval = 900 // 15 minutes default
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    init(id: UUID = UUID(), name: String, address: String, latitude: Double, longitude: Double, notes: String? = nil, visitOrder: Int? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.notes = notes
        self.visitOrder = visitOrder
    }
}

// MARK: - Sample Data
extension Apartment {
    static let sampleData: [Apartment] = [
        Apartment(
            name: "Sunset Heights",
            address: "123 Sunset Blvd, Los Angeles, CA 90028",
            latitude: 34.1014,
            longitude: -118.3350,
            notes: "Building code: 1234"
        ),
        Apartment(
            name: "Park View Apartments",
            address: "456 Park Ave, Los Angeles, CA 90010",
            latitude: 34.0618,
            longitude: -118.3448,
            notes: "Gate code: 5678"
        ),
        Apartment(
            name: "Downtown Lofts",
            address: "789 Main St, Los Angeles, CA 90014",
            latitude: 34.0430,
            longitude: -118.2517,
            notes: "Parking on level 2"
        ),
        Apartment(
            name: "Beach Plaza",
            address: "321 Ocean Ave, Santa Monica, CA 90401",
            latitude: 34.0094,
            longitude: -118.4959,
            notes: "Check with concierge"
        ),
        Apartment(
            name: "Valley Gardens",
            address: "654 Ventura Blvd, Sherman Oaks, CA 91403",
            latitude: 34.1508,
            longitude: -118.4625,
            notes: "Unit 4B"
        )
    ]
}