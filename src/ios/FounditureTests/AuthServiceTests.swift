// XCTest framework - Latest
import XCTest
// Combine framework - Latest
import Combine
@testable import Founditure

/// Human Tasks:
/// 1. Configure test environment with proper keychain access
/// 2. Set up mock biometric authentication for simulator testing
/// 3. Verify test coverage meets security requirements
/// 4. Configure proper test data isolation

/// AuthServiceTests: Test suite for AuthService functionality
/// Requirements addressed:
/// - Authentication Methods (5.1.1): Verify email/password and social authentication with JWT tokens
/// - Security Controls (5.3.2): Test secure authentication and session management
/// - Data Security (5.2.1): Validate secure storage of tokens and credentials
final class AuthServiceTests: XCTestCase {
    // MARK: - Properties
    
    private var sut: AuthService!
    private var mockAPIClient: MockAPIClient!
    private var mockKeychainManager: MockKeychainManager!
    private var cancellables: Set<AnyCancellable>!
    private var testProfile: UserProfile!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize mock dependencies
        mockAPIClient = MockAPIClient()
        mockKeychainManager = MockKeychainManager()
        
        // Initialize system under test
        sut = AuthService(apiClient: mockAPIClient, keychainManager: mockKeychainManager)
        
        // Initialize cancellables set
        cancellables = Set<AnyCancellable>()
        
