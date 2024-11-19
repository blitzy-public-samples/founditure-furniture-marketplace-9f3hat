// Foundation framework - Latest
import Foundation
// Combine framework - Latest
import Combine
// CoreLocation framework - Latest
import CoreLocation

/// Human Tasks:
/// 1. Configure proper error logging for listing operations
/// 2. Set up monitoring for image upload failures
/// 3. Configure caching policy for listing data
/// 4. Review and adjust location query radius based on user density
/// 5. Set up proper retry mechanisms for failed network requests

// MARK: - ListingEndpoint

/// API endpoints for listing operations
/// Requirements addressed:
/// - Location-based discovery (1.2): Location-based furniture discovery endpoints
/// - Data Types (1.3): Furniture listings data handling
enum ListingEndpoint {
    case createListing(title: String, description: String, category: FurnitureCategory, condition: FurnitureCondition, location: Location, images: [Data])
    case getListing(UUID)
    case updateListing(UUID, status: ListingStatus)
    case deleteListing(UUID)
    case getNearbyListings(coordinates: CLLocationCoordinate2D, radius: Double)
    case uploadListingImage(listingId: UUID, imageData: Data)
}

// MARK: - ListingEndpoint + APIEndpoint

extension ListingEndpoint: APIEndpoint {
    typealias Response = Listing
    
    var path: String {
        switch self {
        case .createListing:
            return "/listings"
        case .getListing(let id):
            return "/listings/\(id)"
        case .updateListing(let id, _):
            return "/listings/\(id)"
        case .deleteListing(let id):
            return "/listings/\(id)"
        case .getNearbyListings:
            return "/listings/nearby"
        case .uploadListingImage(let listingId, _):
            return "/listings/\(listingId)/images"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .createListing:
            return .post
        case .getListing:
            return .get
        case .updateListing:
            return .put
        case .deleteListing:
            return .delete
        case .getNearbyListings:
            return .get
        case .uploadListingImage:
            return .post
        }
    }
    
    var headers: [String: String]? {
        switch self {
        case .uploadListingImage:
            return ["Content-Type": "image/jpeg"]
        default:
            return nil
        }
    }
    
    var body: Encodable? {
        switch self {
        case .createListing(let title, let description, let category, let condition, let location, _):
            return [
                "title": title,
                "description": description,
                "category": category,
                "condition": condition,
                "location": location
            ]
        case .updateListing(_, let status):
            return ["status": status]
        default:
            return nil
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getNearbyListings(let coordinates, let radius):
            return [
                URLQueryItem(name: "latitude", value: String(coordinates.latitude)),
                URLQueryItem(name: "longitude", value: String(coordinates.longitude)),
                URLQueryItem(name: "radius", value: String(radius))
            ]
        default:
            return nil
        }
    }
}

// MARK: - ListingService

/// Service class for managing furniture listings
/// Requirements addressed:
/// - Location-based discovery (1.2): Implements location-based listing queries
/// - AI-powered furniture recognition (1.2): Handles AI-categorized listings
/// - Data Types (1.3): Manages furniture listing data operations
@MainActor
public final class ListingService {
    // MARK: - Private Properties
    
    private let apiClient: APIClient
    private let listingsSubject = CurrentValueSubject<[Listing], Never>([])
    
    // MARK: - Initialization
    
    /// Initializes the listing service with an API client
    /// - Parameter apiClient: The API client for network operations
    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    // MARK: - Public Methods
    
    /// Creates a new furniture listing with images
    /// - Parameters:
    ///   - title: Title of the listing
    ///   - description: Detailed description of the furniture
    ///   - category: Furniture category
    ///   - condition: Condition of the furniture
    ///   - location: Location of the furniture
    ///   - images: Array of image data
    /// - Returns: Created listing with server-generated ID
    public func createListing(
        title: String,
        description: String,
        category: FurnitureCategory,
        condition: FurnitureCondition,
        location: Location,
        images: [Data]
    ) async throws -> Listing {
        // Create listing first
        let endpoint = ListingEndpoint.createListing(
            title: title,
            description: description,
            category: category,
            condition: condition,
            location: location,
            images: images
        )
        
        let listing = try await apiClient.request(endpoint)
        
        // Upload images
        for imageData in images {
            let uploadEndpoint = ListingEndpoint.uploadListingImage(
                listingId: listing.id,
                imageData: imageData
            )
            _ = try await apiClient.uploadData(imageData, endpoint: uploadEndpoint)
        }
        
        // Update listings subject
        var currentListings = listingsSubject.value
        currentListings.append(listing)
        listingsSubject.send(currentListings)
        
        return listing
    }
    
    /// Retrieves a specific listing by ID
    /// - Parameter id: UUID of the listing
    /// - Returns: Retrieved listing details
    public func getListing(_ id: UUID) async throws -> Listing {
        let endpoint = ListingEndpoint.getListing(id)
        return try await apiClient.request(endpoint)
    }
    
    /// Retrieves listings near a specified location
    /// - Parameters:
    ///   - coordinates: Location coordinates
    ///   - radius: Search radius in kilometers
    /// - Returns: Array of nearby listings
    public func getNearbyListings(
        coordinates: CLLocationCoordinate2D,
        radius: Double
    ) async throws -> [Listing] {
        let endpoint = ListingEndpoint.getNearbyListings(
            coordinates: coordinates,
            radius: radius
        )
        
        let listings = try await apiClient.request(endpoint)
        listingsSubject.send(listings)
        return listings
    }
    
    /// Updates the status of a listing
    /// - Parameters:
    ///   - id: UUID of the listing
    ///   - status: New listing status
    /// - Returns: Updated listing
    public func updateListingStatus(
        _ id: UUID,
        status: ListingStatus
    ) async throws -> Listing {
        let endpoint = ListingEndpoint.updateListing(id, status: status)
        let updatedListing = try await apiClient.request(endpoint)
        
        // Update listings subject
        var currentListings = listingsSubject.value
        if let index = currentListings.firstIndex(where: { $0.id == id }) {
            currentListings[index] = updatedListing
            listingsSubject.send(currentListings)
        }
        
        return updatedListing
    }
    
    /// Deletes a listing by ID
    /// - Parameter id: UUID of the listing to delete
    public func deleteListing(_ id: UUID) async throws {
        let endpoint = ListingEndpoint.deleteListing(id)
        _ = try await apiClient.request(endpoint)
        
        // Update listings subject
        var currentListings = listingsSubject.value
        currentListings.removeAll { $0.id == id }
        listingsSubject.send(currentListings)
    }
}