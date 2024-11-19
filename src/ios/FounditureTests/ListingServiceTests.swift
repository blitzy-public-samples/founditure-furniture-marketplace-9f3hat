// XCTest framework - Latest
import XCTest
// Combine framework - Latest
import Combine
@testable import Founditure

/// Human Tasks:
/// 1. Configure test data fixtures for different listing scenarios
/// 2. Set up proper test environment configuration
/// 3. Verify mock responses match production API format
/// 4. Configure proper test coverage reporting
/// 5. Set up CI/CD test automation pipeline

/// ListingServiceTests: Test suite for ListingService functionality
/// Requirements addressed:
/// - Location-based discovery (1.2): Tests for location-based listing retrieval
/// - AI-powered furniture recognition (1.2): Tests for AI-categorized listings
/// - Data Types (1.3): Tests for listing data operations
final class ListingServiceTests: XCTestCase {
    // MARK: - Properties
    
    private var sut: ListingService!
    private var mockAPIClient: MockAPIClient!
    
    // MARK: - Setup/Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        mockAPIClient = MockAPIClient()
        sut = ListingService(apiClient: mockAPIClient)
    }
    
    override func tearDown() async throws {
        mockAPIClient.mockResponses.removeAll()
        mockAPIClient.requestHistory.removeAll()
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Tests creating a new listing with images
    func testCreateListing() async throws {
        // Prepare test data
        let testTitle = "Vintage Armchair"
        let testDescription = "Beautiful vintage armchair in excellent condition"
        let testCategory = FurnitureCategory.chair
        let testCondition = FurnitureCondition.excellent
        let testLocation = Location(
            coordinates: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "123 Test St",
            city: "San Francisco",
            state: "CA",
            country: "USA",
            postalCode: "94105"
        )
        let testImages = [Data(repeating: 0, count: 1024)]
        
        // Configure mock responses
        let expectedListing = Listing(
            title: testTitle,
            description: testDescription,
            category: testCategory,
            condition: testCondition,
            location: testLocation,
            userId: UUID(),
            imageUrls: [],
            aiTags: ["vintage", "chair"],
            aiConfidenceScore: 0.95
        )
        
        mockAPIClient.mockResponses["createListing"] = expectedListing
        mockAPIClient.mockResponses["uploadListingImage"] = expectedListing
        
        // Perform test
        let result = try await sut.createListing(
            title: testTitle,
            description: testDescription,
            category: testCategory,
            condition: testCondition,
            location: testLocation,
            images: testImages
        )
        
        // Verify results
        XCTAssertEqual(result.title, testTitle)
        XCTAssertEqual(result.description, testDescription)
        XCTAssertEqual(result.category, testCategory)
        XCTAssertEqual(result.condition, testCondition)
        XCTAssertEqual(result.location.address, testLocation.address)
        
        // Verify API calls
        XCTAssertEqual(mockAPIClient.requestHistory.count, 2) // Create + Upload
        XCTAssertTrue(mockAPIClient.requestHistory[0].0.url?.path.contains("/listings") ?? false)
        XCTAssertTrue(mockAPIClient.requestHistory[1].0.url?.path.contains("/images") ?? false)
    }
    
    /// Tests retrieving a specific listing by ID
    func testGetListing() async throws {
        // Prepare test data
        let testId = UUID()
        let expectedListing = Listing(
            title: "Test Listing",
            description: "Test Description",
            category: .chair,
            condition: .good,
            location: Location(
                coordinates: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                address: "123 Test St",
                city: "San Francisco",
                state: "CA",
                country: "USA",
                postalCode: "94105"
            ),
            userId: UUID(),
            imageUrls: [],
            aiTags: ["test"],
            aiConfidenceScore: 0.9
        )
        
        // Configure mock response
        mockAPIClient.mockResponses["getListing"] = expectedListing
        
        // Perform test
        let result = try await sut.getListing(testId)
        
        // Verify results
        XCTAssertEqual(result.id, expectedListing.id)
        XCTAssertEqual(result.title, expectedListing.title)
        XCTAssertEqual(result.description, expectedListing.description)
        
        // Verify API call
        XCTAssertEqual(mockAPIClient.requestHistory.count, 1)
        XCTAssertTrue(mockAPIClient.requestHistory[0].0.url?.path.contains("/listings/\(testId)") ?? false)
    }
    
    /// Tests retrieving listings near a location
    func testGetNearbyListings() async throws {
        // Prepare test data
        let testCoordinates = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let testRadius = 5.0
        let expectedListings = [
            Listing(
                title: "Nearby Listing 1",
                description: "Test Description 1",
                category: .sofa,
                condition: .excellent,
                location: Location(
                    coordinates: CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195),
                    address: "456 Test St",
                    city: "San Francisco",
                    state: "CA",
                    country: "USA",
                    postalCode: "94105"
                ),
                userId: UUID(),
                imageUrls: [],
                aiTags: ["nearby"],
                aiConfidenceScore: 0.85
            )
        ]
        
        // Configure mock response
        mockAPIClient.mockResponses["getNearbyListings"] = expectedListings
        
        // Perform test
        let results = try await sut.getNearbyListings(coordinates: testCoordinates, radius: testRadius)
        
        // Verify results
        XCTAssertEqual(results.count, expectedListings.count)
        XCTAssertEqual(results[0].title, expectedListings[0].title)
        
        // Verify location calculations
        let distance = results[0].location.distanceTo(expectedListings[0].location)
        XCTAssertLessThan(distance, testRadius * 1000) // Convert km to meters
        
        // Verify API call
        XCTAssertEqual(mockAPIClient.requestHistory.count, 1)
        XCTAssertTrue(mockAPIClient.requestHistory[0].0.url?.path.contains("/listings/nearby") ?? false)
    }
    
    /// Tests updating a listing's status
    func testUpdateListingStatus() async throws {
        // Prepare test data
        let testId = UUID()
        let newStatus = ListingStatus.collected
        let expectedListing = Listing(
            title: "Test Listing",
            description: "Test Description",
            category: .table,
            condition: .good,
            location: Location(
                coordinates: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                address: "789 Test St",
                city: "San Francisco",
                state: "CA",
                country: "USA",
                postalCode: "94105"
            ),
            userId: UUID(),
            imageUrls: [],
            aiTags: ["test"],
            aiConfidenceScore: 0.88
        )
        expectedListing.updateStatus(newStatus)
        
        // Configure mock response
        mockAPIClient.mockResponses["updateListing"] = expectedListing
        
        // Perform test
        let result = try await sut.updateListingStatus(testId, status: newStatus)
        
        // Verify results
        XCTAssertEqual(result.status, newStatus)
        XCTAssertNotNil(result.collectedAt)
        
        // Verify API call
        XCTAssertEqual(mockAPIClient.requestHistory.count, 1)
        XCTAssertTrue(mockAPIClient.requestHistory[0].0.url?.path.contains("/listings/\(testId)") ?? false)
    }
    
    /// Tests deleting a listing
    func testDeleteListing() async throws {
        // Prepare test data
        let testId = UUID()
        
        // Configure mock response
        mockAPIClient.mockResponses["deleteListing"] = true
        
        // Perform test
        try await sut.deleteListing(testId)
        
        // Verify API call
        XCTAssertEqual(mockAPIClient.requestHistory.count, 1)
        XCTAssertTrue(mockAPIClient.requestHistory[0].0.url?.path.contains("/listings/\(testId)") ?? false)
        XCTAssertEqual(mockAPIClient.requestHistory[0].0.httpMethod, "DELETE")
    }
}

// MARK: - Mock API Client

private final class MockAPIClient: APIClient {
    // MARK: - Properties
    
    var mockResponses: [String: Any] = [:]
    var requestHistory: [(URLRequest, Date)] = []
    
    // MARK: - Override Methods
    
    override func request<T>(_ endpoint: T) async throws -> T.Response where T : APIEndpoint {
        // Record request
        if let urlRequest = try? endpoint.asURLRequest() {
            requestHistory.append((urlRequest, Date()))
        }
        
        // Return mock response based on endpoint type
        let mockKey: String
        switch endpoint {
        case is ListingEndpoint:
            switch endpoint as! ListingEndpoint {
            case .createListing: mockKey = "createListing"
            case .getListing: mockKey = "getListing"
            case .updateListing: mockKey = "updateListing"
            case .deleteListing: mockKey = "deleteListing"
            case .getNearbyListings: mockKey = "getNearbyListings"
            case .uploadListingImage: mockKey = "uploadListingImage"
            }
        default:
            throw APIError.invalidRequest("Unsupported endpoint")
        }
        
        guard let response = mockResponses[mockKey] as? T.Response else {
            throw APIError.invalidResponse(404)
        }
        
        return response
    }
}