/*
 * External dependencies:
 * kotlinx-coroutines-core:1.7.0
 */

package com.founditure.data.api

/**
 * A sealed class that wraps API responses to handle success and error states in a type-safe way.
 * 
 * Requirements addressed:
 * - API Architecture (3.3.1): Implements standardized response handling for REST/HTTP/2 protocol
 * - System Monitoring (2.4.1): Provides error tracking and request tracing capabilities
 */
sealed class NetworkResult<out T> {
    
    /**
     * Represents a successful network operation containing the response data.
     * @param data The typed payload data returned from the API
     */
    data class Success<out T>(val data: T) : NetworkResult<T>()

    /**
     * Represents a failed network operation with error details.
     * @param message Detailed error message for tracking and monitoring
     */
    data class Error(val message: String) : NetworkResult<Nothing>()

    /**
     * Executes the provided block if this is a successful result.
     * @param block The suspend function to execute with the success data
     */
    suspend fun onSuccess(block: suspend (T) -> Unit) {
        when (this) {
            is Success -> block(data)
            is Error -> { /* Do nothing for error case */ }
        }
    }

    /**
     * Executes the provided block if this is an error result.
     * @param block The suspend function to execute with the error message
     */
    suspend fun onError(block: suspend (String) -> Unit) {
        when (this) {
            is Success -> { /* Do nothing for success case */ }
            is Error -> block(message)
        }
    }
}