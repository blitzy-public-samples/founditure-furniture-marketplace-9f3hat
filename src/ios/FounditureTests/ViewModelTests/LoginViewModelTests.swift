// XCTest framework - Latest
import XCTest
// Combine framework - Latest
import Combine
@testable import Founditure

/// Human Tasks:
/// 1. Configure test environment with proper mock data
/// 2. Set up test coverage reporting
/// 3. Verify test suite integration with CI/CD pipeline
/// 4. Configure proper test logging and reporting

/// LoginViewModelTests: Test suite for LoginViewModel authentication and state management
/// Requirements addressed:
/// - Authentication Methods (5.1.1): Verify email/password and biometric authentication implementation
/// - Security Controls (5.3.2): Test input validation and authentication flow security
final class LoginViewModelTests: XCTestCase {
    // MARK: - Properties
    
    private var sut: LoginViewModel!
    private var mockAuthService: MockAuthService!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup and Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        mockAuthService = MockAuthService()
        sut = LoginViewModel(authService: mockAuthService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        cancellables = nil
        sut = nil
        mockAuthService = nil
        try await super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Tests successful login flow with valid credentials
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Verify successful email/password authentication
    func testLoginSuccess() async throws {
        // Given
        let expectation = expectation(description: "Login success")
        var states: [LoginState] = []
        
        sut.email = "test@example.com"
        sut.password = "password123"
        
        let mockUser = User(
            id: UUID(),
            email: "test@example.com",
            role: .basicUser,
            provider: .email,
            profile: UserProfile(displayName: "Test User")
        )
        mockUser.accessToken = "valid_token"
        mockUser.accessTokenExpiresAt = Date().addingTimeInterval(3600)
        
        mockAuthService.loginResult = .success(mockUser)
        
        // When
        sut.$state
            .sink { state in
                states.append(state)
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await sut.login()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(states.count, 3)
        XCTAssertEqual(states[0], .idle)
        XCTAssertEqual(states[1], .loading)
        
        if case .success(let user) = states[2] {
            XCTAssertEqual(user.email, "test@example.com")
            XCTAssertTrue(user.isTokenValid())
        } else {
            XCTFail("Expected success state with valid user")
        }
    }
    
    /// Tests login failure scenarios with invalid credentials
    /// Requirements addressed:
    /// - Security Controls (5.3.2): Verify proper error handling for invalid credentials
    func testLoginFailure() async throws {
        // Given
        let expectation = expectation(description: "Login failure")
        var states: [LoginState] = []
        
        sut.email = "invalid@example.com"
        sut.password = "wrongpassword"
        
        mockAuthService.loginResult = .failure(AuthError.invalidCredentials)
        
        // When
        sut.$state
            .sink { state in
                states.append(state)
                if case .error = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await sut.login()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(states.count, 3)
        XCTAssertEqual(states[0], .idle)
        XCTAssertEqual(states[1], .loading)
        
        if case .error(let error) = states[2] {
            XCTAssertEqual(error, .invalidCredentials)
        } else {
            XCTFail("Expected error state with invalid credentials")
        }
    }
    
    /// Tests successful biometric authentication flow
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Verify biometric authentication implementation
    func testBiometricLoginSuccess() async throws {
        // Given
        let expectation = expectation(description: "Biometric login success")
        var states: [LoginState] = []
        
        sut.isBiometricsAvailable = true
        
        let mockUser = User(
            id: UUID(),
            email: "test@example.com",
            role: .basicUser,
            provider: .email,
            profile: UserProfile(displayName: "Test User")
        )
        mockUser.accessToken = "valid_token"
        mockUser.accessTokenExpiresAt = Date().addingTimeInterval(3600)
        
        mockAuthService.biometricResult = .success(true)
        mockAuthService.loginResult = .success(mockUser)
        
        // When
        sut.$state
            .sink { state in
                states.append(state)
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await sut.loginWithBiometrics()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(states.count, 3)
        XCTAssertEqual(states[0], .idle)
        XCTAssertEqual(states[1], .loading)
        
        if case .success(let user) = states[2] {
            XCTAssertTrue(user.isTokenValid())
        } else {
            XCTFail("Expected success state with valid user")
        }
    }
    
    /// Tests input validation logic for credentials
    /// Requirements addressed:
    /// - Security Controls (5.3.2): Verify input validation implementation
    func testInputValidation() async throws {
        // Test empty credentials
        sut.email = ""
        sut.password = ""
        await sut.login()
        
        if case .error(let error) = sut.state {
            XCTAssertEqual(error, .invalidCredentials)
        } else {
            XCTFail("Expected error state for empty credentials")
        }
        
        // Test invalid email format
        sut.email = "invalidemail"
        sut.password = "password123"
        await sut.login()
        
        if case .error(let error) = sut.state {
            XCTAssertEqual(error, .invalidCredentials)
        } else {
            XCTFail("Expected error state for invalid email format")
        }
        
        // Test password length requirement
        sut.email = "test@example.com"
        sut.password = "short"
        await sut.login()
        
        if case .error(let error) = sut.state {
            XCTAssertEqual(error, .invalidCredentials)
        } else {
            XCTFail("Expected error state for short password")
        }
    }
}

// MARK: - Mock Auth Service

/// Mock implementation of AuthService for testing
final class MockAuthService: AuthService {
    var loginResult: Result<User, Error>?
    var biometricResult: Result<Bool, Error>?
    
    override func login(email: String, password: String) async throws -> User {
        guard let result = loginResult else {
            throw AuthError.networkError
        }
        return try result.get()
    }
    
    override func authenticateWithBiometrics() async throws -> Bool {
        guard let result = biometricResult else {
            throw AuthError.biometricError
        }
        return try result.get()
    }
}