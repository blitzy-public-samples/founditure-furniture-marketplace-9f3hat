/*
 * External dependencies:
 * javax.inject:1
 */

package com.founditure.domain.usecase.auth

import com.founditure.data.api.NetworkResult
import com.founditure.data.repository.AuthRepository
import com.founditure.domain.model.User
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Human Tasks:
 * 1. Configure proper email validation regex pattern in a constants file
 * 2. Set up password complexity requirements in a security configuration file
 * 3. Implement proper error message localization
 * 4. Configure proper logging for authentication failures
 */

/**
 * Use case implementation for handling user login operations with input validation.
 * Implements clean architecture principles to separate business logic from data layer operations.
 *
 * Requirements addressed:
 * - User Authentication (1.3 Scope/Core Features): Implements secure user authentication with validation
 * - API Architecture (3.3.1 API Architecture): Implements JWT + OAuth2 authentication with proper error handling
 */
@Singleton
class LoginUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    companion object {
        // Email validation regex pattern
        private val EMAIL_PATTERN = Regex(
            "[a-zA-Z0-9+._%\\-]{1,256}" +
            "@" +
            "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}" +
            "(" +
            "\\." +
            "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25}" +
            ")+"
        )

        // Minimum password requirements
        private const val MIN_PASSWORD_LENGTH = 8
    }

    /**
     * Executes the login operation with provided credentials, including input validation.
     * 
     * Requirements addressed:
     * - User Authentication (1.3 Scope/Core Features): Implements secure login with validation
     * - API Architecture (3.3.1): Handles authentication with proper error handling
     *
     * @param email User's email address
     * @param password User's password
     * @return NetworkResult containing User data on success or error message
     */
    suspend operator fun invoke(
        email: String,
        password: String
    ): NetworkResult<User> {
        // Validate email format
        if (!isValidEmail(email)) {
            return NetworkResult.Error("Invalid email format")
        }

        // Validate password requirements
        if (!isValidPassword(password)) {
            return NetworkResult.Error(
                "Password must be at least $MIN_PASSWORD_LENGTH characters long"
            )
        }

        // Attempt login through repository
        return try {
            authRepository.login(email, password)
        } catch (e: Exception) {
            NetworkResult.Error("Login failed: ${e.message}")
        }
    }

    /**
     * Validates email format using regex pattern.
     *
     * @param email Email address to validate
     * @return true if email format is valid, false otherwise
     */
    private fun isValidEmail(email: String): Boolean {
        return email.isNotBlank() && EMAIL_PATTERN.matches(email)
    }

    /**
     * Validates password meets minimum requirements.
     *
     * @param password Password to validate
     * @return true if password meets requirements, false otherwise
     */
    private fun isValidPassword(password: String): Boolean {
        return password.length >= MIN_PASSWORD_LENGTH
    }
}