// Foundation framework - Latest
import Foundation
// Combine framework - Latest
import Combine

/// Human Tasks:
/// 1. Configure proper error logging for authentication failures
/// 2. Set up analytics tracking for user events
/// 3. Implement proper token refresh monitoring
/// 4. Configure secure storage for user credentials
/// 5. Set up proper session timeout handling

/// UserService: Manages user authentication and profile operations with secure token handling
/// Requirements addressed:
/// - Authentication Methods (5.1.1): Implementation of email/password and social authentication
/// - Data Security (5.2.1): Secure handling of user credentials and tokens
/// - User Profile Management (1.2): User authentication and profile functionality
@MainActor
public final class UserService {
    // MARK: - Private Properties
    
    private let apiClient: APIClient
    private let keychainManager: KeychainManager
    private let currentUserSubject: CurrentValueSubject<User?, Never>
    private let tokenKey: String
    private let refreshTokenKey: String
    
    // MARK: - Constants
    
    private enum Constants {
        static let tokenKey = "com.founditure.auth.token"
        static let refreshTokenKey = "com.founditure.auth.refreshToken"
        static let tokenRefreshThreshold: TimeInterval = 300 // 5 minutes before expiration
    }
    
    // MARK: - Initialization
    
    /// Initializes the UserService with required dependencies
    /// - Parameters:
    ///   - apiClient: API client for network requests
    ///   - keychainManager: Keychain manager for secure storage
    public init(apiClient: APIClient, keychainManager: KeychainManager) {
        self.apiClient = apiClient
        self.keychainManager = keychainManager
        self.currentUserSubject = CurrentValueSubject<User?, Never>(nil)
        self.tokenKey = Constants.tokenKey
        self.refreshTokenKey = Constants.refreshTokenKey
        
        // Attempt to restore user session
        Task {
            await restoreUserSession()
        }
    }
    
    // MARK: - Public Methods
    
    /// Authenticates user with email and password
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Email/password authentication
    /// - Data Security (5.2.1): Secure credential handling
    public func login(email: String, password: String) async throws -> User {
        struct LoginEndpoint: APIEndpoint {
            typealias Response = AuthResponse
            let path = "/auth/login"
            let method: HTTPMethod = .post
            let headers: [String: String]? = nil
            let body: LoginRequest
            let queryItems: [URLQueryItem]? = nil
        }
        
        struct LoginRequest: Encodable {
            let email: String
            let password: String
        }
        
        struct AuthResponse: Decodable {
            let user: User
            let accessToken: String
            let refreshToken: String
        }
        
        // Create and send login request
        let endpoint = LoginEndpoint(body: LoginRequest(email: email, password: password))
        let response = try await apiClient.request(endpoint)
        
        // Store tokens securely
        try await storeTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        
        // Update user state
        let user = response.user
        currentUserSubject.send(user)
        
        return user
    }
    
