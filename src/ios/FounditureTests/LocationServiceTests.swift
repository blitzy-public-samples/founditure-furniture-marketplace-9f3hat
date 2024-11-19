//
// LocationServiceTests.swift
// FounditureTests
//
// Human Tasks:
// 1. Verify test environment has proper location permissions configured
// 2. Ensure test data matches production data format requirements
// 3. Configure proper test timeout values for async operations
// 4. Set up mock location services for CI/CD pipeline

import XCTest // Latest
import CoreLocation // Latest
import Combine // Latest
@testable import Founditure

/// Test suite for LocationService functionality
/// Requirements addressed:
/// - 1.2 System Overview/Core Features: Location-based furniture discovery with real-time updates
/// - 1.3 Scope/Implementation Boundaries: Major urban centers in North America with configurable search radius
@MainActor
final class LocationServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: LocationService!
    private var mockAPIClient: APIClient!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Lifecycle
    
    override func setUp() async throws {
        try await super.setUp()
        mockAPIClient = APIClient()
        sut = LocationService(apiClient: mockAPIClient)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        sut.stopLocationUpdates()
        cancellables.removeAll()
        mockAPIClient = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Location Update Tests
    
    func testStartLocationUpdates() async throws {
        // Given
        let expectation = expectation(description: "Location updates started")
        var receivedLocations: [Location] = []
        
        // When
        sut.nearbyLocationsPublisher
            .sink { locations in
                receivedLocations = locations
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        try await sut.startLocationUpdates()
        
        // Simulate location update
        let testLocation = Location(
            coordinates: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "123 Test St",
            city: "San Francisco",
            state: "CA",
            country: "USA",
            postalCode: "94105"
        )
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(receivedLocations.isEmpty) // Initial state before updates
    }
    
    func testStopLocationUpdates() {
        // Given
        let expectation = expectation(description: "Location updates stopped")
        var updateCount = 0
        
        sut.nearbyLocationsPublisher
            .sink { _ in
                updateCount += 1
            }
            .store(in: &cancellables)
        
        // When
        sut.stopLocationUpdates()
        
        // Then
        XCTAssertEqual(updateCount, 0)
        expectation.fulfill()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Search Tests
    
    func testSearchNearbyFurniture() async throws {
        // Given
        let testLocation = Location(
            coordinates: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "123 Test St",
            city: "San Francisco",
            state: "CA",
            country: "USA",
            postalCode: "94105"
        )
        
        let expectation = expectation(description: "Search completed")
        var receivedLocations: [Location] = []
        
        sut.nearbyLocationsPublisher
            .sink { locations in
                receivedLocations = locations
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        let searchResults = try await sut.searchNearbyFurniture(location: testLocation)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertEqual(searchResults, receivedLocations)
    }
    
    func testUpdateSearchRadius() {
        // Given
        let expectation = expectation(description: "Search radius updated")
        let newRadius = 10.0 // kilometers
        var receivedLocations: [Location] = []
        
        sut.nearbyLocationsPublisher
            .sink { locations in
                receivedLocations = locations
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.updateSearchRadius(newRadius)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(receivedLocations.isEmpty) // Initial state before location update
    }
    
    // MARK: - Error Handling Tests
    
    func testSearchNearbyFurnitureWithInvalidLocation() async throws {
        // Given
        let invalidLocation = Location(
            coordinates: CLLocationCoordinate2D(latitude: 200, longitude: 200), // Invalid coordinates
            address: "Invalid",
            city: nil,
            state: nil,
            country: "Invalid",
            postalCode: "00000"
        )
        
        // When/Then
        do {
            _ = try await sut.searchNearbyFurniture(location: invalidLocation)
            XCTFail("Expected error for invalid location")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
    
    func testUpdateSearchRadiusWithInvalidValue() {
        // Given
        let invalidRadius = -1.0
        
        // When
        sut.updateSearchRadius(invalidRadius)
        
        // Then
        // Verify that the invalid radius was rejected (no changes made)
        let expectation = expectation(description: "No updates received")
        var updateReceived = false
        
        sut.nearbyLocationsPublisher
            .sink { _ in
                updateReceived = true
            }
            .store(in: &cancellables)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
        XCTAssertFalse(updateReceived)
    }
}