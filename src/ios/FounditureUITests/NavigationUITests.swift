// XCTest framework - Latest
import XCTest

/// Human Tasks:
/// 1. Verify test coverage for all critical navigation paths
/// 2. Test navigation performance with slow network conditions
/// 3. Validate Material Design 3 transition animations
/// 4. Test navigation with different device orientations
/// 5. Verify deep linking navigation scenarios

/// UI test suite for validating navigation flows and transitions
/// Requirements addressed:
/// - Core Features (1.2): User authentication and profile management, Location-based furniture discovery
/// - Device Support (3.1.1): iOS 14+ device compatibility and tablet optimization
class NavigationUITests: XCTestCase {
    
    // MARK: - Properties
    
    private var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Initialize app instance
        app = XCUIApplication()
        
        // Configure test environment
        app.launchArguments = ["UI_TESTING"]
        app.launchEnvironment = [
            "ANIMATION_SPEED": "0.1", // Speed up animations for testing
            "NETWORK_ENVIRONMENT": "TEST",
            "SKIP_ONBOARDING": "true"
        ]
        
        // Launch app
        app.launch()
    }
    
    override func tearDown() {
        // Clean up test environment
        app.terminate()
        app = nil
        
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Tests navigation between main tab bar items with Material Design 3 transitions
    func testTabBarNavigation() throws {
        // Verify HomeView is selected by default
        XCTAssertTrue(app.tabBars.buttons["Home"].isSelected)
        
        // Navigate to Map tab
        app.tabBars.buttons["Map"].tap()
        XCTAssertTrue(app.tabBars.buttons["Map"].isSelected)
        
        // Verify map screen elements
        let mapView = app.otherElements["MapView"]
        XCTAssertTrue(mapView.waitForExistence(timeout: 5))
        XCTAssertTrue(app.sliders["Search Radius"].exists)
        
        // Navigate to Camera tab
        app.tabBars.buttons["Camera"].tap()
        XCTAssertTrue(app.tabBars.buttons["Camera"].isSelected)
        
        // Verify camera access alert
        let cameraAlert = app.alerts["Camera Access"]
        XCTAssertTrue(cameraAlert.waitForExistence(timeout: 5))
        cameraAlert.buttons["Allow"].tap()
        
        // Navigate to Messages tab
        app.tabBars.buttons["Messages"].tap()
        XCTAssertTrue(app.tabBars.buttons["Messages"].isSelected)
        XCTAssertTrue(app.navigationBars["Messages"].exists)
        
        // Navigate to Profile tab
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.tabBars.buttons["Profile"].isSelected)
        XCTAssertTrue(app.navigationBars["Profile"].exists)
        
        // Return to Home tab
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.tabBars.buttons["Home"].isSelected)
    }
    
    /// Tests navigation to and from listing details with proper transitions
    func testListingDetailNavigation() throws {
        // Verify home screen listing feed
        let listingFeed = app.scrollViews["ListingFeed"]
        XCTAssertTrue(listingFeed.waitForExistence(timeout: 5))
        
        // Tap first listing card
        let firstListing = listingFeed.otherElements["ListingCard"].firstMatch
        XCTAssertTrue(firstListing.exists)
        firstListing.tap()
        
        // Verify listing detail view
        let detailView = app.scrollViews["ListingDetailView"]
        XCTAssertTrue(detailView.waitForExistence(timeout: 5))
        
        // Test back navigation gesture
        detailView.swipeRight()
        XCTAssertTrue(listingFeed.waitForExistence(timeout: 5))
    }
    
    /// Tests navigation from map annotations to listing details
    func testMapListingNavigation() throws {
        // Navigate to map screen
        app.tabBars.buttons["Map"].tap()
        
        // Verify map view loaded
        let mapView = app.otherElements["MapView"]
        XCTAssertTrue(mapView.waitForExistence(timeout: 5))
        
        // Tap map annotation
        let annotation = mapView.otherElements["MapAnnotation"].firstMatch
        XCTAssertTrue(annotation.waitForExistence(timeout: 10))
        annotation.tap()
        
        // Verify listing card overlay
        let listingCard = app.otherElements["ListingCard"].firstMatch
        XCTAssertTrue(listingCard.waitForExistence(timeout: 5))
        
        // Tap listing card to open details
        listingCard.tap()
        
        // Verify listing detail view
        let detailView = app.scrollViews["ListingDetailView"]
        XCTAssertTrue(detailView.waitForExistence(timeout: 5))
        
        // Navigate back to map
        app.navigationBars.buttons["Map"].tap()
        XCTAssertTrue(mapView.exists)
    }
    
    /// Tests navigation to and within chat screens
    func testChatNavigation() throws {
        // Navigate to messages tab
        app.tabBars.buttons["Messages"].tap()
        
        // Verify chat list
        let chatList = app.collectionViews["ChatList"]
        XCTAssertTrue(chatList.waitForExistence(timeout: 5))
        
        // Tap first chat thread
        let firstChat = chatList.cells.firstMatch
        XCTAssertTrue(firstChat.exists)
        firstChat.tap()
        
        // Verify chat view
        let chatView = app.otherElements["ChatView"]
        XCTAssertTrue(chatView.waitForExistence(timeout: 5))
        XCTAssertTrue(app.textViews["MessageInput"].exists)
        
        // Test back navigation
        chatView.swipeRight()
        XCTAssertTrue(chatList.waitForExistence(timeout: 5))
    }
}