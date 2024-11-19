package com.founditure.presentation.profile

// External dependencies
import androidx.lifecycle.ViewModel // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
import androidx.lifecycle.viewModelScope // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
import kotlinx.coroutines.flow.StateFlow // kotlinx-coroutines-core:1.7.0
import kotlinx.coroutines.flow.MutableStateFlow // kotlinx-coroutines-core:1.7.0
import kotlinx.coroutines.flow.asStateFlow // kotlinx-coroutines-core:1.7.0
import kotlinx.coroutines.launch // kotlinx-coroutines-core:1.7.0
import javax.inject.Inject // javax.inject:1

// Internal dependencies
import com.founditure.domain.model.User
import com.founditure.domain.model.Achievement
import com.founditure.data.repository.UserRepository

/**
 * Human Tasks:
 * 1. Verify Hilt/Dagger DI configuration for ViewModel injection
 * 2. Configure proper error tracking and analytics for profile interactions
 * 3. Set up proper testing environment for ViewModel unit tests
 * 4. Ensure proper memory management for coroutines and state flows
 */

/**
 * ViewModel managing user profile data and interactions for the profile screen.
 * Implements offline-first architecture with coroutines and state management.
 *
 * Requirements addressed:
 * - User Profile Management (1.3 Scope/Core Features): 
 *   Implements comprehensive profile data management with offline support
 * - Gamification System (1.2 System Overview): 
 *   Manages achievement tracking and points display
 * - User Engagement (1.2 System Overview/Success Criteria): 
 *   Enables 70% monthly active user retention through profile features
 */
class ProfileViewModel @Inject constructor(
    private val userRepository: UserRepository
) : ViewModel() {

    // Internal mutable state
    private val _uiState = MutableStateFlow<ProfileUiState>(ProfileUiState.Loading)
    
    // Exposed immutable state
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()

    init {
        loadUserProfile()
    }

    /**
     * Loads user profile data from repository with error handling.
     * Implements offline-first approach using repository pattern.
     */
    private fun loadUserProfile() {
        viewModelScope.launch {
            _uiState.value = ProfileUiState.Loading
            
            try {
                // Get current user ID from repository
                userRepository.getUser("current_user").collect { user ->
                    if (user != null) {
                        _uiState.value = ProfileUiState.Success(user)
                    } else {
                        _uiState.value = ProfileUiState.Error(
                            "Unable to load profile data. Please try again."
                        )
                    }
                }
            } catch (e: Exception) {
                _uiState.value = ProfileUiState.Error(
                    "An error occurred while loading profile: ${e.message}"
                )
            }
        }
    }

    /**
     * Forces a refresh of profile data.
     * Triggers repository to fetch fresh data while maintaining offline support.
     */
    fun refreshProfile() {
        loadUserProfile()
    }

    /**
     * Retrieves list of completed achievements.
     * Supports gamification system by tracking user progress.
     *
     * @return List of unlocked achievements or empty list if no data
     */
    fun getUnlockedAchievements(): List<Achievement> {
        return when (val currentState = uiState.value) {
            is ProfileUiState.Success -> currentState.user.getUnlockedAchievements()
            else -> emptyList()
        }
    }

    /**
     * Retrieves list of in-progress achievements.
     * Supports user engagement through achievement progress tracking.
     *
     * @return List of achievements in progress or empty list if no data
     */
    fun getProgressingAchievements(): List<Achievement> {
        return when (val currentState = uiState.value) {
            is ProfileUiState.Success -> currentState.user.getProgressingAchievements()
            else -> emptyList()
        }
    }
}

/**
 * Sealed class representing possible UI states for profile screen.
 * Implements type-safe state management for profile data.
 */
sealed class ProfileUiState {
    /**
     * Loading state while fetching profile data
     */
    object Loading : ProfileUiState()
    
    /**
     * Success state with loaded profile data
     */
    data class Success(val user: User) : ProfileUiState()
    
    /**
     * Error state when profile loading fails
     */
    data class Error(val message: String) : ProfileUiState()
}