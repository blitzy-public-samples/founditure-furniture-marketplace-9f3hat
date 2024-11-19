/*
 * External dependencies:
 * androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
 * javax.inject:1
 * kotlinx-coroutines-core:1.7.0
 */

package com.founditure.presentation.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.founditure.data.api.NetworkResult
import com.founditure.domain.model.User
import com.founditure.domain.usecase.auth.LoginUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Human Tasks:
 * 1. Configure proper error message localization
 * 2. Set up analytics tracking for login attempts and failures
 * 3. Implement proper logging for authentication events
 * 4. Configure proper testing coverage for all login scenarios
 */

/**
 * ViewModel responsible for managing login screen state and handling authentication operations.
 * Implements clean architecture principles with coroutines and state management.
 *
 * Requirements addressed:
 * - User Authentication (1.3 Scope/Core Features): Implements secure user authentication with validation
 * - API Architecture (3.3.1 API Architecture): Handles JWT + OAuth2 authentication with proper error handling
 */
@HiltViewModel
class LoginViewModel @Inject constructor(
    private val loginUseCase: LoginUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(LoginUiState())
    val uiState: StateFlow<LoginUiState> = _uiState.asStateFlow()

    /**
     * Attempts to authenticate user with provided credentials.
     * Handles loading state, validation, and error handling.
     *
     * Requirements addressed:
     * - User Authentication (1.3 Scope/Core Features): Implements secure login with validation
     * - API Architecture (3.3.1): Handles authentication with proper error handling
     *
     * @param email User's email address
     * @param password User's password
     */
    fun login(email: String, password: String) {
        if (!validateInput(email, password)) {
            _uiState.value = _uiState.value.copy(
                error = "Please enter a valid email and password"
            )
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(
                isLoading = true,
                error = null
            )

            try {
                when (val result = loginUseCase(email, password)) {
                    is NetworkResult.Success -> {
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            user = result.data,
                            error = null
                        )
                    }
                    is NetworkResult.Error -> {
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            error = result.message
                        )
                    }
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = "An unexpected error occurred. Please try again."
                )
            }
        }
    }

    /**
     * Validates login form input before attempting authentication.
     *
     * @param email Email address to validate
     * @param password Password to validate
     * @return true if input is valid, false otherwise
     */
    private fun validateInput(email: String, password: String): Boolean {
        return email.isNotBlank() && 
               email.matches(Regex("[a-zA-Z0-9+._%\\-]{1,256}@[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}(\\.[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25})+")) &&
               password.length >= 8
    }

    /**
     * Resets error state in UI.
     * Useful when navigating away from login screen or retrying login.
     */
    fun resetError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}

/**
 * Data class representing the UI state for login screen.
 * Implements clean architecture principles by separating UI state from business logic.
 *
 * Requirements addressed:
 * - User Authentication (1.3 Scope/Core Features): Manages login screen state
 */
data class LoginUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val user: User? = null
)