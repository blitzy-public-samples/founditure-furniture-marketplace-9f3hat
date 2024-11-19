package com.founditure.domain.model

import android.os.Parcelable // Latest Android SDK version
import kotlinx.parcelize.Parcelize // kotlinx.parcelize:1.9.0
import com.founditure.domain.model.Achievement

/**
 * Human Tasks:
 * 1. Ensure Android SDK is properly configured in the project's build.gradle
 * 2. Verify kotlinx.parcelize plugin is enabled in the module's build.gradle
 * 3. Configure ProGuard/R8 rules if using code obfuscation to preserve Parcelable implementation
 * 4. Set up proper user role constants in a separate configuration file
 */

/**
 * Domain model representing a user in the Founditure application.
 * This class implements core user profile functionality and gamification features.
 *
 * Requirements addressed:
 * - User Profile Management (1.3 Scope/Core Features): Implements comprehensive user profile data structure
 * - Gamification System (1.2 System Overview): Supports achievement tracking and points system
 * - User Engagement (1.2 System Overview/Success Criteria): Enables tracking of user activity and achievements
 */
@Parcelize
data class User(
    /**
     * Unique identifier for the user
     */
    val id: String,
    
    /**
     * User's email address, used for authentication and communication
     */
    val email: String,
    
    /**
     * User's display name shown in the application
     */
    val displayName: String,
    
    /**
     * URL to the user's profile image
     */
    val profileImageUrl: String,
    
    /**
     * Total points accumulated through achievements and activities
     */
    val totalPoints: Int,
    
    /**
     * List of user's achievements, both completed and in-progress
     */
    val achievements: List<Achievement>,
    
    /**
     * Timestamp when the user account was created
     */
    val createdAt: Long,
    
    /**
     * Timestamp of the user's last login
     */
    val lastLoginAt: Long,
    
    /**
     * Flag indicating if the user's email has been verified
     */
    val isVerified: Boolean,
    
    /**
     * User's role in the system (e.g., "USER", "ADMIN", "MODERATOR")
     */
    val role: String
) : Parcelable {

    /**
     * Returns a list of achievements that have been unlocked by the user.
     *
     * @return List of unlocked achievements
     */
    fun getUnlockedAchievements(): List<Achievement> {
        return achievements.filter { it.isComplete() }
    }

    /**
     * Returns a list of achievements that are currently in progress but not yet completed.
     * An achievement is considered "in progress" if it has some progress but is not yet complete.
     *
     * @return List of achievements that are in progress
     */
    fun getProgressingAchievements(): List<Achievement> {
        return achievements.filter { 
            !it.isComplete() && it.getProgressPercentage() > 0
        }
    }

    /**
     * Checks if the user has a specific role.
     *
     * @param roleName The role to check against
     * @return true if the user has the specified role, false otherwise
     */
    fun hasRole(roleName: String): Boolean {
        return role.equals(roleName, ignoreCase = true)
    }
}