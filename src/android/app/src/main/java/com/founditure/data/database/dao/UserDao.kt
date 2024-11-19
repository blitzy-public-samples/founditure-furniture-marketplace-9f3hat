package com.founditure.data.database.dao

// androidx.room:room-runtime:2.6.0
import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update

// kotlinx-coroutines-core:1.7.0
import kotlinx.coroutines.flow.Flow

import com.founditure.data.database.entity.UserEntity

/**
 * Human Tasks:
 * 1. Ensure Room database dependencies are properly configured in build.gradle
 * 2. Verify database migrations are set up for any schema changes
 * 3. Configure database access patterns for optimal performance
 * 4. Set up database encryption if storing sensitive user data
 * 5. Implement proper error handling and recovery strategies for database operations
 */

/**
 * Room Database Data Access Object (DAO) interface for user-related database operations.
 * Provides methods for CRUD operations with reactive data access using Kotlin Flow.
 *
 * Requirements addressed:
 * - User Profile Management (1.3 Scope/Core Features): Implements local storage and management 
 *   of user profile data through comprehensive CRUD operations
 * - User Engagement (1.2 System Overview/Success Criteria): Enables offline access and caching 
 *   of user data through reactive Flow updates
 * - Gamification System (1.3 Scope/Core Features): Supports local storage and updates of user 
 *   points and achievements
 */
@Dao
interface UserDao {
    /**
     * Retrieves a user by their ID with reactive updates.
     * Returns a Flow that emits updates whenever the user data changes.
     *
     * @param userId The unique identifier of the user to retrieve
     * @return Flow emitting the user entity or null if not found
     */
    @Query("SELECT * FROM users WHERE id = :userId")
    fun getUser(userId: String): Flow<UserEntity?>

    /**
     * Retrieves a user by their email address with reactive updates.
     * Returns a Flow that emits updates whenever the user data changes.
     *
     * @param email The email address of the user to retrieve
     * @return Flow emitting the user entity or null if not found
     */
    @Query("SELECT * FROM users WHERE email = :email")
    fun getUserByEmail(email: String): Flow<UserEntity?>

    /**
     * Inserts a new user with complete profile data into the database.
     * This is a suspend function that should be called from a coroutine context.
     *
     * @param user The UserEntity containing all user data to be inserted
     * @return The row ID of the inserted user
     */
    @Insert
    suspend fun insertUser(user: UserEntity): Long

    /**
     * Updates all fields of an existing user in the database.
     * This is a suspend function that should be called from a coroutine context.
     *
     * @param user The UserEntity containing updated user data
     * @return Number of rows updated (1 if successful, 0 if user not found)
     */
    @Update
    suspend fun updateUser(user: UserEntity): Int

    /**
     * Deletes a user and all associated data from the database.
     * This is a suspend function that should be called from a coroutine context.
     *
     * @param user The UserEntity to be deleted
     * @return Number of rows deleted (1 if successful, 0 if user not found)
     */
    @Delete
    suspend fun deleteUser(user: UserEntity): Int

    /**
     * Updates a user's total points for gamification features.
     * This is a suspend function that should be called from a coroutine context.
     *
     * @param userId The unique identifier of the user
     * @param points The new total points value
     * @return Number of rows updated (1 if successful, 0 if user not found)
     */
    @Query("UPDATE users SET total_points = :points WHERE id = :userId")
    suspend fun updateUserPoints(userId: String, points: Int): Int
}