package com.founditure.data.database.entity

// androidx.room:room-runtime:2.6.0
import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.founditure.domain.model.Message

/**
 * Human Tasks:
 * 1. Ensure Room database schema version is properly configured in the database implementation
 * 2. Verify database migration strategies are in place for schema changes
 * 3. Configure database inspector in Android Studio for debugging
 * 4. Set up appropriate database backup strategies
 */

/**
 * Room database entity representing a message in the local database.
 * This entity enables offline support and local caching for the messaging system.
 *
 * Requirements addressed:
 * - Real-time messaging (1.2 System Overview/High-Level Description): 
 *   Implements local persistence for offline message support
 * - Core Features/Messaging (1.3 Scope/In-Scope Elements): 
 *   Enables real-time messaging with local persistence capabilities
 * - Offline Support (1.2 System Overview/High-Level Description): 
 *   Provides local caching and offline access to messages
 */
@Entity(
    tableName = "messages",
    indices = [
        Index(value = ["sender_id"]),
        Index(value = ["receiver_id"]),
        Index(value = ["listing_id"])
    ]
)
data class MessageEntity(
    /**
     * Unique identifier for the message
     */
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,

    /**
     * ID of the user who sent the message
     */
    @ColumnInfo(name = "sender_id")
    val senderId: String,

    /**
     * ID of the user who receives the message
     */
    @ColumnInfo(name = "receiver_id")
    val receiverId: String,

    /**
     * ID of the furniture listing this message is related to
     */
    @ColumnInfo(name = "listing_id")
    val listingId: String,

    /**
     * Actual content/text of the message
     */
    @ColumnInfo(name = "content")
    val content: String,

    /**
     * Timestamp when the message was sent (in milliseconds since epoch)
     */
    @ColumnInfo(name = "timestamp")
    val timestamp: Long,

    /**
     * Flag indicating if the message has been read by the receiver
     */
    @ColumnInfo(name = "is_read")
    val isRead: Boolean
) {
    /**
     * Converts the database entity to a domain model Message instance.
     * This method facilitates the data layer conversion for business logic operations.
     *
     * @return Message domain model representation of this entity
     */
    fun toDomainModel(): Message {
        return Message(
            id = id,
            senderId = senderId,
            receiverId = receiverId,
            listingId = listingId,
            content = content,
            timestamp = timestamp,
            isRead = isRead
        )
    }

    companion object {
        /**
         * Creates a MessageEntity from a domain model Message instance.
         * This method facilitates the conversion from domain model to database entity.
         *
         * @param message The domain model Message to convert
         * @return MessageEntity representation of the provided Message
         */
        fun fromDomainModel(message: Message): MessageEntity {
            return MessageEntity(
                id = message.id,
                senderId = message.senderId,
                receiverId = message.receiverId,
                listingId = message.listingId,
                content = message.content,
                timestamp = message.timestamp,
                isRead = message.isRead
            )
        }
    }
}