/*
 * External dependencies:
 * androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
 * javax.inject:javax.inject:1
 * kotlinx.coroutines:kotlinx-coroutines-core:1.7.0
 * dagger.hilt:hilt-android:2.46
 */

package com.founditure.presentation.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.founditure.data.api.NetworkResult
import com.founditure.domain.model.User
import com.founditure.domain.usecase.auth.RegisterUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Human Tasks:
 * 1. Configure proper error logging and analytics for registration failures
 * 2. Set up proper error message localization
 * 3. Implement proper input validation rules according to business requirements
 * 4. Configure rate limiting for registration attempts if required
 */

/**
 * ViewModel implementation for the registration screen, handling user input validation,
 * registration state management, and user feedback using Kotlin Coroutines and StateFlow.
 *
 * Requirements addressed:
 * - User Authentication (1.3 Scope/Core Features): Implements user authentication and profile management
 * - Security Architecture (2.5 Security Architecture/5.1.1 Authentication Methods): 
 *   Email/Password authentication implementation using Firebase Auth
 */
@HiltViewModel
class RegisterViewModel @Inject constructor(
    private val registerUseCase: RegisterUseCase
) : ViewModel() {

    // Email input state
    private val _email = MutableStateFlow("")
    val email: StateFlow<String> = _email.asStateFlow()

    // Password input state
    private val _password = MutableStateFlow("")
    val password: StateFlow<String> = _password.asStateFlow()

    // Display name input state
    private val _name = MutableStateFlow("")
    val name: StateFlow<String> = _name.asStateFlow()

    // Loading state
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    // Error state
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    // Registered user state
    private val _registeredUser = MutableStateFlow<User?>(null)
    val registeredUser: StateFlow<User?> = _registeredUser.asStateFlow()

    /**
     * Updates the email input state.
     *
     * @param email New email value
     */
    fun updateEmail(email: String) {
        _email.value = email
    }

    /**
     * Updates the password input state.
     *
     * @param password New password value
     */
    fun updatePassword(password: String) {
        _password.value = password
    }

    /**
     * Updates the display name input state.
     *
     * @param name New display name value
     */
    fun updateName(name: String) {
        _name.value = name
    }

    /**
     * Initiates the registration process using the current input values.
     * Handles success and error states through NetworkResult.
     */
    fun register() {
        // Prevent multiple simultaneous registration attempts
        if (_isLoading.value) return

        viewModelScope.launch {
            try {
                _isLoading.value = true
                _error.value = null

                val result = registerUseCase.execute(
                    email = _email.value,
                    password = _password.value,
                    name = _name.value
                )

                result.onSuccess { user ->
                    _registeredUser.value = user
                }.onError { errorMessage ->
                    _error.value = errorMessage
                }
            } catch (e: Exception) {
                _error.value = "An unexpected error occurred. Please try again."
            } finally {
                _isLoading.value = false
            }
        }
    }

    /**
     * Clears the current error state.
     */
    fun clearError() {
        _error.value = null
    }
}