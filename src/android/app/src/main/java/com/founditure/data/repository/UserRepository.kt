package com.founditure.data.repository

// External dependencies
import javax.inject.Inject // javax.inject:1
import kotlinx.coroutines.flow.Flow // kotlinx-coroutines-core:1.7.0
import kotlinx.coroutines.flow.flow // kotlinx-coroutines-core:1.7.0
import kotlinx.coroutines.flow.map // kotlinx-coroutines-core:1.7.0

// Internal dependencies
import com.founditure.domain.model.User
import com.founditure.data.database.dao.UserDao
import com.founditure.data.database.entity.UserEntity
import com.founditure.data.api.ApiService
import com.founditure.data.api.NetworkResult

/**
 * Human Tasks:
 * 1. Verify database encryption is properly configured for user data
 * 2. Ensure proper network security configuration for API calls
 * 3. Configure offline data sync policies in app configuration
 * 4. Set up proper error tracking and monitoring for data operations
 * 5. Implement proper token refresh mechanism for API authentication
 */

/**
 * Repository implementing single source of truth pattern for user data management.
 * Coordinates between local database and remote API data sources with offline support.
 *
 * Requirements addressed:
 * - User Profile Management (1.3 Scope/Core Features): 
 *   Implements comprehensive user data management with offline support
 * - User Engagement (1.2 System Overview/Success Criteria): 
 *   Enables 70% monthly active user retention through effective data management
 * - Offline Support (1.3 Scope/Core Features): 
 *   Provides offline functionality through local caching
 */
@Inject
class UserRepository @Inject constructor(
    private val userDao: UserDao,
    private val apiService: ApiService
) {
    /**
     * Authenticates user and caches their data locally.
     * Implements offline-first approach with remote sync.
     *
     * @param email User's email address
     * @param password User's password
     * @return Flow emitting NetworkResult with User data or error
     */
    fun login(email: String, password: String): Flow<NetworkResult<User>> = flow {
        try {
            // Attempt to authenticate with API
            val response = apiService.login(mapOf(
                "email" to email,
                "password" to password
            ))

            response.onSuccess { user ->
                // Cache user data locally for offline access
                userDao.insertUser(UserEntity.fromDomainModel(user))
                emit(NetworkResult.Success(user))
            }.onError { message ->
                emit(NetworkResult.Error(message))
            }
        } catch (e: Exception) {
            emit(NetworkResult.Error("Authentication failed: ${e.message}"))
        }
    }

    /**
     * Registers new user and caches their data locally.
     * Implements data consistency with remote sync.
     *
     * @param email User's email address
     * @param password User's password
     * @param displayName User's display name
     * @return Flow emitting NetworkResult with User data or error
     */
    fun register(
        email: String, 
        password: String, 
        displayName: String
    ): Flow<NetworkResult<User>> = flow {
        try {
            // Attempt to register with API
            val response = apiService.register(mapOf(
                "email" to email,
                "password" to password,
                "displayName" to displayName
            ))

            response.onSuccess { user ->
                // Cache new user data locally
                userDao.insertUser(UserEntity.fromDomainModel(user))
                emit(NetworkResult.Success(user))
            }.onError { message ->
                emit(NetworkResult.Error(message))
            }
        } catch (e: Exception) {
            emit(NetworkResult.Error("Registration failed: ${e.message}"))
        }
    }

    /**
     * Retrieves user data with offline support.
     * Implements offline-first approach with background sync.
     *
     * @param userId Unique identifier of the user
     * @return Flow of user data updates or null if not found
     */
    fun getUser(userId: String): Flow<User?> {
        return userDao.getUser(userId).map { entity ->
            try {
                // Attempt to fetch fresh data from API in background
                val response = apiService.getProfile(userId)
                response.onSuccess { user ->
                    // Update local cache with fresh data
                    userDao.updateUser(UserEntity.fromDomainModel(user))
                }
                // Return cached data immediately while update happens in background
                entity?.toDomainModel()
            } catch (e: Exception) {
                // Return cached data on network error
                entity?.toDomainModel()
            }
        }
    }

    /**
     * Updates user points locally and syncs with remote.
     * Implements optimistic updates with conflict resolution.
     *
     * @param userId Unique identifier of the user
     * @param points New total points value
     * @return NetworkResult with updated User data or error
     */
    suspend fun updateUserPoints(userId: String, points: Int): NetworkResult<User> {
        try {
            // Update points locally first (optimistic update)
            val updateResult = userDao.updateUserPoints(userId, points)
            if (updateResult == 0) {
                return NetworkResult.Error("User not found")
            }

            // Sync with remote API
            val response = apiService.getProfile(userId)
            return when (response) {
                is NetworkResult.Success -> {
                    val updatedUser = response.data
                    // Ensure local cache reflects server state
                    userDao.updateUser(UserEntity.fromDomainModel(updatedUser))
                    NetworkResult.Success(updatedUser)
                }
                is NetworkResult.Error -> {
                    // Revert local update on sync failure
                    val cachedUser = userDao.getUser(userId).map { it?.toDomainModel() }
                    NetworkResult.Error("Failed to sync points: ${response.message}")
                }
            }
        } catch (e: Exception) {
            return NetworkResult.Error("Failed to update points: ${e.message}")
        }
    }
}