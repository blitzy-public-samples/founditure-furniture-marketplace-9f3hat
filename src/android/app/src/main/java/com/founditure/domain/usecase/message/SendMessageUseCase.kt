/*
 * External dependencies:
 * javax.inject:1
 * kotlinx-coroutines-core:1.7.0
 */

package com.founditure.domain.usecase.message

import javax.inject.Inject
import com.founditure.data.repository.MessageRepository
import com.founditure.domain.model.Message
import com.founditure.data.api.NetworkResult

/**
 * Human Tasks:
 * 1. Configure proper dependency injection in the DI module
 * 2. Set up appropriate error tracking and monitoring for message sending failures
 * 3. Configure proper validation rules for message content and size limits
 */

/**
 * Use case implementation for sending messages between users with validation and error handling.
 * Implements offline-first approach with local persistence and background synchronization.
 *
 * Requirements addressed:
 * - Real-time messaging (1.2 System Overview/High-Level Description):
 *   Implements message sending with offline support and validation
 * - Core Features/Messaging (1.3 Scope/In-Scope Elements):
 *   Enables real-time messaging between users with error handling
 */
class SendMessageUseCase @Inject constructor(
    private val messageRepository: MessageRepository
) {

    /**
     * Executes the use case to send a message with validation.
     * Implements offline-first approach by saving locally first and then syncing with server.
     *
     * @param message The message to be sent
     * @return NetworkResult containing the sent message or error details
     */
    suspend operator fun invoke(message: Message): NetworkResult<Message> {
        // Validate message before sending
        if (!validateMessage(message)) {
            return NetworkResult.Error("Invalid message: Missing required fields or invalid content")
        }

        // Set current timestamp if not already set
        val messageToSend = if (message.timestamp == 0L) {
            message.copy(timestamp = System.currentTimeMillis())
        } else {
            message
        }

        // Send message through repository with offline support
        return messageRepository.sendMessage(messageToSend)
    }

    /**
     * Validates message content and required parameters.
     * Ensures all required fields are present and valid before sending.
     *
     * @param message Message to validate
     * @return true if message is valid, false otherwise
     */
    private fun validateMessage(message: Message): Boolean {
        // Check message content is not empty and within reasonable limits
        if (message.content.isBlank() || message.content.length > MAX_MESSAGE_LENGTH) {
            return false
        }

        // Verify sender ID is present and valid
        if (message.senderId.isBlank()) {
            return false
        }

        // Verify receiver ID is present and valid
        if (message.receiverId.isBlank()) {
            return false
        }

        // Validate listing ID exists
        if (message.listingId.isBlank()) {
            return false
        }

        return true
    }

    companion object {
        private const val MAX_MESSAGE_LENGTH = 1000 // Maximum characters allowed in a message
    }
}