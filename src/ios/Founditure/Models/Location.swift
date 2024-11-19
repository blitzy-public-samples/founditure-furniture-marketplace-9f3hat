//
// Location.swift
// Founditure
//
// Human Tasks:
// 1. Verify coordinate precision requirements with mapping service provider
// 2. Confirm address formatting compliance with USPS guidelines for international addresses
// 3. Review distance calculation accuracy requirements for different regions
//

import CoreLocation // Latest
import Foundation // Latest

/// Addresses requirements:
/// - 1.2 System Overview/Core Features: Location-based furniture discovery with real-time distance calculation
/// - 1.3 Scope/Implementation Boundaries: Major urban centers in North America with standardized address formatting
class Location: Codable {
    // MARK: - Properties
    
    /// Unique identifier for the location
    let id: UUID
    
    /// Geographic coordinates (latitude/longitude)
    let coordinates: CLLocationCoordinate2D
    
    /// Street address
    let address: String
    
    /// City name (optional)
    let city: String?
    
    /// State/province (optional)
    let state: String?
    
    /// Country name
    let country: String
    
    /// Postal/ZIP code
    let postalCode: String
    
    /// Timestamp when the location was created
    let timestamp: Date
    
    // MARK: - CodingKeys
    
    private enum CodingKeys: String, CodingKey {
        case id
        case latitude
        case longitude
        case address
        case city
        case state
        case country
        case postalCode
        case timestamp
    }
    
    // MARK: - Initialization
    
    /// Initializes a new Location instance with the provided coordinate and address information
    init(coordinates: CLLocationCoordinate2D, address: String, city: String? = nil, state: String? = nil, country: String, postalCode: String) {
        self.id = UUID()
        self.coordinates = coordinates
        self.address = address.formatAddress
        self.city = city
        self.state = state
        self.country = country
        self.postalCode = postalCode
        self.timestamp = Date()
    }
    
    // MARK: - Codable Implementation
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        address = try container.decode(String.self, forKey: .address)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        country = try container.decode(String.self, forKey: .country)
        postalCode = try container.decode(String.self, forKey: .postalCode)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(coordinates.latitude, forKey: .latitude)
        try container.encode(coordinates.longitude, forKey: .longitude)
        try container.encode(address, forKey: .address)
        try container.encodeIfPresent(city, forKey: .city)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encode(country, forKey: .country)
        try container.encode(postalCode, forKey: .postalCode)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    // MARK: - Public Methods
    
    /// Calculates the great-circle distance to another location in meters
    /// - Parameter otherLocation: The location to calculate the distance to
    /// - Returns: The distance in meters between the two locations
    func distanceTo(_ otherLocation: Location) -> Double {
        let selfLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        let otherCLLocation = CLLocation(latitude: otherLocation.coordinates.latitude, longitude: otherLocation.coordinates.longitude)
        
        return selfLocation.distance(from: otherCLLocation)
    }
    
    /// Returns a USPS-compliant formatted full address string
    /// - Returns: Formatted address string following USPS guidelines
    func formattedAddress() -> String {
        var components: [String] = [address]
        
        if let city = city {
            components.append(city)
        }
        
        if let state = state {
            components.append(state)
        }
        
        components.append("\(country) \(postalCode)")
        
        return components.joined(separator: ", ").formatAddress
    }
}