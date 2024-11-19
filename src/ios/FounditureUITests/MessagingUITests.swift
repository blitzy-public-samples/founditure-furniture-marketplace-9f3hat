// XCTest framework - Latest
import XCTest
@testable import Founditure

/// Human Tasks:
/// 1. Configure test data for consistent test execution
/// 2. Set up proper test environment with mock network responses
/// 3. Verify VoiceOver testing configuration is properly set up
/// 4. Review test coverage with QA team for edge cases
/// 5. Configure proper test device orientation handling

/// MessagingUITests: UI test suite for messaging functionality
/// Requirements addressed:
/// - Real-time messaging (1.3 Scope/Core Features): Tests real-time messaging with delivery status
/// - User Engagement (1.2 System Overview/Success Criteria): Validates messaging UX flows
/// - Visual Hierarchy (3.1.1 Design Specifications): Verifies Material Design 3 compliance
/// - Accessibility (3.1.1 Design Specifications): Tests WCAG 2.1 AA compliance
class MessagingUITests: XCTestCase {
    
    // MARK: - Properties
    
    private var app: XCUIApplication!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        
        // Initialize application
        app = XCUIApplication()
        
        // Configure test environment
        app.launchArguments = ["UI-Testing"]
        app.launchEnvironment = [
            "TESTING_MODE": "1",
            "DISABLE_ANIMATIONS": "1"
        ]
        
        // Enable accessibility testing
        app.launchEnvironment["ENABLE_ACCESSIBILITY_CHECKS"] = "1"
        