        // Setup test profile data
        testProfile = UserProfile(
            displayName: "Test User",
            avatarUrl: "https://example.com/avatar.jpg",
            bio: "Test bio",
            phoneNumber: "+1234567890",
            dateOfBirth: Date(),
            interests: ["furniture", "design"]
        )
    }
    
    override func tearDown() async throws {
        // Clear all subscriptions
        cancellables.removeAll()
        
        // Reset mock states
        mockAPIClient.reset()
        try await mockKeychainManager.clear().get()
        
        // Clear references
        sut = nil
        mockAPIClient = nil
        mockKeychainManager = nil
        testProfile = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Login Tests
    
    /// Tests successful login flow with valid credentials
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Verify email/password authentication
    func testLoginSuccess() async throws {
        // Prepare test data
        let email = "test@example.com"
        let password = "SecurePass123!"
        let testUser = User(
            id: UUID(),
            email: email,
            role: .basicUser,
            provider: .email,
            profile: testProfile
        )
        testUser.accessToken = "valid_access_token"
        testUser.accessTokenExpiresAt = Date().addingTimeInterval(3600)
        
        // Configure mock response
        let mockResponse = AuthResponse(
            user: testUser,
            accessToken: testUser.accessToken!,
            refreshToken: "valid_refresh_token"
        )
        mockAPIClient.mockResponse(mockResponse, for: "/auth/login")
        
        // Setup auth state expectation
        let authStateExpectation = expectation(description: "Auth state updated")
        var receivedUser: User?
        
        sut.authStatePublisher
            .dropFirst()
            .sink { user in
                receivedUser = user
                authStateExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Perform login
        let loggedInUser = try await sut.login(email: email, password: password)
        
        // Verify user is authenticated
        XCTAssertEqual(loggedInUser.id, testUser.id)
        XCTAssertEqual(loggedInUser.email, email)
        XCTAssertTrue(loggedInUser.isTokenValid())
        
        // Verify token storage
        let storedToken = try await mockKeychainManager.retrieve(key: "com.founditure.authToken").get()
        XCTAssertEqual(String(data: storedToken, encoding: .utf8), testUser.accessToken)
        
        // Wait for auth state update
        await fulfillment(of: [authStateExpectation], timeout: 1.0)
        XCTAssertEqual(receivedUser?.id, testUser.id)
    }
    
    /// Tests login failure scenarios
    /// Requirements addressed:
    /// - Security Controls (5.3.2): Verify proper error handling
    func testLoginFailure() async throws {
        // Prepare test data
        let email = "invalid@example.com"
        let password = "wrong_password"
        
        // Configure mock error response
        mockAPIClient.mockError(APIError.invalidResponse(401), for: "/auth/login")
        
        // Verify login throws error
        do {
            _ = try await sut.login(email: email, password: password)
            XCTFail("Login should fail with invalid credentials")
        } catch {
            XCTAssertEqual(error as? AuthError, .invalidCredentials)
        }
        
        // Verify no token storage
        let tokenResult = await mockKeychainManager.retrieve(key: "com.founditure.authToken")
        if case .success = tokenResult {
            XCTFail("No token should be stored for failed login")
        }
        
        // Verify auth state remains nil
        let authStateExpectation = expectation(description: "Auth state remains nil")
        sut.authStatePublisher
            .sink { user in
                XCTAssertNil(user)
                authStateExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [authStateExpectation], timeout: 1.0)
    }
    
    // MARK: - Registration Tests
    
    /// Tests successful user registration
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Verify user registration flow
    func testRegistrationSuccess() async throws {
        // Prepare test data
        let email = "newuser@example.com"
        let password = "SecurePass123!"
        let testUser = User(
            id: UUID(),
            email: email,
            role: .basicUser,
            provider: .email,
            profile: testProfile
        )
        testUser.accessToken = "new_access_token"
        testUser.accessTokenExpiresAt = Date().addingTimeInterval(3600)
        
        // Configure mock response
        let mockResponse = AuthResponse(
            user: testUser,
            accessToken: testUser.accessToken!,
            refreshToken: "new_refresh_token"
        )
        mockAPIClient.mockResponse(mockResponse, for: "/auth/register")
        
        // Setup auth state expectation
        let authStateExpectation = expectation(description: "Auth state updated")
        var receivedUser: User?
        
        sut.authStatePublisher
            .dropFirst()
            .sink { user in
                receivedUser = user
                authStateExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Perform registration
        let registeredUser = try await sut.register(
            email: email,
            password: password,
            profile: testProfile
        )
        
        // Verify registration success
        XCTAssertEqual(registeredUser.id, testUser.id)
        XCTAssertEqual(registeredUser.email, email)
        XCTAssertEqual(registeredUser.profile.displayName, testProfile.displayName)
        
        // Verify token storage
        let storedToken = try await mockKeychainManager.retrieve(key: "com.founditure.authToken").get()
        XCTAssertEqual(String(data: storedToken, encoding: .utf8), testUser.accessToken)
        
        // Wait for auth state update
        await fulfillment(of: [authStateExpectation], timeout: 1.0)
        XCTAssertEqual(receivedUser?.id, testUser.id)
    }
    
    // MARK: - Token Refresh Tests
    
    /// Tests token refresh mechanism
    /// Requirements addressed:
    /// - Security Controls (5.3.2): Verify token refresh functionality
    func testTokenRefresh() async throws {
        // Configure initial authenticated state
        let testUser = User(
            id: UUID(),
            email: "test@example.com",
            role: .basicUser,
            provider: .email,
            profile: testProfile
        )
        testUser.accessToken = "expired_token"
        testUser.accessTokenExpiresAt = Date().addingTimeInterval(-60) // Expired
        
        // Store expired token
        try await mockKeychainManager.save(
            data: testUser.accessToken!.data(using: .utf8)!,
            key: "com.founditure.authToken"
        ).get()
        
        // Configure mock refresh response
        let newToken = "refreshed_token"
        let mockResponse = AuthResponse(
            user: testUser,
            accessToken: newToken,
            refreshToken: "new_refresh_token"
        )
        mockAPIClient.mockResponse(mockResponse, for: "/auth/refresh")
        
        // Perform token refresh
        try await sut.refreshToken()
        
        // Verify new token storage
        let storedToken = try await mockKeychainManager.retrieve(key: "com.founditure.authToken").get()
        XCTAssertEqual(String(data: storedToken, encoding: .utf8), newToken)
    }
    
    // MARK: - Biometric Authentication Tests
    
    /// Tests biometric authentication flow
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Verify biometric authentication
    func testBiometricAuthentication() async throws {
        // Configure mock biometric success
        let testUser = User(
            id: UUID(),
            email: "test@example.com",
            role: .basicUser,
            provider: .email,
            profile: testProfile
        )
        testUser.accessToken = "valid_token"
        testUser.accessTokenExpiresAt = Date().addingTimeInterval(3600)
        
        // Store valid token for session restoration
        try await mockKeychainManager.save(
            data: testUser.accessToken!.data(using: .utf8)!,
            key: "com.founditure.authToken"
        ).get()
        
        // Perform biometric authentication
        let success = try await sut.authenticateWithBiometrics()
        XCTAssertTrue(success)
        
        // Verify session restoration
        let authStateExpectation = expectation(description: "Auth state updated")
        sut.authStatePublisher
            .dropFirst()
            .sink { user in
                XCTAssertNotNil(user)
                authStateExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [authStateExpectation], timeout: 1.0)
    }
    
    // MARK: - Logout Tests
    
    /// Tests logout functionality
    /// Requirements addressed:
    /// - Security Controls (5.3.2): Verify secure session termination
    func testLogout() async throws {
        // Configure authenticated state
        let testUser = User(
            id: UUID(),
            email: "test@example.com",
            role: .basicUser,
            provider: .email,
            profile: testProfile
        )
        testUser.accessToken = "valid_token"
        testUser.accessTokenExpiresAt = Date().addingTimeInterval(3600)
        
        // Store token
        try await mockKeychainManager.save(
            data: testUser.accessToken!.data(using: .utf8)!,
            key: "com.founditure.authToken"
        ).get()
        
        // Configure mock logout response
        mockAPIClient.mockResponse(EmptyResponse(), for: "/auth/logout")
        
        // Setup auth state expectation
        let authStateExpectation = expectation(description: "Auth state cleared")
        sut.authStatePublisher
            .dropFirst()
            .sink { user in
                XCTAssertNil(user)
                authStateExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Perform logout
        try await sut.logout()
        
        // Verify token removal
        let tokenResult = await mockKeychainManager.retrieve(key: "com.founditure.authToken")
        if case .success = tokenResult {
            XCTFail("Token should be removed after logout")
        }
        
        // Wait for auth state update
        await fulfillment(of: [authStateExpectation], timeout: 1.0)
    }
}

// MARK: - Mock Types

private class MockAPIClient: APIClient {
    private var responses: [String: Any] = [:]
    private var errors: [String: Error] = [:]
    
    func mockResponse<T: Decodable>(_ response: T, for path: String) {
        responses[path] = response
    }
    
    func mockError(_ error: Error, for path: String) {
        errors[path] = error
    }
    
    func reset() {
        responses.removeAll()
        errors.removeAll()
    }
    
    override func request<T: APIEndpoint>(_ endpoint: T) async throws -> T.Response {
        let path = endpoint.path
        
        if let error = errors[path] {
            throw error
        }
        
        guard let response = responses[path] as? T.Response else {
            throw APIError.invalidResponse(404)
        }
        
        return response
    }
}

private class MockKeychainManager: KeychainManager {
    private var storage: [String: Data] = [:]
    
    override func save(data: Data, key: String) -> Result<Void, KeychainError> {
        storage[key] = data
        return .success(())
    }
    
    override func retrieve(key: String) -> Result<Data, KeychainError> {
        guard let data = storage[key] else {
            return .failure(.itemNotFound)
        }
        return .success(data)
    }
    
    override func delete(key: String) -> Result<Void, KeychainError> {
        storage.removeValue(forKey: key)
        return .success(())
    }
    
    override func clear() -> Result<Void, KeychainError> {
        storage.removeAll()
        return .success(())
    }
}