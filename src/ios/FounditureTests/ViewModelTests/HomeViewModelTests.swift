// XCTest framework - Latest
import XCTest
// Combine framework - Latest
import Combine
// CoreLocation framework - Latest
import CoreLocation
@testable import Founditure

/// Human Tasks:
/// 1. Configure test data fixtures for consistent test scenarios
/// 2. Set up proper mocking of location services in CI environment
/// 3. Verify proper cleanup of test subscriptions
/// 4. Configure test coverage reporting thresholds

/// Test suite for HomeViewModel functionality
/// Requirements addressed:
/// - Location-based discovery (1.2): Tests for location-based furniture discovery with real-time updates
/// - User Engagement (1.2): Tests for home feed functionality driving 70% monthly active user retention
@MainActor
final class HomeViewModelTests: XCTestCase {
    // MARK: - Properties
    
    private var sut: HomeViewModel!
    private var mockListingService: MockListingService!
    private var mockLocationService: MockLocationService!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        mockListingService = MockListingService()
        mockLocationService = MockLocationService()
        sut = HomeViewModel(listingService: mockListingService, locationService: mockLocationService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        cancellables.removeAll()
        mockListingService = nil
        mockLocationService = nil
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Tests initial state of HomeViewModel
    /// Requirements addressed:
    /// - User Engagement (1.2): Verify initial home feed state
    func testInitialState() {
        XCTAssertTrue(sut.nearbyListings.isEmpty, "Initial listings should be empty")
        XCTAssertFalse(sut.isLoading, "Should not be loading initially")
        XCTAssertNil(sut.error, "Should not have initial error")
    }
    
    /// Tests successful listing refresh operation
    /// Requirements addressed:
    /// - Location-based discovery (1.2): Verify successful furniture discovery
    func testRefreshListingsSuccess() async throws {
        // Prepare test data
        let testLocation = Location(
            coordinates: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "Test Address",
            country: "USA",
            postalCode: "94105"
        )
        
        let testListings = [
            createTestListing(id: UUID(), title: "Test Chair"),
            createTestListing(id: UUID(), title: "Test Table")
        ]
        
        // Configure mocks
        mockLocationService.currentLocation = testLocation
        mockListingService.mockNearbyListings = testListings
        
        // Test loading state changes
        let loadingExpectation = expectation(description: "Loading state should change")
        var loadingStates: [Bool] = []
        
        sut.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count == 2 {
                    loadingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Perform refresh
        try await sut.refreshListings()
        
        await fulfillment(of: [loadingExpectation], timeout: 1.0)
        
        // Verify state changes
        XCTAssertEqual(loadingStates, [true, false], "Should transition from loading to not loading")
        XCTAssertEqual(sut.nearbyListings.count, testListings.count, "Should update listings")
        XCTAssertNil(sut.error, "Should not have error")
    }
    
    /// Tests listing refresh operation failure
    /// Requirements addressed:
    /// - Location-based discovery (1.2): Verify error handling in furniture discovery
    func testRefreshListingsFailure() async throws {
        // Configure mock to throw error
        let testError = APIError.networkError(NSError(domain: "test", code: -1))
        mockListingService.mockError = testError
        
        // Test loading and error state changes
        let stateExpectation = expectation(description: "State changes should complete")
        var loadingStates: [Bool] = []
        var errors: [Error?] = []
        
        sut.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)
        
        sut.$error
            .sink { error in
                errors.append(error)
                if errors.count == 2 {
                    stateExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Perform refresh
        try? await sut.refreshListings()
        
        await fulfillment(of: [stateExpectation], timeout: 1.0)
        
        // Verify error handling
        XCTAssertEqual(loadingStates, [true, false], "Should transition from loading to not loading")
        XCTAssertTrue(sut.nearbyListings.isEmpty, "Should not update listings on error")
        XCTAssertNotNil(sut.error, "Should have error")
    }
    
    /// Tests location-based listing updates
    /// Requirements addressed:
    /// - Location-based discovery (1.2): Verify real-time location updates
    func testLocationUpdates() async throws {
        // Prepare test data
        let testLocation = Location(
            coordinates: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "Test Address",
            country: "USA",
            postalCode: "94105"
        )
        
        let testListings = [
            createTestListing(id: UUID(), title: "Nearby Chair"),
            createTestListing(id: UUID(), title: "Nearby Table")
        ]
        
        // Configure mocks
        mockLocationService.currentLocation = testLocation
        mockListingService.mockNearbyListings = testListings
        
        // Test location updates
        let updateExpectation = expectation(description: "Location updates should trigger listing refresh")
        
        sut.$nearbyListings
            .dropFirst()
            .sink { listings in
                XCTAssertEqual(listings.count, testListings.count)
                updateExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulate location update
        mockLocationService.nearbyLocationsPublisher.send([testLocation])
        
        await fulfillment(of: [updateExpectation], timeout: 1.0)
        
        // Verify location service interactions
        XCTAssertTrue(mockLocationService.startLocationUpdatesCalled)
        XCTAssertTrue(mockLocationService.searchNearbyFurnitureCalled)
    }
    
    /// Tests filtering of expired listings
    /// Requirements addressed:
    /// - User Engagement (1.2): Verify content quality through expired listing filtering
    func testExpiredListingsFiltering() async throws {
        // Prepare test data with mix of expired and valid listings
        let validListing = createTestListing(id: UUID(), title: "Valid Listing")
        let expiredListing = createTestListing(id: UUID(), title: "Expired Listing", isExpired: true)
        
        mockListingService.mockNearbyListings = [validListing, expiredListing]
        
        // Perform refresh
        try await sut.refreshListings()
        
        // Verify filtering
        XCTAssertEqual(sut.nearbyListings.count, 1, "Should filter out expired listings")
        XCTAssertEqual(sut.nearbyListings.first?.title, "Valid Listing")
    }
    
    // MARK: - Helper Methods
    
    private func createTestListing(id: UUID, title: String, isExpired: Bool = false) -> Listing {
        let listing = Listing(
            title: title,
            description: "Test Description",
            category: .chair,
            condition: .good,
            location: Location(
                coordinates: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                address: "Test Address",
                country: "USA",
                postalCode: "94105"
            ),
            userId: UUID(),
            imageUrls: [],
            aiTags: [],
            aiConfidenceScore: 0.9
        )
        
        if isExpired {
            listing.updateStatus(.expired)
        }
        
        return listing
    }
}

// MARK: - Mock Services

private class MockListingService: ListingService {
    var mockNearbyListings: [Listing] = []
    var mockError: Error?
    
    override func getNearbyListings(coordinates: CLLocationCoordinate2D, radius: Double) async throws -> [Listing] {
        if let error = mockError {
            throw error
        }
        return mockNearbyListings
    }
}

private class MockLocationService: LocationService {
    var startLocationUpdatesCalled = false
    var searchNearbyFurnitureCalled = false
    var currentLocation: Location?
    let nearbyLocationsPublisher = PassthroughSubject<[Location], Never>()
    
    override func startLocationUpdates() async throws {
        startLocationUpdatesCalled = true
    }
    
    override func searchNearbyFurniture(location: Location, radius: Double?) async throws -> [Location] {
        searchNearbyFurnitureCalled = true
        return [location]
    }
}