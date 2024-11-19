package com.founditure.data.database.entity

// androidx.room:room-runtime:2.6.0
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.TypeConverters

import com.founditure.domain.model.User
import com.founditure.domain.model.Achievement

/**
 * Human Tasks:
 * 1. Ensure Room database dependencies are properly configured in build.gradle
 * 2. Verify that AchievementConverter class is implemented and registered in the Room database
 * 3. Configure database migration strategies if schema changes are made
 * 4. Set up database encryption if storing sensitive user data
 */

/**
 * Room database entity representing a user in the local database.
 * Provides offline data persistence and caching for user profiles.
 *
 * Requirements addressed:
 * - User Profile Management (1.3 Scope/Core Features): Implements local storage and caching of user profile data
 * - User Engagement (1.2 System Overview/Success Criteria): Enables offline access to user profile and gamification data
 */
@Entity(tableName = "users")
@TypeConverters(AchievementConverter::class)
data class UserEntity(
    @PrimaryKey
    val id: String,

    @ColumnInfo(name = "email")
    val email: String,

    @ColumnInfo(name = "display_name")
    val displayName: String,

    @ColumnInfo(name = "profile_image_url")
    val profileImageUrl: String,

    @ColumnInfo(name = "total_points")
    val totalPoints: Int,

    @ColumnInfo(name = "achievements")
    val achievements: List<Achievement>,

    @ColumnInfo(name = "created_at")
    val createdAt: Long,

    @ColumnInfo(name = "last_login_at")
    val lastLoginAt: Long,

    @ColumnInfo(name = "is_verified")
    val isVerified: Boolean,

    @ColumnInfo(name = "role")
    val role: String
) {
    /**
     * Converts this database entity to its corresponding domain model.
     * Maps all properties from the entity to create a complete User object.
     *
     * @return Domain model User object with all properties mapped from this entity
     */
    fun toDomainModel(): User {
        return User(
            id = id,
            email = email,
            displayName = displayName,
            profileImageUrl = profileImageUrl,
            totalPoints = totalPoints,
            achievements = achievements,
            createdAt = createdAt,
            lastLoginAt = lastLoginAt,
            isVerified = isVerified,
            role = role
        )
    }

    companion object {
        /**
         * Creates a UserEntity from a domain model User object.
         * This factory method facilitates the conversion from domain model to database entity.
         *
         * @param user The domain model User object to convert
         * @return UserEntity instance with all properties mapped from the domain model
         */
        fun fromDomainModel(user: User): UserEntity {
            return UserEntity(
                id = user.id,
                email = user.email,
                displayName = user.displayName,
                profileImageUrl = user.profileImageUrl,
                totalPoints = user.totalPoints,
                achievements = user.achievements,
                createdAt = user.createdAt,
                lastLoginAt = user.lastLoginAt,
                isVerified = user.isVerified,
                role = user.role
            )
        }
    }
}