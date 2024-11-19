// Foundation framework - Latest
import Foundation
// CoreLocation framework - Latest
import CoreLocation

/// Human Tasks:
/// 1. Configure proper data encryption for sensitive listing information
/// 2. Set up monitoring for AI recognition service availability
/// 3. Verify location permission handling in the app
/// 4. Review listing expiration policy with business team
/// 5. Configure proper logging for listing status changes

// MARK: - Enums

/// Represents the condition of the furniture item
/// Requirements addressed:
/// - Data Types (1.3): Furniture listings data structure
public enum FurnitureCondition: String, Codable {
    case excellent
    case good
    case fair
    case poor
}

/// Categories of furniture items
/// Requirements addressed:
/// - AI-powered furniture recognition (1.2): Furniture categorization
public enum FurnitureCategory: String, Codable {
    case chair
    case table
    case sofa
    case bed
    case storage
    case other
}

/// Current status of the listing
/// Requirements addressed:
/// - Data Types (1.3): Furniture listings lifecycle management
public enum ListingStatus: String, Codable {
    case active
    case pending
    case collected
    case expired
}

// MARK: - Listing Class

/// Represents a furniture item listing with comprehensive details and location information
/// Requirements addressed:
/// - AI-powered furniture recognition (1.2): AI-based furniture categorization
/// - Location-based discovery (1.2): Location tracking for furniture items
/// - Data Types (1.3): Comprehensive furniture listing data model
public final class Listing: Codable, Identifiable {
    // MARK: - Properties
    
    public let id: UUID
    public let title: String
    public let description: String
    public let category: FurnitureCategory
    public let condition: FurnitureCondition
    public let location: Location
    public let userId: UUID
    public let imageUrls: [String]
    public let aiTags: [String]
    public let aiConfidenceScore: Double
    public private(set) var status: ListingStatus
    public let createdAt: Date
    public private(set) var collectedAt: Date?
    public private(set) var expiresAt: Date?
    
    // MARK: - Initialization
    
    /// Initializes a new Listing instance with the provided details
    public init(
        title: String,
        description: String,
        category: FurnitureCategory,
        condition: FurnitureCondition,
        location: Location,
        userId: UUID,
        imageUrls: [String],
        aiTags: [String],
        aiConfidenceScore: Double
    ) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.category = category
        self.condition = condition
        self.location = location
        self.userId = userId
        self.imageUrls = imageUrls
        self.aiTags = aiTags
        self.aiConfidenceScore = aiConfidenceScore
        self.status = .active
        self.createdAt = Date()
        self.expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: self.createdAt)
        self.collectedAt = nil
    }
    
    // MARK: - Public Methods
    
    /// Updates the listing status and related timestamps
    /// Requirements addressed:
    /// - Data Types (1.3): Listing lifecycle management
    public func updateStatus(_ newStatus: ListingStatus) {
        self.status = newStatus
        
        switch newStatus {
        case .collected:
            self.collectedAt = Date()
        case .expired:
            self.expiresAt = Date()
        default:
            break
        }
    }
    
    /// Checks if the listing has expired
    /// Requirements addressed:
    /// - Data Types (1.3): Listing lifecycle management
    public func isExpired() -> Bool {
        guard let expiresAt = expiresAt else {
            return false
        }
        return Date() > expiresAt
    }
    
    /// Calculates distance from another location
    /// Requirements addressed:
    /// - Location-based discovery (1.2): Distance calculation for furniture discovery
    public func distanceFrom(_ otherLocation: Location) -> Double {
        return location.distanceTo(otherLocation)
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case id, title, description, category, condition, location
        case userId, imageUrls, aiTags, aiConfidenceScore
        case status, createdAt, collectedAt, expiresAt
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(FurnitureCategory.self, forKey: .category)
        condition = try container.decode(FurnitureCondition.self, forKey: .condition)
        location = try container.decode(Location.self, forKey: .location)
        userId = try container.decode(UUID.self, forKey: .userId)
        imageUrls = try container.decode([String].self, forKey: .imageUrls)
        aiTags = try container.decode([String].self, forKey: .aiTags)
        aiConfidenceScore = try container.decode(Double.self, forKey: .aiConfidenceScore)
        status = try container.decode(ListingStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        collectedAt = try container.decodeIfPresent(Date.self, forKey: .collectedAt)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode(condition, forKey: .condition)
        try container.encode(location, forKey: .location)
        try container.encode(userId, forKey: .userId)
        try container.encode(imageUrls, forKey: .imageUrls)
        try container.encode(aiTags, forKey: .aiTags)
        try container.encode(aiConfidenceScore, forKey: .aiConfidenceScore)
        try container.encode(status, forKey: .status)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(collectedAt, forKey: .collectedAt)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
    }
}