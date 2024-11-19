/*
 * External dependencies:
 * kotlinx-coroutines-core:1.7.0
 * javax.inject:1
 */

package com.founditure.domain.usecase.message

import javax.inject.Inject
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map

import com.founditure.domain.model.Message
import com.founditure.data.repository.MessageRepository

/**
 * Human Tasks:
 * 1. Configure proper dependency injection in the DI module
 * 2. Verify proper error tracking is set up for message retrieval failures
 * 3. Set up appropriate logging and monitoring for message flow
 */

/**
 * Use case that encapsulates the business logic for retrieving messages for a user
 * with offline-first support and real-time updates.
 *
 * Requirements addressed:
 * - Real-time messaging (1.2 System Overview/High-Level Description):
 *   Implements real-time message retrieval with offline-first architecture
 * - Core Features/Messaging (1.3 Scope/In-Scope Elements):
 *   Enables real-time messaging between users with proper data handling
 */
class GetMessagesUseCase @Inject constructor(
    private val messageRepository: MessageRepository
) {

    /**
     * Executes the use case to retrieve messages for a user with offline-first support.
     * Returns a Flow of messages that updates in real-time as new messages arrive or
     * existing messages are updated.
     *
     * @param userId ID of the user whose messages to retrieve
     * @return Flow<List<Message>> Reactive stream of messages with offline-first support
     * @throws IllegalArgumentException if userId is empty
     */
    operator fun invoke(userId: String): Flow<List<Message>> {
        require(userId.isNotBlank()) { "User ID cannot be empty" }

        return messageRepository.getMessages(userId)
            .map { messages ->
                // Sort messages by timestamp in descending order (newest first)
                messages.sortedByDescending { it.timestamp }
            }
            .catch { exception ->
                // Log error but continue with empty list to maintain Flow
                println("Error retrieving messages: ${exception.message}")
                emit(emptyList())
            }
    }
}