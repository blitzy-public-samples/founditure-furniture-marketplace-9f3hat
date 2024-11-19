// XCTest framework - Latest
import XCTest

/// Human Tasks:
/// 1. Configure test environment with proper test data
/// 2. Set up test device with biometric authentication enabled
/// 3. Verify network conditions for OAuth testing
/// 4. Configure proper test coverage reporting
/// 5. Set up accessibility testing tools

/// AuthenticationUITests: UI test suite for authentication flows
/// Requirements addressed:
/// - Authentication Methods (5.1.1): Verify email/password and biometric authentication
/// - Security Controls (5.3.2): Validate input validation and error handling
/// - Accessibility (3.1.1): Verify WCAG 2.1 AA compliance
class AuthenticationUITests: XCTestCase {
    // MARK: - Properties
    
    private var app: XCUIApplication!
    private let validEmail = "test@founditure.com"
    private let validPassword = "Test@123456"
    private let validDisplayName = "Test User"
    private let testTimeout: TimeInterval = 10.0
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        // Initialize app instance
        app = XCUIApplication()
        
        // Configure test environment
        app.launchArguments += ["UI_TESTING"]
        app.launchArguments += ["RESET_STATE"]
        
        // Configure accessibility testing
        app.launchArguments += ["ENABLE_TESTING_ACCESSIBILITY_LABEL"]
        
