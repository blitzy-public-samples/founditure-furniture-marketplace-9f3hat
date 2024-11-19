// Foundation framework - Latest
import Foundation
// Combine framework - Latest
import Combine
// LocalAuthentication framework - Latest
import LocalAuthentication

/// Human Tasks:
/// 1. Configure biometric authentication settings in device capabilities
/// 2. Set up proper error logging for authentication failures
/// 3. Review token refresh intervals with security team
/// 4. Configure proper keychain access groups if needed
/// 5. Verify proper handling of background state authentication

/// AuthError: Defines possible authentication-related errors
/// Requirements addressed:
/// - Authentication Methods (5.1.1): Comprehensive error handling for auth flows
public enum AuthError: Error {
    case invalidCredentials
    case networkError
    case tokenExpired
    case biometricError
    case registrationError
}

/// AuthService: Manages user authentication and session state
/// Requirements addressed:
/// - Authentication Methods (5.1.1): Support for email/password and biometric authentication
/// - Security Controls (5.3.2): Secure authentication and session management
/// - Data Security (5.2.1): Secure storage of auth tokens
@MainActor
public final class AuthService {
    // MARK: - Private Properties
    
    private let apiClient: APIClient
    private let keychainManager: KeychainManager
    private let authStateSubject = PassthroughSubject<User?, Never>()
    private var currentUser: User?
    private let biometricContext = LAContext()
    
    private enum Constants {
        static let tokenKey = "com.founditure.authToken"
        static let refreshTokenKey = "com.founditure.refreshToken"
        static let biometricKey = "com.founditure.biometricEnabled"
        static let tokenRefreshThreshold: TimeInterval = 300 // 5 minutes
    }
    
    // MARK: - Public Properties
    
    /// Publisher for observing authentication state changes
    public var authStatePublisher: AnyPublisher<User?, Never> {
        authStateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    /// Initializes the auth service with required dependencies
    /// - Parameters:
    ///   - apiClient: Client for making authenticated API requests
    ///   - keychainManager: Manager for secure token storage
    public init(apiClient: APIClient, keychainManager: KeychainManager) {
        self.apiClient = apiClient
        self.keychainManager = keychainManager
        
        // Attempt to restore previous session
        Task {
            await restoreSession()
        }
    }
    
    // MARK: - Public Methods
    
    /// Authenticates user with email and password
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Email/password authentication
    /// - Security Controls (5.3.2): Secure credential handling
    public func login(email: String, password: String) async throws -> User {
        struct LoginEndpoint: APIEndpoint {
            typealias Response = AuthResponse
            let path = "/auth/login"
            let method: HTTPMethod = .post
            let body: LoginRequest
            let headers: [String: String]? = nil
            let queryItems: [URLQueryItem]? = nil
        }
        
        let request = LoginRequest(email: email, password: password)
        let endpoint = LoginEndpoint(body: request)
        
        do {
            let response = try await apiClient.request(endpoint)
            
            // Store tokens securely
            try await storeTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
            
            // Create and store user
            let user = response.user
            self.currentUser = user
            authStateSubject.send(user)
            
            return user
        } catch {
            throw AuthError.invalidCredentials
        }
    }
    
    /// Registers new user with email and password
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): User registration
    /// - Data Security (5.2.1): Secure profile creation
    public func register(email: String, password: String, profile: UserProfile) async throws -> User {
        struct RegisterEndpoint: APIEndpoint {
            typealias Response = AuthResponse
            let path = "/auth/register"
            let method: HTTPMethod = .post
            let body: RegisterRequest
            let headers: [String: String]? = nil
            let queryItems: [URLQueryItem]? = nil
        }
        
        let request = RegisterRequest(email: email, password: password, profile: profile)
        let endpoint = RegisterEndpoint(body: request)
        
        do {
            let response = try await apiClient.request(endpoint)
            
            // Store tokens securely
            try await storeTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
            
            // Create and store user
            let user = response.user
            self.currentUser = user
            authStateSubject.send(user)
            
            return user
        } catch {
            throw AuthError.registrationError
        }
    }
    
