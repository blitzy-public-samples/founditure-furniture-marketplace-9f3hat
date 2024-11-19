/*
 * Human Tasks:
 * 1. Ensure SharedPreferences is properly initialized in the Application class or DI module
 * 2. Verify JWT token format and expiration handling in the authentication flow
 * 3. Configure token refresh mechanism if required
 * 4. Set up error handling for authentication failures
 * 5. Review security implications of token storage in SharedPreferences
 */

package com.founditure.data.api

// okhttp3 v4.11.0
import okhttp3.Interceptor
import okhttp3.Response
import okhttp3.Request
import okhttp3.Chain

// javax.inject v2.48
import javax.inject.Singleton
import javax.inject.Inject

// android.content (built-in)
import android.content.SharedPreferences

/**
 * OkHttp interceptor that adds authentication headers to API requests.
 * Implements JWT token-based authentication as specified in technical requirements
 * section 5.1.1 Authentication Methods and 3.3.1 API Architecture.
 */
@Singleton
class AuthInterceptor @Inject constructor(
    private val sharedPreferences: SharedPreferences
) : Interceptor {

    companion object {
        private const val AUTH_TOKEN_KEY = "auth_token"
        private const val AUTHORIZATION_HEADER = "Authorization"
        private const val BEARER_PREFIX = "Bearer "
    }

    /**
     * Intercepts HTTP requests to add JWT authentication token as Bearer token.
     * Implements requirement from section 5.1.1: "JWT Tokens for session management
     * and API authentication"
     *
     * @param chain The interceptor chain for processing the request
     * @return The HTTP response after processing through the chain
     */
    override fun intercept(chain: Chain): Response {
        // Get the original request from the chain
        val originalRequest = chain.request()

        // Retrieve the JWT auth token from SharedPreferences
        val authToken = sharedPreferences.getString(AUTH_TOKEN_KEY, null)

        // Create the modified request with authentication header if token exists
        val modifiedRequest = if (!authToken.isNullOrBlank()) {
            originalRequest.newBuilder()
                .header(AUTHORIZATION_HEADER, "$BEARER_PREFIX$authToken")
                .build()
        } else {
            // If no token is available, proceed with original request
            originalRequest
        }

        // Proceed with the request through the chain
        return chain.proceed(modifiedRequest)
    }
}