        // Launch app
        app.launch()
    }
    
    override func tearDownWithError() throws {
        // Reset app state
        app.terminate()
        app = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - Test Cases
    
    /// Tests successful login flow with valid credentials
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Verify email/password authentication
    func testLoginSuccess() throws {
        // Enter valid credentials
        let emailTextField = app.textFields["Email"]
        XCTAssertTrue(emailTextField.waitForExistence(timeout: testTimeout))
        emailTextField.tap()
        emailTextField.typeText(validEmail)
        
        let passwordSecureField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordSecureField.waitForExistence(timeout: testTimeout))
        passwordSecureField.tap()
        passwordSecureField.typeText(validPassword)
        
        // Submit login form
        let loginButton = app.buttons["Log In"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: testTimeout))
        loginButton.tap()
        
        // Verify successful login
        let homeScreen = app.otherElements["HomeScreen"]
        XCTAssertTrue(homeScreen.waitForExistence(timeout: testTimeout))
    }
    
    /// Tests login failure scenarios and error handling
    /// Requirements addressed:
    /// - Security Controls (5.3.2): Validate error handling
    func testLoginFailure() throws {
        // Test invalid email format
        let emailTextField = app.textFields["Email"]
        XCTAssertTrue(emailTextField.waitForExistence(timeout: testTimeout))
        emailTextField.tap()
        emailTextField.typeText("invalid-email")
        
        // Test invalid password
        let passwordSecureField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordSecureField.waitForExistence(timeout: testTimeout))
        passwordSecureField.tap()
        passwordSecureField.typeText("short")
        
        // Submit form
        let loginButton = app.buttons["Log In"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: testTimeout))
        loginButton.tap()
        
        // Verify error messages
        let errorMessage = app.staticTexts["Error: Invalid email or password"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: testTimeout))
        XCTAssertTrue(errorMessage.isHittable)
        
        // Verify staying on login screen
        XCTAssertTrue(app.navigationBars["Login"].exists)
    }
    
    /// Tests successful user registration flow
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Verify registration process
    func testRegistrationSuccess() throws {
        // Navigate to registration
        let signUpButton = app.buttons["Sign Up"]
        XCTAssertTrue(signUpButton.waitForExistence(timeout: testTimeout))
        signUpButton.tap()
        
        // Fill registration form
        let emailTextField = app.textFields["Email"]
        XCTAssertTrue(emailTextField.waitForExistence(timeout: testTimeout))
        emailTextField.tap()
        emailTextField.typeText(validEmail)
        
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: testTimeout))
        passwordField.tap()
        passwordField.typeText(validPassword)
        
        let confirmPasswordField = app.secureTextFields["Confirm Password"]
        XCTAssertTrue(confirmPasswordField.waitForExistence(timeout: testTimeout))
        confirmPasswordField.tap()
        confirmPasswordField.typeText(validPassword)
        
        let displayNameField = app.textFields["Display Name"]
        XCTAssertTrue(displayNameField.waitForExistence(timeout: testTimeout))
        displayNameField.tap()
        displayNameField.typeText(validDisplayName)
        
        // Submit registration
        let registerButton = app.buttons["Register"]
        XCTAssertTrue(registerButton.waitForExistence(timeout: testTimeout))
        registerButton.tap()
        
        // Verify successful registration
        let homeScreen = app.otherElements["HomeScreen"]
        XCTAssertTrue(homeScreen.waitForExistence(timeout: testTimeout))
    }
    
    /// Tests registration form validation and error states
    /// Requirements addressed:
    /// - Security Controls (5.3.2): Validate input validation
    func testRegistrationValidation() throws {
        // Navigate to registration
        let signUpButton = app.buttons["Sign Up"]
        XCTAssertTrue(signUpButton.waitForExistence(timeout: testTimeout))
        signUpButton.tap()
        
        // Test empty form submission
        let registerButton = app.buttons["Register"]
        XCTAssertTrue(registerButton.waitForExistence(timeout: testTimeout))
        registerButton.tap()
        
        // Verify required field errors
        let emailError = app.staticTexts["Error: Email is required"]
        XCTAssertTrue(emailError.waitForExistence(timeout: testTimeout))
        
        // Test password mismatch
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText(validPassword)
        
        let confirmPasswordField = app.secureTextFields["Confirm Password"]
        confirmPasswordField.tap()
        confirmPasswordField.typeText("different")
        
        registerButton.tap()
        
        let passwordError = app.staticTexts["Error: Passwords do not match"]
        XCTAssertTrue(passwordError.waitForExistence(timeout: testTimeout))
    }
    
    /// Tests biometric authentication flow when available
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Verify biometric authentication
    func testBiometricLogin() throws {
        // Enable biometric simulation
        app.launchArguments += ["ENABLE_BIOMETRIC_SIMULATION"]
        app.terminate()
        app.launch()
        
        // Verify biometric button presence
        let biometricButton = app.buttons["Login with Face ID"]
        XCTAssertTrue(biometricButton.waitForExistence(timeout: testTimeout))
        
        // Attempt biometric login
        biometricButton.tap()
        
        // Verify biometric prompt
        let biometricPrompt = app.alerts["Face ID"].firstMatch
        XCTAssertTrue(biometricPrompt.waitForExistence(timeout: testTimeout))
        
        // Simulate successful authentication
        biometricPrompt.buttons["Authenticate"].tap()
        
        // Verify successful login
        let homeScreen = app.otherElements["HomeScreen"]
        XCTAssertTrue(homeScreen.waitForExistence(timeout: testTimeout))
    }
    
    /// Tests WCAG 2.1 AA compliance and accessibility features
    /// Requirements addressed:
    /// - Accessibility (3.1.1): Verify WCAG compliance
    func testAccessibility() throws {
        // Enable VoiceOver simulation
        app.launchArguments += ["ENABLE_VOICEOVER_SIMULATION"]
        app.terminate()
        app.launch()
        
        // Test login form accessibility
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.isAccessibilityElement)
        XCTAssertEqual(emailField.accessibilityLabel, "Email")
        XCTAssertNotNil(emailField.accessibilityHint)
        
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.isAccessibilityElement)
        XCTAssertEqual(passwordField.accessibilityLabel, "Password")
        XCTAssertNotNil(passwordField.accessibilityHint)
        
        // Test minimum touch targets
        let loginButton = app.buttons["Log In"]
        let buttonFrame = loginButton.frame
        XCTAssertGreaterThanOrEqual(buttonFrame.width, 44)
        XCTAssertGreaterThanOrEqual(buttonFrame.height, 44)
        
        // Test dynamic type support
        app.launchArguments += ["ENABLE_DYNAMIC_TYPE_TESTING"]
        app.terminate()
        app.launch()
        
        // Verify text scaling
        XCTAssertTrue(emailField.waitForExistence(timeout: testTimeout))
        XCTAssertTrue(passwordField.waitForExistence(timeout: testTimeout))
    }
}