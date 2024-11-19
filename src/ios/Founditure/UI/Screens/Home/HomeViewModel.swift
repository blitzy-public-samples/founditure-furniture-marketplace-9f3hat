// Foundation framework - Latest
import Foundation
// Combine framework - Latest
import Combine
// CoreLocation framework - Latest
import CoreLocation

/// Human Tasks:
/// 1. Configure proper error logging for listing fetch failures
/// 2. Review location update frequency for battery optimization
/// 3. Verify proper handling of background location updates
/// 4. Set up monitoring for listing refresh failures
/// 5. Configure proper caching policy for listing data

/// ViewModel managing the home screen state and business logic with reactive updates
/// Requirements addressed:
/// - Location-based discovery (1.2): Location-based furniture discovery with real-time updates
/// - Core Features (1.3): Location-based furniture discovery
/// - User Engagement (1.2): 70% monthly active user retention through engaging home feed
@MainActor
public final class HomeViewModel {
    // MARK: - Published Properties
    
    /// Currently displayed nearby furniture listings
    @Published private(set) var nearbyListings: [Listing] = []
    
    /// Loading state indicator
    @Published private(set) var isLoading: Bool = false
    
    /// Current error state
    @Published private(set) var error: Error?
    
    // MARK: - Private Properties
    
    /// Service for managing furniture listings
    private let listingService: ListingService
    
    /// Service for handling location updates
    private let locationService: LocationService
    
    /// Set to store active Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Timer for automatic listing refresh
    private var refreshTimer: Timer?
    
    /// Default search radius in meters
    private let defaultSearchRadius: Double = 5000.0
    
    /// Refresh interval in seconds (5 minutes)
    private let refreshInterval: TimeInterval = 300.0
    
    // MARK: - Initialization
    
    /// Initializes the home view model with required services
    /// - Parameters:
    ///   - listingService: Service for managing furniture listings
    ///   - locationService: Service for handling location updates
    public init(listingService: ListingService, locationService: LocationService) {
        self.listingService = listingService
        self.locationService = locationService
        
        setupLocationUpdates()
        setupRefreshTimer()
    }
    
    // MARK: - Private Methods
    
    /// Configures location-based updates for nearby listings
    private func setupLocationUpdates() {
        Task {
            do {
                try await locationService.startLocationUpdates()
                
                // Subscribe to location updates
                locationService.nearbyLocationsPublisher
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] locations in
                        Task {
                            try? await self?.refreshListings()
                        }
                    }
                    .store(in: &cancellables)
                
                // Initial listings fetch
                try await refreshListings()
            } catch {
                self.error = error
            }
        }
    }
    
    /// Sets up automatic refresh timer
    private func setupRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: refreshInterval,
            repeats: true
        ) { [weak self] _ in
            Task {
                try? await self?.refreshListings()
            }
        }
    }
    
    /// Refreshes the nearby listings data
    /// - Throws: API or network errors
    public func refreshListings() async throws {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            // Get current location from location service
            guard let currentLocation = await locationService.locationManager.currentLocation else {
                throw APIError.invalidRequest("Location not available")
            }
            
            // Fetch nearby listings
            let listings = try await listingService.getNearbyListings(
                coordinates: currentLocation.coordinates,
                radius: defaultSearchRadius
            )
            
            // Filter out expired listings
            let validListings = listings.filter { !$0.isExpired() }
            
            // Update listings on main thread
            await MainActor.run {
                self.nearbyListings = validListings
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    /// Removes expired listings from the display
    private func filterExpiredListings() {
        nearbyListings = nearbyListings.filter { !$0.isExpired() }
    }
    
    // MARK: - Deinitialization
    
    deinit {
        refreshTimer?.invalidate()
        cancellables.removeAll()
    }
}