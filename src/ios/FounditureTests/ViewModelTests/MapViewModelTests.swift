// XCTest framework - Latest
import XCTest
// CoreLocation framework - Latest
import CoreLocation
// MapKit framework - Latest
import MapKit
// Combine framework - Latest
import Combine

@testable import Founditure

/// Human Tasks:
/// 1. Configure proper test data for different geographic regions
/// 2. Set up mock location permissions for testing
/// 3. Verify test coverage meets minimum requirements
/// 4. Configure CI/CD pipeline for automated testing

/// Test suite for MapViewModel functionality with Combine integration
/// Requirements addressed:
/// - Location-based discovery (1.2 System Overview/Core Features)
/// - Geographic Boundaries (1.3 Scope/Implementation Boundaries)
@MainActor
final class MapViewModelTests: XCTestCase {
    // MARK: - Properties
    
    private var sut: MapViewModel!
    private var mockLocationService: LocationService!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Test Lifecycle
    
    override func setUpWithError() throws {
        // Create mock location service
        mockLocationService = LocationService(apiClient: MockAPIClient())
        
        // Initialize system under test with mock service
        sut = MapViewModel(locationService: mockLocationService)
        
        // Initialize empty cancellables set
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        // Cancel all subscriptions
        cancellables.removeAll()
        
        // Release memory
        sut = nil
        mockLocationService = nil
    }
    
    // MARK: - Test Cases
    
    /// Tests successful location updates initialization
    /// Requirements addressed:
    /// - Location-based discovery: Verifies real-time location updates
    func testStartLocationUpdatesSuccess() async throws {
        // Given
        let expectation = expectation(description: "Location updates started")
        let testLocation = Location(
            coordinates: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "Test Address",
            country: "USA",
            postalCode: "94105"
        )
        
        // When
        sut.$isLoading
            .dropFirst()
            .sink { isLoading in
                if !isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate location update
        mockLocationService.nearbyLocationsPublisher.send([testLocation])
        
        try await sut.startLocationUpdates()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(sut.userLocation?.coordinates.latitude, testLocation.coordinates.latitude)
        XCTAssertEqual(sut.userLocation?.coordinates.longitude, testLocation.coordinates.longitude)
        XCTAssertFalse(sut.isLoading)
        
        // Verify map region updated
        XCTAssertEqual(sut.mapRegion.center.latitude, testLocation.coordinates.latitude)
        XCTAssertEqual(sut.mapRegion.center.longitude, testLocation.coordinates.longitude)
    }
    
    /// Tests nearby listings update when location changes
    /// Requirements addressed:
    /// - Location-based discovery: Verifies furniture discovery updates
    /// - Geographic Boundaries: Tests search radius constraints
    func testNearbyListingsUpdate() async throws {
        // Given
        let expectation = expectation(description: "Listings updated")
        let userLocation = Location(
            coordinates: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "User Location",
            country: "USA",
            postalCode: "94105"
        )
        
        let testListings = [
            createTestListing(latitude: 37.7749, longitude: -122.4194, distance: 1000),
            createTestListing(latitude: 37.7850, longitude: -122.4300, distance: 2000),
            createTestListing(latitude: 37.7650, longitude: -122.4100, distance: 4000)
        ]
        
        // When
        sut.$nearbyListings
            .dropFirst()
            .sink { listings in
                if !listings.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Set user location
        mockLocationService.nearbyLocationsPublisher.send([userLocation])
        
        // Simulate listings update
        mockLocationService.nearbyLocationsPublisher.send(testListings.map { $0.location })
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(sut.nearbyListings.count, testListings.count)
        
        // Verify listings are sorted by distance
        let distances = sut.nearbyListings.map { $0.distanceFrom(userLocation) }
        XCTAssertEqual(distances, distances.sorted())
    }
    
    /// Tests search radius update functionality
    /// Requirements addressed:
    /// - Geographic Boundaries: Verifies search radius adjustments
    func testSearchRadiusUpdate() async throws {
        // Given
        let expectation = expectation(description: "Search radius updated")
        let newRadius: Double = 10000 // 10km
        
        // When
        sut.$searchRadius
            .dropFirst()
            .sink { radius in
                if radius == newRadius {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        sut.updateSearchRadius(newRadius)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(sut.searchRadius, newRadius)
        
        // Verify map region span updated proportionally
        let expectedSpan = newRadius / 111000 // Convert meters to degrees (approx)
        XCTAssertEqual(sut.mapRegion.span.latitudeDelta, expectedSpan, accuracy: 0.001)
        XCTAssertEqual(sut.mapRegion.span.longitudeDelta, expectedSpan, accuracy: 0.001)
    }
    
    /// Tests listing selection on map
    /// Requirements addressed:
    /// - Location-based discovery: Verifies listing selection behavior
    func testListingSelection() async throws {
        // Given
        let testListing = createTestListing(
            latitude: 37.7749,
            longitude: -122.4194,
            distance: 1000
        )
        
        // When
        sut.selectListing(testListing)
        
        // Then
        XCTAssertEqual(sut.mapRegion.center.latitude, testListing.location.coordinates.latitude)
        XCTAssertEqual(sut.mapRegion.center.longitude, testListing.location.coordinates.longitude)
    }
    
    // MARK: - Helper Methods
    
    private func createTestListing(latitude: Double, longitude: Double, distance: Double) -> Listing {
        let location = Location(
            coordinates: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            address: "Test Address",
            country: "USA",
            postalCode: "94105"
        )
        
        return Listing(
            title: "Test Listing",
            description: "Test Description",
            category: .other,
            condition: .good,
            location: location,
            userId: UUID(),
            imageUrls: [],
            aiTags: [],
            aiConfidenceScore: 0.9
        )
    }
}

// MARK: - Mock API Client

private class MockAPIClient: APIClient {
    override init() {
        super.init(session: .shared)
    }
}