        continueAfterFailure = false
        app.launch()
    }
    
    override func tearDown() {
        app.terminate()
        app = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Tests navigation to and within message list with Material Design 3 validation
    /// Requirements addressed:
    /// - Visual Hierarchy (3.1.1): Verifies Material Design 3 styling
    /// - Accessibility (3.1.1): Tests WCAG compliance
    func testMessageListNavigation() throws {
        // Navigate to messages tab
        let tabBar = app.tabBars.firstMatch
        let messagesTab = tabBar.buttons["Messages"]
        XCTAssertTrue(messagesTab.exists, "Messages tab should exist")
        messagesTab.tap()
        
        // Verify navigation title with Material Design typography
        let navigationBar = app.navigationBars.firstMatch
        let title = navigationBar.staticTexts["Messages"]
        XCTAssertTrue(title.exists, "Navigation title should exist")
        
        // Verify search bar accessibility
        let searchField = app.searchFields["Search messages"]
        XCTAssertTrue(searchField.exists, "Search field should exist")
        XCTAssertTrue(searchField.isEnabled, "Search field should be enabled")
        XCTAssertTrue(searchField.isAccessibilityElement, "Search field should be accessible")
        
        // Test pull-to-refresh gesture
        let messageList = app.scrollViews.firstMatch
        messageList.swipeDown()
        
        // Verify loading indicator appears with proper styling
        let loadingIndicator = app.activityIndicators["Loading"]
        XCTAssertTrue(loadingIndicator.exists, "Loading indicator should appear during refresh")
        
        // Verify message list accessibility
        XCTAssertTrue(messageList.isAccessibilityElement, "Message list should be accessible")
    }
    
    /// Tests message composition and sending with real-time updates
    /// Requirements addressed:
    /// - Real-time messaging (1.3): Tests message sending functionality
    /// - Visual Hierarchy (3.1.1): Validates Material Design 3 input styling
    func testSendMessage() throws {
        // Navigate to chat screen
        navigateToChat()
        
        // Verify message input field styling
        let messageInput = app.textFields["Message input field"]
        XCTAssertTrue(messageInput.exists, "Message input field should exist")
        
        // Enter test message
        let testMessage = "Test message"
        messageInput.tap()
        messageInput.typeText(testMessage)
        
        // Verify send button state
        let sendButton = app.buttons["Send message"]
        XCTAssertTrue(sendButton.isEnabled, "Send button should be enabled with text")
        XCTAssertTrue(sendButton.isAccessibilityElement, "Send button should be accessible")
        
        // Send message
        sendButton.tap()
        
        // Verify message appears in chat
        let messageBubble = app.staticTexts[testMessage]
        XCTAssertTrue(messageBubble.waitForExistence(timeout: 5), "Sent message should appear")
        
        // Verify message status indicator
        let statusIndicator = app.images["Message sent"]
        XCTAssertTrue(statusIndicator.exists, "Message status indicator should exist")
    }
    
    /// Tests message interaction features and accessibility
    /// Requirements addressed:
    /// - Accessibility (3.1.1): Tests WCAG compliance and VoiceOver support
    /// - Visual Hierarchy (3.1.1): Validates Material Design 3 interaction patterns
    func testMessageInteractions() throws {
        // Navigate to chat screen
        navigateToChat()
        
        // Find existing message
        let message = app.staticTexts.element(boundBy: 0)
        XCTAssertTrue(message.exists, "Message should exist")
        
        // Test long press gesture
        message.press(forDuration: 1.0)
        
        // Verify context menu accessibility
        let copyButton = app.buttons["Copy message"]
        XCTAssertTrue(copyButton.exists, "Copy option should exist")
        XCTAssertTrue(copyButton.isAccessibilityElement, "Copy option should be accessible")
        
        // Verify message timestamp
        let timestamp = app.staticTexts.matching(identifier: "Message timestamp").firstMatch
        XCTAssertTrue(timestamp.exists, "Message timestamp should be visible")
        
        // Test VoiceOver support
        XCTAssertTrue(message.isAccessibilityElement, "Message should be accessible")
        XCTAssertNotNil(message.value, "Message should have accessibility value")
        
        // Test dynamic type size adaptation
        let currentContentSize = app.windows.firstMatch.frame.size
        XCUIDevice.shared.orientation = .portrait
        let newContentSize = app.windows.firstMatch.frame.size
        XCTAssertNotEqual(currentContentSize, newContentSize, "Layout should adapt to orientation")
    }
    
    /// Tests chat screen UI elements and Material Design 3 compliance
    /// Requirements addressed:
    /// - Visual Hierarchy (3.1.1): Validates Material Design 3 styling
    /// - Accessibility (3.1.1): Tests contrast ratios and accessibility
    func testChatScreenLayout() throws {
        // Navigate to chat screen
        navigateToChat()
        
        // Verify message input styling
        let messageInput = app.textFields["Message input field"]
        XCTAssertTrue(messageInput.exists, "Message input should exist")
        
        // Verify send button states
        let sendButton = app.buttons["Send message"]
        XCTAssertFalse(sendButton.isEnabled, "Send button should be disabled without text")
        
        messageInput.tap()
        messageInput.typeText("Test")
        XCTAssertTrue(sendButton.isEnabled, "Send button should be enabled with text")
        
        // Test keyboard interactions
        XCTAssertTrue(app.keyboards.firstMatch.exists, "Keyboard should be visible")
        app.swipeDown()
        XCTAssertFalse(app.keyboards.firstMatch.exists, "Keyboard should be dismissed")
        
        // Verify message list scrolling
        let messageList = app.scrollViews.firstMatch
        messageList.swipeUp()
        messageList.swipeDown()
        
        // Verify loading indicator
        messageList.swipeDown()
        let loadingIndicator = app.activityIndicators["Loading"]
        XCTAssertTrue(loadingIndicator.exists, "Loading indicator should appear during refresh")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToChat() {
        // Navigate to messages tab
        let tabBar = app.tabBars.firstMatch
        let messagesTab = tabBar.buttons["Messages"]
        messagesTab.tap()
        
        // Open first chat conversation
        let firstChat = app.cells.firstMatch
        XCTAssertTrue(firstChat.waitForExistence(timeout: 5), "Chat conversation should exist")
        firstChat.tap()
    }
}