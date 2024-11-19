// Foundation framework - Latest version
import Foundation

/*
Human Tasks:
1. Verify achievement types match product requirements and gamification strategy
2. Confirm point values and required values align with engagement metrics
3. Review achievement descriptions for localization needs
*/

// MARK: - Achievement Types
/// Represents different categories of achievements in the gamification system
/// Requirement: Gamification System (1.1 Executive Summary)
@frozen
public enum AchievementType: Codable, CaseIterable {
    case firstFind      // First item found/saved
    case quickCollector // Rapid collection achievements  
    case superSaver    // Savings milestone achievements
}

// MARK: - Achievement Model
/// Core model for tracking user achievements and progress
/// Requirements:
/// - Gamification System (1.1 Executive Summary)
/// - User Engagement (1.2 System Overview/Success Criteria)
/// - Achievement Display (3.1 User Interface Design/3.1.7 Profile/Points Screen)
@frozen
public struct Achievement: Codable, Equatable {
    // MARK: - Properties
    public let id: String
    public let title: String
    public let description: String
    public let pointsValue: Int
    public let requiredValue: Int
    public let type: AchievementType
    
    public private(set) var currentProgress: Int
    public private(set) var isUnlocked: Bool
    public private(set) var unlockedAt: Date?
    
    // MARK: - Initialization
    /// Creates a new achievement with initial progress values
    /// - Parameters:
    ///   - id: Unique identifier for the achievement
    ///   - title: Display title of the achievement
    ///   - description: Detailed description of how to earn the achievement
    ///   - pointsValue: Points awarded when achievement is unlocked
    ///   - requiredValue: Target value needed to unlock the achievement
    ///   - type: Category of the achievement
    public init(id: String, title: String, description: String, pointsValue: Int, requiredValue: Int, type: AchievementType) {
        precondition(requiredValue > 0, "Required value must be greater than 0")
        precondition(pointsValue > 0, "Points value must be greater than 0")
        
        self.id = id
        self.title = title
        self.description = description
        self.pointsValue = pointsValue
        self.requiredValue = requiredValue
        self.type = type
        self.currentProgress = 0
        self.isUnlocked = false
        self.unlockedAt = nil
    }
    
    // MARK: - Progress Tracking
    /// Calculates the current completion percentage of the achievement
    /// - Returns: Progress percentage between 0 and 100
    public func progressPercentage() -> Double {
        guard requiredValue > 0 else { return 0 }
        let percentage = Double(currentProgress) / Double(requiredValue) * 100
        return min(max(percentage, 0), 100)
    }
    
    /// Updates the achievement progress and checks for completion
    /// - Parameter value: Progress value to add (must be positive)
    /// - Returns: True if achievement was just unlocked, false otherwise
    @discardableResult
    public mutating func updateProgress(value: Int) -> Bool {
        guard value > 0 else { return false }
        guard !isUnlocked else { return false }
        
        currentProgress += value
        
        if currentProgress >= requiredValue && !isUnlocked {
            isUnlocked = true
            unlockedAt = Date()
            return true
        }
        
        return false
    }
}