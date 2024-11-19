// XCTest framework - Latest
import XCTest

/// Human Tasks:
/// 1. Configure test data for different furniture categories and conditions
/// 2. Set up test environment with proper network mocking
/// 3. Verify accessibility labels with VoiceOver team
/// 4. Test image recognition with various furniture photos
/// 5. Validate form validation error messages with UX team

/// UI test suite for testing the furniture listing creation flow
/// Requirements addressed:
/// - AI-powered furniture recognition (1.2): Tests furniture recognition and categorization
/// - Location-based discovery (1.2): Tests location integration
/// - Core Features (1.3): Tests listing creation and validation
final class ListingCreationUITests: XCTestCase {
    // MARK: - Properties
    
    private var app: XCUIApplication!
    private let timeout: TimeInterval = 10
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Test Cases
    
    /// Tests the complete listing creation flow
    /// Requirements addressed:
    /// - AI-powered furniture recognition (1.2): Validates AI recognition results
    /// - Core Features (1.3): Tests form validation and submission
    func testCreateListingFlow() throws {
        // Navigate to create listing screen
        app.tabBars.buttons["Create"].tap()
        
        // Test photo capture section
        let addPhotoButton = app.buttons["Add Photo"]
        XCTAssertTrue(addPhotoButton.waitForExistence(timeout: timeout))
        addPhotoButton.tap()
        
        // Select photo from library
        app.sheets.buttons["Choose from Library"].tap()
        
        // Wait for AI recognition results
        let aiRecognitionLabel = app.staticTexts.matching(identifier: "AI recognized this as:").firstMatch
        XCTAssertTrue(aiRecognitionLabel.waitForExistence(timeout: timeout))
        
        // Fill in listing details
        let titleField = app.textFields["Title"]
        titleField.tap()
        titleField.typeText("Modern Sofa")
        
        let descriptionField = app.textFields["Description"]
        descriptionField.tap()
        descriptionField.typeText("Comfortable modern sofa in excellent condition")
        
        // Select category
        app.buttons["Category"].tap()
        app.buttons["Sofa"].tap()
        
        // Select condition
        app.buttons["Condition"].tap()
        app.buttons["Excellent"].tap()
        
        // Submit listing
        let createButton = app.buttons["Create Listing"]
        XCTAssertTrue(createButton.isEnabled)
        createButton.tap()
        
        // Verify success state
        XCTAssertTrue(app.navigationBars["My Listings"].waitForExistence(timeout: timeout))
    }
    
    /// Tests the photo capture and AI recognition functionality
    /// Requirements addressed:
    /// - AI-powered furniture recognition (1.2): Tests photo capture and recognition
    func testPhotoCapture() throws {
        app.tabBars.buttons["Create"].tap()
        
        // Test camera access
        let addPhotoButton = app.buttons["Add Photo"]
        addPhotoButton.tap()
        app.sheets.buttons["Take Photo"].tap()
        
        // Verify camera UI elements
        XCTAssertTrue(app.buttons["Take Picture"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["Switch Camera"].exists)
        
        // Test photo preview
        app.buttons["Take Picture"].tap()
        XCTAssertTrue(app.buttons["Use Photo"].waitForExistence(timeout: timeout))
        app.buttons["Use Photo"].tap()
        
        // Verify AI recognition results
        let aiRecognitionLabel = app.staticTexts.matching(identifier: "AI recognized this as:").firstMatch
        XCTAssertTrue(aiRecognitionLabel.waitForExistence(timeout: timeout))
    }
    
    /// Tests the listing form validation
    /// Requirements addressed:
    /// - Core Features (1.3): Tests input validation and error handling
    func testFormValidation() throws {
        app.tabBars.buttons["Create"].tap()
        
        // Test empty field validation
        let createButton = app.buttons["Create Listing"]
        XCTAssertFalse(createButton.isEnabled)
        
        // Test title field validation
        let titleField = app.textFields["Title"]
        titleField.tap()
        titleField.typeText("a")
        titleField.typeText(String(repeating: "a", count: 100))
        
        // Test description field validation
        let descriptionField = app.textFields["Description"]
        descriptionField.tap()
        descriptionField.typeText("Test description")
        
        // Verify error messages
        XCTAssertTrue(app.staticTexts["Please fill in all required fields"].exists)
        
        // Test category selection validation
        app.buttons["Category"].tap()
        app.buttons["Chair"].tap()
        
        // Test condition selection validation
        app.buttons["Condition"].tap()
        app.buttons["Good"].tap()
        
        // Verify form completion
        XCTAssertTrue(createButton.isEnabled)
    }
    
    /// Tests the location selection process
    /// Requirements addressed:
    /// - Location-based discovery (1.2): Tests location functionality
    func testLocationSelection() throws {
        app.tabBars.buttons["Create"].tap()
        
        // Test location permission handling
        let locationButton = app.buttons["Set Location"]
        XCTAssertTrue(locationButton.waitForExistence(timeout: timeout))
        locationButton.tap()
        
        // Verify location permission alert
        let allowButton = app.alerts.buttons["Allow While Using App"]
        if allowButton.exists {
            allowButton.tap()
        }
        
        // Test manual location selection
        app.buttons["Choose Location"].tap()
        
        // Test map interaction
        let mapView = app.maps.firstMatch
        XCTAssertTrue(mapView.exists)
        
        // Test location search
        let searchField = app.searchFields["Search location"]
        searchField.tap()
        searchField.typeText("New York")
        
        // Select location from search results
        app.tables.cells.firstMatch.tap()
        
        // Confirm location selection
        app.buttons["Confirm Location"].tap()
        
        // Verify location was set
        XCTAssertTrue(app.staticTexts.matching(identifier: "Location set").firstMatch.exists)
    }
    
    // MARK: - Helper Methods
    
    private func waitForElementToAppear(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}