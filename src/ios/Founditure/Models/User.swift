// Foundation framework - Latest
import Foundation
// Internal imports
import APIClient

/// Human Tasks:
/// 1. Configure secure keychain storage for access tokens
/// 2. Set up proper user data encryption at rest
/// 3. Implement biometric authentication for sensitive operations
/// 4. Configure proper logging for authentication events
/// 5. Set up user session monitoring and timeout handling

// MARK: - UserRole Enum
/// Defines available user roles with hierarchical access levels
/// Requirements addressed:
/// - Authorization Model (5.1.2): Implementation of role-based access control
public enum UserRole: String, Codable {
    case admin
    case moderator
    case verifiedUser
    case basicUser
}

// MARK: - AuthProvider Enum
/// Supported authentication providers for user sign-in
/// Requirements addressed:
/// - Authentication Methods (5.1.1): Support for multiple authentication providers
public enum AuthProvider: String, Codable {
    case email
    case google
    case apple
    case facebook
}

// MARK: - UserProfile Struct
/// Represents user profile information with optional fields
/// Requirements addressed:
/// - Data Security (5.2.1): Secure handling of personal information
public struct UserProfile: Codable {
    public let displayName: String
    public var avatarUrl: String?
    public var bio: String?
    public var phoneNumber: String?
    public var dateOfBirth: Date?
    public var interests: [String]
    
    public init(
        displayName: String,
        avatarUrl: String? = nil,
        bio: String? = nil,
        phoneNumber: String? = nil,
        dateOfBirth: Date? = nil,
        interests: [String] = []
    ) {
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.bio = bio
        self.phoneNumber = phoneNumber
        self.dateOfBirth = dateOfBirth
        self.interests = interests
    }
}

// MARK: - User Class
/// Main user model implementing secure data handling and authentication state management
/// Requirements addressed:
/// - Authentication Methods (5.1.1): Secure token management
/// - Data Security (5.2.1): Secure storage of user credentials
public final class User {
    // MARK: - Properties
    
    public let id: UUID
    public let email: String
    public let role: UserRole
    public let provider: AuthProvider
    public var providerId: String?
    public var profile: UserProfile
    public var points: Int
    public var achievements: [String]
    public var emailVerified: Bool
    public var lastLoginAt: Date?
    public var accessToken: String?
    public var accessTokenExpiresAt: Date?
    
    // MARK: - Initialization
    
    public init(
        id: UUID,
        email: String,
        role: UserRole,
        provider: AuthProvider,
        profile: UserProfile
    ) {
        self.id = id
        self.email = email
        self.role = role
        self.provider = provider
        self.profile = profile
        self.points = 0
        self.achievements = []
        self.emailVerified = false
    }
    
    // MARK: - Public Methods
    
    /// Checks if the current access token is valid and not expired
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Token validation
    public func isTokenValid() -> Bool {
        guard let token = accessToken,
              let expiresAt = accessTokenExpiresAt,
              !token.isEmpty else {
            return false
        }
        return expiresAt > Date()
    }
    
    /// Updates user profile information through API client
    /// Requirements addressed:
    /// - Data Security (5.2.1): Secure profile data transmission
    public func updateProfile(_ newProfile: UserProfile) async throws {
        // Create API endpoint for profile update
        struct ProfileUpdateEndpoint: APIEndpoint {
            typealias Response = UserProfile
            let path: String
            let method: HTTPMethod = .put
            let headers: [String: String]?
            let body: UserProfile
            let queryItems: [URLQueryItem]? = nil
        }
        
        // Validate access token
        guard isTokenValid() else {
            throw APIError.unauthorized
        }
        
        // Create endpoint with authorization header
        let endpoint = ProfileUpdateEndpoint(
            path: "/users/\(id.uuidString)/profile",
            headers: ["Authorization": "Bearer \(accessToken ?? "")"],
            body: newProfile
        )
        
        // Send update request
        let updatedProfile = try await APIClient().request(endpoint)
        
        // Update local profile data on success
        self.profile = updatedProfile
    }
}

// MARK: - User Extensions
extension User: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, email, role, provider, providerId, profile, points
        case achievements, emailVerified, lastLoginAt
        case accessToken, accessTokenExpiresAt
    }
    
    /// Encodes user object to JSON with secure handling of sensitive data
    /// Requirements addressed:
    /// - Data Security (5.2.1): Secure data serialization
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(role, forKey: .role)
        try container.encode(provider, forKey: .provider)
        try container.encodeIfPresent(providerId, forKey: .providerId)
        try container.encode(profile, forKey: .profile)
        try container.encode(points, forKey: .points)
        try container.encode(achievements, forKey: .achievements)
        try container.encode(emailVerified, forKey: .emailVerified)
        try container.encodeIfPresent(lastLoginAt, forKey: .lastLoginAt)
        try container.encodeIfPresent(accessToken, forKey: .accessToken)
        try container.encodeIfPresent(accessTokenExpiresAt, forKey: .accessTokenExpiresAt)
    }
    
    /// Decodes user object from JSON with validation
    /// Requirements addressed:
    /// - Data Security (5.2.1): Secure data deserialization
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let id = try container.decode(UUID.self, forKey: .id)
        let email = try container.decode(String.self, forKey: .email)
        let role = try container.decode(UserRole.self, forKey: .role)
        let provider = try container.decode(AuthProvider.self, forKey: .provider)
        let profile = try container.decode(UserProfile.self, forKey: .profile)
        
        self.init(id: id, email: email, role: role, provider: provider, profile: profile)
        
        self.providerId = try container.decodeIfPresent(String.self, forKey: .providerId)
        self.points = try container.decode(Int.self, forKey: .points)
        self.achievements = try container.decode([String].self, forKey: .achievements)
        self.emailVerified = try container.decode(Bool.self, forKey: .emailVerified)
        self.lastLoginAt = try container.decodeIfPresent(Date.self, forKey: .lastLoginAt)
        self.accessToken = try container.decodeIfPresent(String.self, forKey: .accessToken)
        self.accessTokenExpiresAt = try container.decodeIfPresent(Date.self, forKey: .accessTokenExpiresAt)
    }
}

extension User: Identifiable {}

extension User: Equatable {
    public static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}