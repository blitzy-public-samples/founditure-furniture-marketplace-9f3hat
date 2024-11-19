package com.founditure.domain.model

import android.os.Parcelable // Latest Android SDK version
import kotlinx.parcelize.Parcelize // kotlinx.parcelize:1.9.0
import com.founditure.domain.model.User.id

/**
 * Human Tasks:
 * 1. Ensure Android SDK is properly configured in the project's build.gradle
 * 2. Verify kotlinx.parcelize plugin is enabled in the module's build.gradle
 * 3. Configure ProGuard/R8 rules if using code obfuscation to preserve Parcelable implementation
 * 4. Set up proper listing expiration threshold in configuration
 */

/**
 * Enum class representing possible states of a furniture listing
 * 
 * Requirements addressed:
 * - Core Features - Furniture listings (1.3 Scope/Core Features): 
 *   Defines standardized listing states for furniture item lifecycle management
 */
enum class ListingStatus {
    AVAILABLE,
    PENDING,
    COLLECTED,
    EXPIRED,
    REMOVED
}

/**
 * Enum class representing the condition of the furniture item
 * 
 * Requirements addressed:
 * - Core Features - Furniture listings (1.3 Scope/Core Features): 
 *   Standardizes furniture condition classification for consistent item quality assessment
 */
enum class FurnitureCondition {
    EXCELLENT,
    GOOD,
    FAIR,
    POOR
}

/**
 * Data class representing a furniture listing with all its details.
 * 
 * Requirements addressed:
 * - Core Features - Furniture listings (1.3 Scope/Core Features): 
 *   Implements comprehensive furniture listing data structure
 * - AI-powered furniture recognition (1.3 Scope/Core Features):
 *   Supports AI-generated tags for furniture categorization
 * - Location-based discovery (1.3 Scope/Core Features):
 *   Includes geolocation data for furniture items
 */
@Parcelize
data class Listing(
    /**
     * Unique identifier for the listing
     */
    val id: String,
    
    /**
     * Reference to the user who created the listing
     */
    val userId: String,
    
    /**
     * Title/name of the furniture item
     */
    val title: String,
    
    /**
     * Detailed description of the furniture item
     */
    val description: String,
    
    /**
     * Current status of the listing
     */
    val status: ListingStatus,
    
    /**
     * Physical condition of the furniture
     */
    val condition: FurnitureCondition,
    
    /**
     * List of URLs to the furniture item images
     */
    val imageUrls: List<String>,
    
    /**
     * Geographical latitude of the furniture location
     */
    val latitude: Double,
    
    /**
     * Geographical longitude of the furniture location
     */
    val longitude: Double,
    
    /**
     * Human-readable address of the furniture location
     */
    val address: String,
    
    /**
     * AI-generated tags and categories for the furniture
     */
    val aiTags: Map<String, String>,
    
    /**
     * Timestamp when the listing was created
     */
    val postedAt: Long,
    
    /**
     * Timestamp of the last update to the listing
     */
    val updatedAt: Long
) : Parcelable {

    companion object {
        // Listing expiration threshold in milliseconds (30 days)
        private const val EXPIRATION_THRESHOLD = 30L * 24 * 60 * 60 * 1000
    }

    /**
     * Checks if the listing is still available for collection
     *
     * @return true if the listing status is AVAILABLE
     */
    fun isAvailable(): Boolean {
        return status == ListingStatus.AVAILABLE
    }

    /**
     * Checks if the listing has expired based on posting time
     *
     * @return true if the listing has exceeded the expiration threshold
     */
    fun isExpired(): Boolean {
        val currentTime = System.currentTimeMillis()
        return (currentTime - postedAt) > EXPIRATION_THRESHOLD
    }

    /**
     * Converts the domain model to a database entity
     *
     * @return ListingEntity instance created from this domain model
     */
    fun toListingEntity(): ListingEntity {
        return ListingEntity(
            id = id,
            userId = userId,
            title = title,
            description = description,
            status = status.name,
            condition = condition.name,
            imageUrls = imageUrls.joinToString(","),
            latitude = latitude,
            longitude = longitude,
            address = address,
            aiTags = aiTags.entries.joinToString(",") { "${it.key}:${it.value}" },
            postedAt = postedAt,
            updatedAt = updatedAt
        )
    }
}

/**
 * Data class representing the database entity for a Listing
 * Note: This is a simplified version - actual implementation should match your database schema
 */
data class ListingEntity(
    val id: String,
    val userId: String,
    val title: String,
    val description: String,
    val status: String,
    val condition: String,
    val imageUrls: String,
    val latitude: Double,
    val longitude: Double,
    val address: String,
    val aiTags: String,
    val postedAt: Long,
    val updatedAt: Long
)