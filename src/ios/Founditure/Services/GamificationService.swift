// Foundation framework - Latest
import Foundation
// Combine framework - Latest
import Combine

/*
Human Tasks:
1. Verify achievement point values align with business metrics
2. Configure analytics tracking for gamification events
3. Set up monitoring for achievement progress updates
4. Review achievement unlock notifications configuration
5. Verify points calculation logic with product team
*/

/// GamificationService: Manages gamification features with real-time updates
/// Requirements addressed:
/// - Gamification System (1.1 Executive Summary)
/// - User Engagement (1.2 System Overview/Success Criteria)
/// - Points System (3.1 User Interface Design/3.1.7 Profile/Points Screen)
@MainActor
public final class GamificationService {
    // MARK: - Constants
    
    private enum Constants {
        static let POINTS_FIRST_FIND = 50
        static let POINTS_QUICK_COLLECTOR = 100
        static let POINTS_SUPER_SAVER = 500
    }
    
    // MARK: - Private Properties
    
    private let apiClient: APIClient
    private let achievementsSubject: CurrentValueSubject<[Achievement], Never>
    private let pointsSubject: CurrentValueSubject<Int, Never>
    
    // MARK: - Public Properties
    
    /// Publisher for observing achievements updates
    public var achievementsPublisher: AnyPublisher<[Achievement], Never> {
        achievementsSubject.eraseToAnyPublisher()
    }
    
    /// Publisher for observing points updates
    public var pointsPublisher: AnyPublisher<Int, Never> {
        pointsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    /// Initializes the gamification service with required dependencies
    /// - Parameter apiClient: API client for network requests
    public init(apiClient: APIClient) {
        self.apiClient = apiClient
        self.achievementsSubject = CurrentValueSubject<[Achievement], Never>([])
        self.pointsSubject = CurrentValueSubject<Int, Never>(0)
    }
    
    // MARK: - Public Methods
    
    /// Awards points to a user for specific actions
    /// Requirements addressed:
    /// - Points System (3.1 User Interface Design/3.1.7 Profile/Points Screen)
    /// - User Engagement (1.2 System Overview/Success Criteria)
    /// - Parameters:
    ///   - userId: User identifier
    ///   - points: Points to award
    /// - Returns: Updated total points
    public func awardPoints(userId: UUID, points: Int) async throws -> Int {
        // Validate points value
        guard points > 0 else {
            throw APIError.invalidRequest("Points value must be positive")
        }
        
        // Create points update endpoint
        struct PointsUpdateEndpoint: APIEndpoint {
            typealias Response = Int
            let path: String
            let method: HTTPMethod = .post
            let headers: [String: String]? = nil
            let queryItems: [URLQueryItem]? = nil
            let body: PointsUpdate
            
            struct PointsUpdate: Codable {
                let points: Int
            }
        }
        
        // Configure endpoint
        let endpoint = PointsUpdateEndpoint(
            path: "/users/\(userId.uuidString)/points",
            body: PointsUpdateEndpoint.PointsUpdate(points: points)
        )
        
        // Send points update request
        let updatedPoints = try await apiClient.request(endpoint)
        
        // Update local points subject
        pointsSubject.send(updatedPoints)
        
        return updatedPoints
    }
    
    /// Updates progress for a specific achievement
    /// Requirements addressed:
    /// - Gamification System (1.1 Executive Summary)
    /// - User Engagement (1.2 System Overview/Success Criteria)
    /// - Parameters:
    ///   - userId: User identifier
    ///   - achievementId: Achievement identifier
    ///   - progress: Progress value to update
    /// - Returns: Updated achievement
    public func updateAchievementProgress(userId: UUID, achievementId: String, progress: Int) async throws -> Achievement {
        // Create achievement update endpoint
        struct AchievementUpdateEndpoint: APIEndpoint {
            typealias Response = Achievement
            let path: String
            let method: HTTPMethod = .put
            let headers: [String: String]? = nil
            let queryItems: [URLQueryItem]? = nil
            let body: ProgressUpdate
            
            struct ProgressUpdate: Codable {
                let progress: Int
            }
        }
        
        // Configure endpoint
        let endpoint = AchievementUpdateEndpoint(
            path: "/users/\(userId.uuidString)/achievements/\(achievementId)",
            body: AchievementUpdateEndpoint.ProgressUpdate(progress: progress)
        )
        
        // Send achievement update request
        var updatedAchievement = try await apiClient.request(endpoint)
        
        // Update local achievements
        var achievements = achievementsSubject.value
        if let index = achievements.firstIndex(where: { $0.id == achievementId }) {
            achievements[index] = updatedAchievement
            achievementsSubject.send(achievements)
            
            // Check if achievement was just unlocked
            if updatedAchievement.isUnlocked {
                // Award achievement points
                _ = try await awardPoints(userId: userId, points: updatedAchievement.pointsValue)
            }
        }
        
        return updatedAchievement
    }
    
    /// Retrieves all achievements for a user
    /// Requirements addressed:
    /// - Gamification System (1.1 Executive Summary)
    /// - Points System (3.1 User Interface Design/3.1.7 Profile/Points Screen)
    /// - Parameter userId: User identifier
    /// - Returns: List of user achievements
    public func getUserAchievements(userId: UUID) async throws -> [Achievement] {
        // Create achievements endpoint
        struct AchievementsEndpoint: APIEndpoint {
            typealias Response = [Achievement]
            let path: String
            let method: HTTPMethod = .get
            let headers: [String: String]? = nil
            let queryItems: [URLQueryItem]? = nil
            let body: Encodable? = nil
        }
        
        // Configure endpoint
        let endpoint = AchievementsEndpoint(
            path: "/users/\(userId.uuidString)/achievements"
        )
        
        // Fetch achievements
        let achievements = try await apiClient.request(endpoint)
        
        // Update local achievements subject
        achievementsSubject.send(achievements)
        
        return achievements
    }
    
    /// Retrieves current points total for a user
    /// Requirements addressed:
    /// - Points System (3.1 User Interface Design/3.1.7 Profile/Points Screen)
    /// - Parameter userId: User identifier
    /// - Returns: Total user points
    public func getUserPoints(userId: UUID) async throws -> Int {
        // Create points endpoint
        struct PointsEndpoint: APIEndpoint {
            typealias Response = Int
            let path: String
            let method: HTTPMethod = .get
            let headers: [String: String]? = nil
            let queryItems: [URLQueryItem]? = nil
            let body: Encodable? = nil
        }
        
        // Configure endpoint
        let endpoint = PointsEndpoint(
            path: "/users/\(userId.uuidString)/points"
        )
        
        // Fetch points
        let points = try await apiClient.request(endpoint)
        
        // Update local points subject
        pointsSubject.send(points)
        
        return points
    }
}