package com.founditure.data.database.dao

// androidx.room:room-runtime:2.6.0
import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update

// kotlinx-coroutines-core:1.7.0
import kotlinx.coroutines.flow.Flow

import com.founditure.data.database.entity.MessageEntity

/**
 * Human Tasks:
 * 1. Ensure Room database configuration includes this DAO in the database builder
 * 2. Verify database migrations handle any query changes properly
 * 3. Set up database inspector in Android Studio for query debugging
 * 4. Configure appropriate database access patterns in the repository layer
 */

/**
 * Data Access Object interface for managing message persistence operations in the Room database.
 * Provides methods for real-time message updates and offline message caching support.
 *
 * Requirements addressed:
 * - Real-time messaging (1.2 System Overview/High-Level Description):
 *   Implements real-time message updates through Flow and offline support
 * - Core Features/Messaging (1.3 Scope/In-Scope Elements):
 *   Enables real-time messaging between users with local persistence capabilities
 */
@Dao
interface MessageDao {

    /**
     * Retrieves all messages for a specific user, either sent or received,
     * ordered by timestamp in descending order (newest first).
     *
     * @param userId ID of the user whose messages to retrieve
     * @return Flow emitting list of messages ordered by timestamp
     */
    @Query("SELECT * FROM messages WHERE sender_id = :userId OR receiver_id = :userId ORDER BY timestamp DESC")
    fun getAllMessages(userId: String): Flow<List<MessageEntity>>

    /**
     * Retrieves all messages related to a specific furniture listing,
     * ordered by timestamp in descending order (newest first).
     *
     * @param listingId ID of the furniture listing
     * @return Flow emitting list of messages for the listing
     */
    @Query("SELECT * FROM messages WHERE listing_id = :listingId ORDER BY timestamp DESC")
    fun getMessagesByListing(listingId: String): Flow<List<MessageEntity>>

    /**
     * Retrieves all unread messages for a specific user,
     * ordered by timestamp in descending order (newest first).
     *
     * @param userId ID of the user whose unread messages to retrieve
     * @return Flow emitting list of unread messages
     */
    @Query("SELECT * FROM messages WHERE receiver_id = :userId AND is_read = 0 ORDER BY timestamp DESC")
    fun getUnreadMessages(userId: String): Flow<List<MessageEntity>>

    /**
     * Inserts a new message into the database.
     *
     * @param message MessageEntity to insert
     * @return ID of the newly inserted message
     */
    @Insert
    suspend fun insertMessage(message: MessageEntity): Long

    /**
     * Updates an existing message in the database.
     *
     * @param message MessageEntity with updated values
     * @return Number of messages updated (0 or 1)
     */
    @Update
    suspend fun updateMessage(message: MessageEntity): Int

    /**
     * Marks a specific message as read in the database.
     *
     * @param messageId ID of the message to mark as read
     */
    @Query("UPDATE messages SET is_read = 1 WHERE id = :messageId")
    suspend fun markAsRead(messageId: String)

    /**
     * Deletes a message from the database.
     *
     * @param message MessageEntity to delete
     * @return Number of messages deleted (0 or 1)
     */
    @Delete
    suspend fun deleteMessage(message: MessageEntity): Int
}