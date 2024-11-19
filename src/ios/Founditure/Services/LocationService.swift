//
// LocationService.swift
// Founditure
//
// Human Tasks:
// 1. Verify location permission strings are properly configured in Info.plist
// 2. Review background location update frequency for battery optimization
// 3. Configure proper error logging for location service failures
// 4. Verify geofencing limits for target iOS versions

import Foundation // Latest
import CoreLocation // Latest
import Combine // Latest

// Internal imports with relative paths
import "../Core/Utilities/LocationManager"
import "../Models/Location"
import "../Core/Network/APIClient"

/// LocationService: Service layer class managing location-based furniture discovery operations
/// Requirements addressed:
/// - 1.2 System Overview/Core Features: Location-based furniture discovery
/// - 1.3 Scope/Implementation Boundaries: Major urban centers in North America
/// - 2.2 Component Details/2.2.1 Core Components: Location-based discovery services
@MainActor
final class LocationService {
    // MARK: - Private Properties
    
    /// Core location manager instance
    private let locationManager: LocationManager
    
    /// API client for network requests
    private let apiClient: APIClient
    
    /// Publisher for nearby furniture locations
    private let nearbyLocationsPublisher = PassthroughSubject<[Location], Never>()
    
    /// Set of active search request identifiers
    private var activeSearches: Set<UUID> = []
    
    // MARK: - Initialization
    
    /// Initializes the location service with required dependencies
    /// - Parameter apiClient: API client instance for network communication
    init(apiClient: APIClient) {
        self.apiClient = apiClient
        self.locationManager = LocationManager.shared
    }
    
    // MARK: - Public Methods
    
    /// Begins monitoring location updates and nearby furniture discovery
    /// - Throws: Location permission or monitoring errors
    func startLocationUpdates() async throws {
        // Start location monitoring
        locationManager.startMonitoringLocation()
        
        // Subscribe to location updates
        locationManager.locationPublisher
            .sink { [weak self] location in
                Task {
                    try? await self?.searchNearbyFurniture(location: location)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Stops location monitoring and furniture discovery
    func stopLocationUpdates() {
        // Stop location monitoring
        locationManager.stopMonitoringLocation()
        
        // Clear active searches
        activeSearches.removeAll()
        
        // Send completion to publisher
        nearbyLocationsPublisher.send(completion: .finished)
    }
    
    /// Searches for furniture items near the specified location
    /// - Parameters:
    ///   - location: Location to search around
    ///   - radius: Optional search radius in kilometers
    /// - Returns: Array of nearby furniture locations
    /// - Throws: API or network errors
    func searchNearbyFurniture(location: Location, radius: Double? = nil) async throws -> [Location] {
        // Create search request
        let searchId = UUID()
        activeSearches.insert(searchId)
        
        // Prepare request parameters
        var parameters: [String: Any] = [
            "latitude": location.coordinates.latitude,
            "longitude": location.coordinates.longitude
        ]
        
        if let radius = radius {
            parameters["radius"] = radius
        }
        
        // Send API request
        let endpoint = FurnitureEndpoints.nearby(parameters)
        let response: LocationSearchResponse = try await apiClient.request(endpoint)
        
        // Process response if search is still active
        guard activeSearches.contains(searchId) else {
            return []
        }
        
        // Convert response to locations
        let nearbyLocations = response.locations
        
        // Publish update
        nearbyLocationsPublisher.send(nearbyLocations)
        
        return nearbyLocations
    }
    
    /// Updates the search radius for furniture discovery
    /// - Parameter radius: New search radius in kilometers
    func updateSearchRadius(_ radius: Double) {
        guard radius > 0 else { return }
        
        // Update location manager radius
        locationManager.updateSearchRadius(radius)
        
        // Refresh search with current location if available
        if let currentLocation = locationManager.currentLocation {
            Task {
                try? await searchNearbyFurniture(location: currentLocation, radius: radius)
            }
        }
    }
    
    // MARK: - Private Properties
    
    /// Set to store cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Supporting Types

/// Response type for location search requests
private struct LocationSearchResponse: Decodable {
    let locations: [Location]
}