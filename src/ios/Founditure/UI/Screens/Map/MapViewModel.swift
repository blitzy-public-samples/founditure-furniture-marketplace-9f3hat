// Foundation framework - Latest
import Foundation
// CoreLocation framework - Latest
import CoreLocation
// MapKit framework - Latest
import MapKit
// Combine framework - Latest
import Combine

// Internal imports with relative paths
import "../../../Services/LocationService"
import "../../../Models/Location"
import "../../../Models/Listing"

/// Human Tasks:
/// 1. Verify proper location permission handling in Info.plist
/// 2. Configure map region span values based on device performance
/// 3. Review location update frequency for battery optimization
/// 4. Set up proper error logging for location service failures

/// ViewModel for the map screen that manages location-based furniture discovery
/// Requirements addressed:
/// - 1.2 System Overview/Core Features: Location-based furniture discovery
/// - 1.3 Scope/Implementation Boundaries: Major urban centers in North America
@MainActor
final class MapViewModel {
    // MARK: - Private Properties
    
    private let locationService: LocationService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    
    @Published private(set) var nearbyListings: [Listing] = []
    @Published private(set) var userLocation: Location?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var searchRadius: Double = 5000 // Default 5km radius
    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default center
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) // Default span
    )
    
    // MARK: - Initialization
    
    /// Initializes the map view model with required services
    init(locationService: LocationService) {
        self.locationService = locationService
        
        // Setup location updates subscription
        setupLocationUpdates()
    }
    
    // MARK: - Private Methods
    
    private func setupLocationUpdates() {
        locationService.nearbyLocationsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] locations in
                guard let self = self else { return }
                Task {
                    // Update user location with first location if available
                    if let firstLocation = locations.first {
                        self.userLocation = firstLocation
                        self.updateMapRegion(for: firstLocation.coordinates)
                    }
                    
                    // Refresh nearby listings
                    try? await self.refreshNearbyListings()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateMapRegion(for coordinates: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(
            latitudeDelta: searchRadius / 111000, // Convert meters to degrees (approx)
            longitudeDelta: searchRadius / 111000
        )
        mapRegion = MKCoordinateRegion(center: coordinates, span: span)
    }
    
    // MARK: - Public Methods
    
    /// Begins monitoring user location and nearby furniture discovery
    func startLocationUpdates() async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await locationService.startLocationUpdates()
    }
    
    /// Updates the search radius for furniture discovery
    func updateSearchRadius(_ radius: Double) {
        guard radius > 0 else { return }
        
        searchRadius = radius
        locationService.updateSearchRadius(radius)
        
        if let location = userLocation {
            updateMapRegion(for: location.coordinates)
        }
        
        Task {
            try? await refreshNearbyListings()
        }
    }
    
    /// Refreshes the list of nearby furniture listings
    func refreshNearbyListings() async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let location = userLocation else {
            return
        }
        
        let locations = try await locationService.searchNearbyFurniture(
            location: location,
            radius: searchRadius
        )
        
        // Update listings array with results
        nearbyListings = locations.compactMap { location in
            // Convert location to listing if it has associated listing data
            // This would typically come from the API response
            return Listing(
                title: "",
                description: "",
                category: .other,
                condition: .good,
                location: location,
                userId: UUID(),
                imageUrls: [],
                aiTags: [],
                aiConfidenceScore: 0.0
            )
        }
    }
    
    /// Handles selection of a furniture listing on the map
    func selectListing(_ listing: Listing) {
        let coordinates = listing.location.coordinates
        updateMapRegion(for: coordinates)
    }
}