import Foundation
import CoreLocation
import SwiftUI

struct Apartment: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let price: Int
    let bedrooms: Int
    let bathrooms: Int
    let imageURL: String?
    let amenities: [String]
    let walkingTimeMinutes: Int?
    
    // Custom init to ensure proper coordinate handling
    init(id: UUID = UUID(), name: String, address: String, coordinate: CLLocationCoordinate2D, price: Int, bedrooms: Int, bathrooms: Int, imageURL: String? = nil, amenities: [String] = [], walkingTimeMinutes: Int? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.coordinate = coordinate
        self.price = price
        self.bedrooms = bedrooms
        self.bathrooms = bathrooms
        self.imageURL = imageURL
        self.amenities = amenities
        self.walkingTimeMinutes = walkingTimeMinutes
    }
    
    // Codable implementation for CLLocationCoordinate2D
    private enum CodingKeys: String, CodingKey {
        case id, name, address, price, bedrooms, bathrooms, imageURL, amenities, walkingTimeMinutes
        case latitude, longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        price = try container.decode(Int.self, forKey: .price)
        bedrooms = try container.decode(Int.self, forKey: .bedrooms)
        bathrooms = try container.decode(Int.self, forKey: .bathrooms)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        amenities = try container.decode([String].self, forKey: .amenities)
        walkingTimeMinutes = try container.decodeIfPresent(Int.self, forKey: .walkingTimeMinutes)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encode(price, forKey: .price)
        try container.encode(bedrooms, forKey: .bedrooms)
        try container.encode(bathrooms, forKey: .bathrooms)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(amenities, forKey: .amenities)
        try container.encodeIfPresent(walkingTimeMinutes, forKey: .walkingTimeMinutes)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
    
    // Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Apartment, rhs: Apartment) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Computed Properties
extension Apartment {
    var pricePerMonth: String {
        return "$\(price)"
    }
    
    var bedroomBathroomText: String {
        return "\(bedrooms)br/\(bathrooms)ba"
    }
    
    var walkingTimeText: String? {
        guard let walkingTime = walkingTimeMinutes else { return nil }
        return "\(walkingTime) min walk"
    }
    
    var amenitiesText: String {
        return amenities.joined(separator: " • ")
    }
}

// MARK: - Sample Data
extension Apartment {
    static var sampleData: [Apartment] {
        return [
            Apartment(
                name: "Sunset Gardens",
                address: "123 Main St, San Francisco, CA 94102",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                price: 2800,
                bedrooms: 2,
                bathrooms: 1,
                amenities: ["Pool", "Gym", "Parking", "Laundry"],
                walkingTimeMinutes: 12
            ),
            Apartment(
                name: "Oak Ridge Apartments",
                address: "456 Oak Ave, San Francisco, CA 94103",
                coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
                price: 3200,
                bedrooms: 3,
                bathrooms: 2,
                amenities: ["Laundry", "Balcony", "Pet Friendly", "Storage"],
                walkingTimeMinutes: 8
            ),
            Apartment(
                name: "City View Lofts",
                address: "789 High St, San Francisco, CA 94104",
                coordinate: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294),
                price: 3800,
                bedrooms: 1,
                bathrooms: 1,
                amenities: ["Rooftop Deck", "Concierge", "Gym", "Modern Kitchen"],
                walkingTimeMinutes: 15
            ),
            Apartment(
                name: "Marina Bay Studios",
                address: "321 Bay St, San Francisco, CA 94105",
                coordinate: CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.3994),
                price: 2400,
                bedrooms: 1,
                bathrooms: 1,
                amenities: ["Water View", "Parking", "Doorman"],
                walkingTimeMinutes: 6
            ),
            Apartment(
                name: "Downtown Heights",
                address: "654 Market St, San Francisco, CA 94106",
                coordinate: CLLocationCoordinate2D(latitude: 37.7549, longitude: -122.4394),
                price: 4200,
                bedrooms: 3,
                bathrooms: 2,
                amenities: ["Gym", "Pool", "Spa", "Concierge", "Business Center"],
                walkingTimeMinutes: 20
            )
        ]
    }
}