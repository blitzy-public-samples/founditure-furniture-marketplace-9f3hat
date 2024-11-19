package com.founditure.domain.model

import android.os.Parcelable // Latest Android SDK version
import kotlinx.parcelize.Parcelize // kotlinx.parcelize:1.9.0
import com.founditure.domain.model.User

/**
 * Human Tasks:
 * 1. Ensure Android SDK is properly configured in the project's build.gradle
 * 2. Verify kotlinx.parcelize plugin is enabled in the module's build.gradle
 * 3. Configure ProGuard/R8 rules if using code obfuscation to preserve Parcelable implementation
 */

/**
 * Data class representing a message between users in the Founditure application's real-time messaging system.
 * This class implements Parcelable for efficient serialization across Android components.
 *
 * Requirements addressed:
 * - Real-time messaging (1.2 System Overview/High-Level Description): Implements core message data structure
 * - Core Features/Messaging (1.3 Scope/In-Scope Elements): Enables real-time messaging between users
 */
@Parcelize
data class Message(
    /**
     * Unique identifier for the message
     */
    val id: String,
    
    /**
     * ID of the user who sent the message
     */
    val senderId: String,
    
    /**
     * ID of the user who receives the message
     */
    val receiverId: String,
    
    /**
     * ID of the furniture listing this message is related to
     */
    val listingId: String,
    
    /**
     * Actual content/text of the message
     */
    val content: String,
    
    /**
     * Timestamp when the message was sent (in milliseconds since epoch)
     */
    val timestamp: Long,
    
    /**
     * Flag indicating if the message has been read by the receiver
     */
    val isRead: Boolean
) : Parcelable {

    /**
     * Converts the domain model to a database entity representation.
     * This method facilitates the data layer conversion for persistence.
     *
     * @return MessageEntity representation of this message
     */
    fun toEntity(): MessageEntity {
        return MessageEntity(
            id = id,
            senderId = senderId,
            receiverId = receiverId,
            listingId = listingId,
            content = content,
            timestamp = timestamp,
            isRead = isRead
        )
    }

    /**
     * Checks if the message was sent by a specific user.
     *
     * @param userId The ID of the user to check against
     * @return true if the message was sent by the specified user, false otherwise
     */
    fun isFromUser(userId: String): Boolean {
        return senderId == userId
    }
}