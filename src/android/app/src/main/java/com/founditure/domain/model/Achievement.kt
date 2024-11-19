package com.founditure.domain.model

import android.os.Parcelable // Latest Android SDK version
import kotlinx.parcelize.Parcelize // kotlinx.parcelize:1.9.0

/**
 * Human Tasks:
 * 1. Ensure Android SDK is properly configured in the project's build.gradle
 * 2. Verify kotlinx.parcelize plugin is enabled in the module's build.gradle
 * 3. Configure ProGuard/R8 rules if using code obfuscation to preserve Parcelable implementation
 */

/**
 * Data class representing a user achievement in the Founditure application's gamification system.
 * This class is part of the core gamification system implementation that drives user engagement
 * and participation in furniture recovery activities.
 *
 * Requirements addressed:
 * - Gamification System (1.2 System Overview): Implements core achievement tracking functionality
 * - User Engagement (1.1 Executive Summary): Supports user retention through achievement progress tracking
 * - Community Growth (1.1 Executive Summary): Enables gamified interactions for community engagement
 */
@Parcelize
data class Achievement(
    /**
     * Unique identifier for the achievement
     */
    val id: String,
    
    /**
     * Display name of the achievement
     */
    val name: String,
    
    /**
     * Detailed description of how to earn the achievement
     */
    val description: String,
    
    /**
     * URL to the achievement's icon image
     */
    val iconUrl: String,
    
    /**
     * Number of points awarded when achievement is unlocked
     */
    val pointsValue: Int,
    
    /**
     * Flag indicating if the achievement has been unlocked
     */
    val isUnlocked: Boolean,
    
    /**
     * Timestamp when the achievement was unlocked (0 if not unlocked)
     */
    val unlockedAt: Long,
    
    /**
     * Category of the achievement (e.g., "furniture_recovery", "community_engagement")
     */
    val category: String,
    
    /**
     * Current progress towards completing the achievement
     */
    val progressCurrent: Int,
    
    /**
     * Total progress required to complete the achievement
     */
    val progressRequired: Int
) : Parcelable {
    
    /**
     * Checks if the achievement has been completed based on current progress.
     *
     * @return true if the current progress meets or exceeds the required progress
     */
    fun isComplete(): Boolean {
        return progressCurrent >= progressRequired
    }

    /**
     * Calculates the percentage completion of the achievement.
     *
     * @return percentage value between 0.0 and 100.0 representing completion progress
     */
    fun getProgressPercentage(): Float {
        val percentage = (progressCurrent.toFloat() / progressRequired.toFloat()) * 100
        return percentage.coerceIn(0f, 100f)
    }
}