/*
 * External dependencies:
 * kotlinx-coroutines-core:1.7.0
 * javax.inject:1
 */

package com.founditure.data.repository

import javax.inject.Inject
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.onEach

import com.founditure.domain.model.Message
import com.founditure.data.database.dao.MessageDao
import com.founditure.data.api.ApiService
import com.founditure.data.api.NetworkResult
import com.founditure.data.database.entity.MessageEntity

/**
 * Human Tasks:
 * 1. Configure proper dependency injection in the DI module
 * 2. Set up appropriate database migration strategies for any schema changes
 * 3. Configure proper error tracking and monitoring for API calls
 * 4. Set up background job scheduling for message sync retries
 */

/**
 * Repository implementation for managing messages with offline-first architecture.
 * Handles both local database operations and remote API synchronization.
 *
 * Requirements addressed:
 * - Real-time messaging (1.2 System Overview/High-Level Description):
 *   Implements offline-first message management with real-time updates
 * - Core Features/Messaging (1.3 Scope/In-Scope Elements):
 *   Enables real-time messaging between users with offline persistence
 */
class MessageRepository @Inject constructor(
    private val messageDao: MessageDao,
    private val apiService: ApiService
) {

    /**
     * Retrieves messages for a user with offline-first approach.
     * Returns messages from local database and syncs with server in background.
     *
     * @param userId ID of the user whose messages to retrieve
     * @return Flow of messages from local database with background API sync
     */
    fun getMessages(userId: String): Flow<List<Message>> {
        // First emit from local database
        return messageDao.getAllMessages(userId)
            .map { entities -> entities.map { it.toDomainModel() } }
            .onEach { localMessages ->
                // Then sync with server in background
                try {
                    when (val apiResult = apiService.getMessages(listingId = "", otherUserId = userId)) {
                        is NetworkResult.Success -> {
                            apiResult.data.forEach { message ->
                                messageDao.insertMessage(message.toEntity())
                            }
                        }
                        is NetworkResult.Error -> {
                            // Log error but continue emitting local data
                            println("Error syncing messages: ${apiResult.message}")
                        }
                    }
                } catch (e: Exception) {
                    // Log error but continue emitting local data
                    println("Exception syncing messages: ${e.message}")
                }
            }
            .catch { e ->
                // Log error but continue with empty list
                println("Error in message flow: ${e.message}")
                emit(emptyList())
            }
    }

    /**
     * Retrieves messages for a specific listing with offline support.
     *
     * @param listingId ID of the listing whose messages to retrieve
     * @return Flow of messages from local database with background API sync
     */
    fun getListingMessages(listingId: String): Flow<List<Message>> {
        return messageDao.getMessagesByListing(listingId)
            .map { entities -> entities.map { it.toDomainModel() } }
            .onEach { localMessages ->
                try {
                    when (val apiResult = apiService.getMessages(listingId = listingId, otherUserId = "")) {
                        is NetworkResult.Success -> {
                            apiResult.data.forEach { message ->
                                messageDao.insertMessage(message.toEntity())
                            }
                        }
                        is NetworkResult.Error -> {
                            println("Error syncing listing messages: ${apiResult.message}")
                        }
                    }
                } catch (e: Exception) {
                    println("Exception syncing listing messages: ${e.message}")
                }
            }
            .catch { e ->
                println("Error in listing message flow: ${e.message}")
                emit(emptyList())
            }
    }

    /**
     * Sends a new message with offline support using optimistic updates.
     *
     * @param message Message to send
     * @return NetworkResult containing sent message or error
     */
    suspend fun sendMessage(message: Message): NetworkResult<Message> {
        // Save to local database first (optimistic update)
        messageDao.insertMessage(message.toEntity())

        // Then try to sync with server
        return try {
            val messageData = mapOf(
                "senderId" to message.senderId,
                "receiverId" to message.receiverId,
                "listingId" to message.listingId,
                "content" to message.content,
                "timestamp" to message.timestamp.toString()
            )

            when (val apiResult = apiService.sendMessage(messageData)) {
                is NetworkResult.Success -> {
                    // Update local message with server response
                    messageDao.updateMessage(apiResult.data.toEntity())
                    apiResult
                }
                is NetworkResult.Error -> {
                    // Keep local message for retry
                    apiResult
                }
            }
        } catch (e: Exception) {
            NetworkResult.Error("Failed to send message: ${e.message}")
        }
    }

    /**
     * Marks a message as read locally and syncs with server.
     *
     * @param messageId ID of the message to mark as read
     */
    suspend fun markMessageAsRead(messageId: String) {
        // Update local database first
        messageDao.markAsRead(messageId)

        // Then sync with server in background
        try {
            val messageData = mapOf(
                "messageId" to messageId,
                "isRead" to "true"
            )
            apiService.sendMessage(messageData)
        } catch (e: Exception) {
            println("Error syncing read status: ${e.message}")
            // Continue with local update even if server sync fails
        }
    }
}