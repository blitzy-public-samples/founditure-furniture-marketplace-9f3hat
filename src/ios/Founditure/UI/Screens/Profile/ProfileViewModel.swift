// Foundation framework - Latest
import Foundation
// Combine framework - Latest
import Combine
// SwiftUI framework - Latest
import SwiftUI

/// Human Tasks:
/// 1. Configure analytics tracking for profile interactions
/// 2. Set up proper error logging for profile operations
/// 3. Review profile update validation rules with product team
/// 4. Verify proper handling of user session timeouts

/// ProfileViewModel: Manages user profile screen state and business logic
/// Requirements addressed:
/// - User Profile Management (1.2 System Overview/Core Features)
/// - Gamification System (1.1 Executive Summary)
/// - User Engagement (1.2 System Overview/Success Criteria)
@MainActor
@Observable
final class ProfileViewModel {
    // MARK: - Private Properties
    
    private let userService: UserService
    private let gamificationService: GamificationService
    
    // MARK: - Published Properties
    
    var currentUser: User?
    var userPoints: Int = 0
    var achievements: [Achievement] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    // MARK: - Initialization
    
    /// Initializes the ProfileViewModel with required services
    /// - Parameters:
    ///   - userService: Service for user operations
    ///   - gamificationService: Service for gamification features
    init(userService: UserService, gamificationService: GamificationService) {
        self.userService = userService
        self.gamificationService = gamificationService
        
        // Load initial user data
        Task {
            await loadUserProfile()
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads the current user profile and associated data
    /// Requirements addressed:
    /// - User Profile Management (1.2): Fetch and display user data
    /// - Gamification System (1.1): Load user achievements and points
    @MainActor
    func loadUserProfile() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch current user
            guard let user = userService.getCurrentUser() else {
                throw APIError.unauthorized
            }
            
            // Update current user
            currentUser = user
            
            // Fetch user points
            userPoints = try await gamificationService.getUserPoints(userId: user.id)
            
            // Fetch user achievements
            achievements = try await gamificationService.getUserAchievements(userId: user.id)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Updates the user profile with new information
    /// Requirements addressed:
    /// - User Profile Management (1.2): Update user profile data
    /// - Parameter newProfile: Updated profile information
    @MainActor
    func updateProfile(_ newProfile: UserProfile) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Update user profile
            currentUser = try await userService.updateUserProfile(newProfile)
            
            // Refresh profile data
            try await loadUserProfile()
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Logs out the current user
    /// Requirements addressed:
    /// - User Profile Management (1.2): User session management
    @MainActor
    func logout() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Perform logout
            try await userService.logout()
            
            // Clear local state
            currentUser = nil
            userPoints = 0
            achievements = []
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Refreshes all profile data
    /// Requirements addressed:
    /// - User Profile Management (1.2): Keep profile data up-to-date
    /// - Gamification System (1.1): Refresh achievements and points
    @MainActor
    func refreshData() async throws {
        do {
            try await loadUserProfile()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}