    /// Registers new user with provided information
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): User registration
    /// - Data Security (5.2.1): Secure profile data handling
    public func register(email: String, password: String, profile: UserProfile) async throws -> User {
        struct RegisterEndpoint: APIEndpoint {
            typealias Response = AuthResponse
            let path = "/auth/register"
            let method: HTTPMethod = .post
            let headers: [String: String]? = nil
            let body: RegisterRequest
            let queryItems: [URLQueryItem]? = nil
        }
        
        struct RegisterRequest: Encodable {
            let email: String
            let password: String
            let profile: UserProfile
        }
        
        struct AuthResponse: Decodable {
            let user: User
            let accessToken: String
            let refreshToken: String
        }
        
        // Create and send registration request
        let endpoint = RegisterEndpoint(body: RegisterRequest(
            email: email,
            password: password,
            profile: profile
        ))
        let response = try await apiClient.request(endpoint)
        
        // Store tokens securely
        try await storeTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        
        // Update user state
        let user = response.user
        currentUserSubject.send(user)
        
        return user
    }
    
    /// Logs out current user and clears session
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Secure session termination
    /// - Data Security (5.2.1): Secure token removal
    public func logout() async throws {
        struct LogoutEndpoint: APIEndpoint {
            typealias Response = EmptyResponse
            let path = "/auth/logout"
            let method: HTTPMethod = .post
            let headers: [String: String]?
            let body: EmptyRequest? = nil
            let queryItems: [URLQueryItem]? = nil
        }
        
        struct EmptyResponse: Decodable {}
        struct EmptyRequest: Encodable {}
        
        // Get current auth token
        guard let token = try? await keychainManager.retrieve(key: tokenKey).get() else {
            throw APIError.unauthorized
        }
        
        // Send logout request
        let endpoint = LogoutEndpoint(headers: ["Authorization": "Bearer \(String(data: token, encoding: .utf8) ?? "")"])
        _ = try await apiClient.request(endpoint)
        
        // Clear tokens and user state
        try await clearTokens()
        currentUserSubject.send(nil)
    }
    
    /// Updates the current user's profile information
    /// Requirements addressed:
    /// - User Profile Management (1.2): Profile update functionality
    /// - Data Security (5.2.1): Secure profile data transmission
    public func updateUserProfile(_ newProfile: UserProfile) async throws -> User {
        guard var currentUser = currentUserSubject.value else {
            throw APIError.unauthorized
        }
        
        // Update profile through User model
        try await currentUser.updateProfile(newProfile)
        
        // Update current user state
        currentUserSubject.send(currentUser)
        
        return currentUser
    }
    
    /// Retrieves the current authenticated user
    /// Requirements addressed:
    /// - User Profile Management (1.2): User state management
    public func getCurrentUser() -> User? {
        return currentUserSubject.value
    }
    
    /// Refreshes the authentication token if expired
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Token refresh mechanism
    /// - Data Security (5.2.1): Secure token rotation
    public func refreshToken() async throws {
        struct RefreshEndpoint: APIEndpoint {
            typealias Response = TokenResponse
            let path = "/auth/refresh"
            let method: HTTPMethod = .post
            let headers: [String: String]? = nil
            let body: RefreshRequest
            let queryItems: [URLQueryItem]? = nil
        }
        
        struct RefreshRequest: Encodable {
            let refreshToken: String
        }
        
        struct TokenResponse: Decodable {
            let accessToken: String
            let refreshToken: String
        }
        
        // Check if refresh is needed
        guard let currentUser = currentUserSubject.value,
              !currentUser.isTokenValid() else {
            return
        }
        
        // Get refresh token
        guard let refreshTokenData = try? await keychainManager.retrieve(key: refreshTokenKey).get(),
              let refreshToken = String(data: refreshTokenData, encoding: .utf8) else {
            throw APIError.unauthorized
        }
        
        // Send refresh request
        let endpoint = RefreshEndpoint(body: RefreshRequest(refreshToken: refreshToken))
        let response = try await apiClient.request(endpoint)
        
        // Store new tokens
        try await storeTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
    }
    
    // MARK: - Private Methods
    
    /// Stores authentication tokens securely in keychain
    private func storeTokens(accessToken: String, refreshToken: String) async throws {
        guard let accessTokenData = accessToken.data(using: .utf8),
              let refreshTokenData = refreshToken.data(using: .utf8) else {
            throw APIError.invalidRequest("Invalid token format")
        }
        
        // Store tokens in keychain
        let accessTokenResult = keychainManager.save(data: accessTokenData, key: tokenKey)
        let refreshTokenResult = keychainManager.save(data: refreshTokenData, key: refreshTokenKey)
        
        // Check for storage errors
        if case .failure(let error) = accessTokenResult {
            throw APIError.serverError("Failed to store access token: \(error)")
        }
        if case .failure(let error) = refreshTokenResult {
            throw APIError.serverError("Failed to store refresh token: \(error)")
        }
    }
    
    /// Clears authentication tokens from keychain
    private func clearTokens() async throws {
        // Delete tokens from keychain
        let accessTokenResult = keychainManager.delete(key: tokenKey)
        let refreshTokenResult = keychainManager.delete(key: refreshTokenKey)
        
        // Check for deletion errors
        if case .failure(let error) = accessTokenResult {
            throw APIError.serverError("Failed to clear access token: \(error)")
        }
        if case .failure(let error) = refreshTokenResult {
            throw APIError.serverError("Failed to clear refresh token: \(error)")
        }
    }
    
    /// Attempts to restore user session from stored tokens
    private func restoreUserSession() async {
        struct UserEndpoint: APIEndpoint {
            typealias Response = User
            let path = "/users/me"
            let method: HTTPMethod = .get
            let headers: [String: String]?
            let body: EmptyRequest? = nil
            let queryItems: [URLQueryItem]? = nil
        }
        
        struct EmptyRequest: Encodable {}
        
        do {
            // Get stored access token
            guard let tokenData = try? await keychainManager.retrieve(key: tokenKey).get(),
                  let token = String(data: tokenData, encoding: .utf8) else {
                return
            }
            
            // Fetch current user
            let endpoint = UserEndpoint(headers: ["Authorization": "Bearer \(token)"])
            let user = try await apiClient.request(endpoint)
            
            // Update user state
            currentUserSubject.send(user)
            
            // Set up token refresh monitoring
            Task {
                await monitorTokenExpiration()
            }
        } catch {
            // Clear invalid session
            try? await clearTokens()
            currentUserSubject.send(nil)
        }
    }
    
    /// Monitors token expiration and refreshes when needed
    private func monitorTokenExpiration() async {
        while true {
            guard let user = currentUserSubject.value else {
                break
            }
            
            // Check if token needs refresh
            if !user.isTokenValid() {
                do {
                    try await refreshToken()
                } catch {
                    // Handle refresh failure
                    try? await clearTokens()
                    currentUserSubject.send(nil)
                    break
                }
            }
            
            // Wait before next check
            try? await Task.sleep(nanoseconds: UInt64(Constants.tokenRefreshThreshold * 1_000_000_000))
        }
    }
}