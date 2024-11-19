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
 * 1. Configure proper email validation rules according to business requirements
 * 2. Set up password policy configuration in line with security standards
 * 3. Implement proper error logging and monitoring for registration failures
 * 4. Configure rate limiting for registration attempts if required
 */

/**
 * Use case implementation for user registration functionality.
 * Handles validation, registration logic and initial user setup with comprehensive error handling.
 *
 * Requirements addressed:
 * - User Authentication (1.3 Scope/Core Features): Implements user authentication and profile management
 * - Security Architecture (2.5 Security Architecture/5.1.1 Authentication Methods): 
 *   Email/Password authentication implementation using Firebase Auth
 */
@Singleton
class RegisterUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    /**
     * Executes the registration process with comprehensive validation.
     * Validates input data before attempting registration through the repository.
     *
     * @param email User's email address
     * @param password User's password
     * @param name User's display name
     * @return NetworkResult containing User data on success or validation error
     */
    suspend fun execute(
        email: String,
        password: String,
        name: String
    ): NetworkResult<User> {
        // Validate email format
        if (!validateEmail(email)) {
            return NetworkResult.Error("Invalid email format")
        }

        // Validate password strength
        if (!validatePassword(password)) {
            return NetworkResult.Error(
                "Password must be at least 8 characters long and contain uppercase, " +
                "lowercase, number and special character"
            )
        }

        // Validate display name
        if (name.length < 2 || !name.matches(Regex("^[a-zA-Z0-9\\s]{2,30}$"))) {
            return NetworkResult.Error(
                "Display name must be 2-30 characters long and contain only letters, numbers and spaces"
            )
        }

        // Attempt registration through repository
        return authRepository.register(email, password, name)
    }

    /**
     * Validates email format using RFC 5322 compliant regex pattern.
     *
     * @param email Email address to validate
     * @return true if email matches valid pattern
     */
    private fun validateEmail(email: String): Boolean {
        if (email.isBlank()) return false

        // RFC 5322 compliant email regex pattern
        val emailRegex = Regex(
            "^[a-zA-Z0-9.!#\$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}" +
            "[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\$"
        )
        return email.matches(emailRegex)
    }

    /**
     * Validates password meets security requirements.
     * Password must:
     * - Be at least 8 characters long
     * - Contain at least one uppercase letter
     * - Contain at least one lowercase letter
     * - Contain at least one number
     * - Contain at least one special character
     *
     * @param password Password to validate
     * @return true if password meets all requirements
     */
    private fun validatePassword(password: String): Boolean {
        if (password.length < 8) return false

        val hasUpperCase = password.any { it.isUpperCase() }
        val hasLowerCase = password.any { it.isLowerCase() }
        val hasDigit = password.any { it.isDigit() }
        val hasSpecialChar = password.any { !it.isLetterOrDigit() }

        return hasUpperCase && hasLowerCase && hasDigit && hasSpecialChar
    }
}