    /// Logs out current user and clears session
    /// Requirements addressed:
    /// - Security Controls (5.3.2): Secure session termination
    public func logout() async throws {
        struct LogoutEndpoint: APIEndpoint {
            typealias Response = EmptyResponse
            let path = "/auth/logout"
            let method: HTTPMethod = .post
            let headers: [String: String]?
            let body: EmptyRequest? = nil
            let queryItems: [URLQueryItem]? = nil
        }
        
        // Get current token for logout request
        guard let token = try? await keychainManager.retrieve(key: Constants.tokenKey) else {
            throw AuthError.tokenExpired
        }
        
        let endpoint = LogoutEndpoint(headers: ["Authorization": "Bearer \(token)"])
        
        do {
            // Send logout request
            _ = try await apiClient.request(endpoint)
            
            // Clear stored tokens
            try await clearTokens()
            
            // Update auth state
            self.currentUser = nil
            authStateSubject.send(nil)
        } catch {
            // Still clear local state on error
            try await clearTokens()
            self.currentUser = nil
            authStateSubject.send(nil)
            throw AuthError.networkError
        }
    }
    
    /// Refreshes authentication token
    /// Requirements addressed:
    /// - Security Controls (5.3.2): Token refresh mechanism
    public func refreshToken() async throws {
        struct RefreshEndpoint: APIEndpoint {
            typealias Response = AuthResponse
            let path = "/auth/refresh"
            let method: HTTPMethod = .post
            let headers: [String: String]?
            let body: EmptyRequest? = nil
            let queryItems: [URLQueryItem]? = nil
        }
        
        guard let refreshToken = try? await keychainManager.retrieve(key: Constants.refreshTokenKey) else {
            throw AuthError.tokenExpired
        }
        
        let endpoint = RefreshEndpoint(headers: ["Authorization": "Bearer \(refreshToken)"])
        
        do {
            let response = try await apiClient.request(endpoint)
            try await storeTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
            
            // Update current user if needed
            if let user = response.user {
                self.currentUser = user
                authStateSubject.send(user)
            }
        } catch {
            throw AuthError.tokenExpired
        }
    }
    
    /// Performs biometric authentication
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Biometric authentication support
    public func authenticateWithBiometrics() async throws -> Bool {
        // Check if biometric authentication is available
        var error: NSError?
        guard biometricContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.biometricError
        }
        
        // Configure authentication reason
        let reason = "Authenticate to access your Founditure account"
        
        do {
            let success = try await biometricContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                // Attempt to restore session after biometric auth
                try await restoreSession()
            }
            
            return success
        } catch {
            throw AuthError.biometricError
        }
    }
    
    // MARK: - Private Methods
    
    /// Stores authentication tokens securely
    private func storeTokens(accessToken: String, refreshToken: String) async throws {
        // Store tokens in keychain
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                let tokenResult = self.keychainManager.save(data: accessToken.data(using: .utf8)!, key: Constants.tokenKey)
                if case .failure = tokenResult {
                    throw AuthError.invalidCredentials
                }
            }
            
            group.addTask {
                let refreshResult = self.keychainManager.save(data: refreshToken.data(using: .utf8)!, key: Constants.refreshTokenKey)
                if case .failure = refreshResult {
                    throw AuthError.invalidCredentials
                }
            }
            
            try await group.waitForAll()
        }
    }
    
    /// Clears stored authentication tokens
    private func clearTokens() async throws {
        // Remove tokens from keychain
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                let tokenResult = self.keychainManager.delete(key: Constants.tokenKey)
                if case .failure = tokenResult {
                    throw AuthError.networkError
                }
            }
            
            group.addTask {
                let refreshResult = self.keychainManager.delete(key: Constants.refreshTokenKey)
                if case .failure = refreshResult {
                    throw AuthError.networkError
                }
            }
            
            try await group.waitForAll()
        }
    }
    
    /// Attempts to restore previous authentication session
    private func restoreSession() async {
        guard let token = try? await keychainManager.retrieve(key: Constants.tokenKey),
              let user = currentUser,
              user.isTokenValid() else {
            currentUser = nil
            authStateSubject.send(nil)
            return
        }
        
        // Check if token needs refresh
        if let expiresAt = user.accessTokenExpiresAt,
           expiresAt.timeIntervalSinceNow < Constants.tokenRefreshThreshold {
            try? await refreshToken()
        }
        
        authStateSubject.send(user)
    }
}

// MARK: - Supporting Types

private struct LoginRequest: Encodable {
    let email: String
    let password: String
}

private struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let profile: UserProfile
}

private struct AuthResponse: Decodable {
    let user: User
    let accessToken: String
    let refreshToken: String
}

private struct EmptyRequest: Encodable {}
private struct EmptyResponse: Decodable {}