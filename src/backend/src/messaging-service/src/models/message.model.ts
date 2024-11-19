// External dependencies
import { Schema, model } from 'mongoose'; // v7.5.0
import { IsNotEmpty, IsMongoId, IsEnum, MaxLength } from 'class-validator'; // v0.14.0

// Internal dependencies
import { BaseModel, SoftDeletable } from '../../../shared/interfaces/model.interface';

/**
 * Human Tasks:
 * 1. Ensure MongoDB connection is properly configured with replica set for real-time updates
 * 2. Set up proper user context management for tracking message creators/updaters
 * 3. Configure message retention policies based on business requirements
 * 4. Set up proper monitoring for message delivery status tracking
 */

/**
 * Enum defining supported message types
 * Requirement: 2.2.1 Core Components/Messaging Service - Support for various message types
 */
export enum MessageType {
    TEXT = 'TEXT',
    IMAGE = 'IMAGE',
    LOCATION = 'LOCATION',
    SYSTEM = 'SYSTEM'
}

/**
 * Enum defining message delivery and read status
 * Requirement: 2.2.1 Core Components/Messaging Service - Message tracking and status
 */
export enum MessageStatus {
    SENT = 'SENT',
    DELIVERED = 'DELIVERED',
    READ = 'READ'
}

/**
 * Message model class for real-time communication
 * Requirement: 2.2.1 Core Components/Messaging Service - Real-time communication between users
 * Requirement: 3.2.2 Data Management Strategy - Message data persistence and auditing
 */
@Schema({ timestamps: true, collection: 'messages' })
export class Message implements BaseModel, SoftDeletable {
    id: string;

    @IsNotEmpty()
    @IsMongoId()
    senderId: string;

    @IsNotEmpty()
    @IsMongoId()
    receiverId: string;

    @IsNotEmpty()
    @IsMongoId()
    listingId: string;

    @IsNotEmpty()
    @MaxLength(2000)
    content: string;

    @IsEnum(MessageType)
    type: MessageType;

    @IsEnum(MessageStatus)
    status: MessageStatus;

    readAt: Date;

    @IsNotEmpty()
    threadId: string;

    metadata: Record<string, any>;

    isActive: boolean;
    createdBy: string;
    updatedBy: string;
    createdAt: Date;
    updatedAt: Date;

    // SoftDeletable implementation
    isDeleted: boolean;
    deletedAt: Date;
    deletedBy: string;

    constructor(messageData: Partial<Message>) {
        // Initialize base model properties
        this.id = messageData.id;
        this.createdAt = messageData.createdAt || new Date();
        this.updatedAt = messageData.updatedAt || new Date();
        this.createdBy = messageData.createdBy;
        this.updatedBy = messageData.updatedBy;
        
        // Set message specific properties
        this.senderId = messageData.senderId;
        this.receiverId = messageData.receiverId;
        this.listingId = messageData.listingId;
        this.content = messageData.content;
        this.type = messageData.type || MessageType.TEXT;
        this.status = messageData.status || MessageStatus.SENT;
        this.readAt = messageData.readAt;
        
        // Generate thread ID if not provided using senderId and receiverId
        this.threadId = messageData.threadId || 
            [messageData.senderId, messageData.receiverId].sort().join('-');
        
        // Initialize metadata
        this.metadata = messageData.metadata || {};
        
        // Set default flags
        this.isActive = messageData.isActive ?? true;
        this.isDeleted = messageData.isDeleted ?? false;
        this.deletedAt = messageData.deletedAt;
        this.deletedBy = messageData.deletedBy;
    }

    /**
     * Marks message as delivered and updates tracking
     * Requirement: 2.2.1 Core Components/Messaging Service - Message delivery tracking
     */
    async markAsDelivered(): Promise<void> {
        this.status = MessageStatus.DELIVERED;
        this.updatedAt = new Date();
        await model('Message').updateOne(
            { _id: this.id },
            { 
                $set: { 
                    status: this.status,
                    updatedAt: this.updatedAt
                }
            }
        );
    }

    /**
     * Marks message as read and updates tracking
     * Requirement: 2.2.1 Core Components/Messaging Service - Message read status tracking
     */
    async markAsRead(): Promise<void> {
        this.status = MessageStatus.READ;
        this.readAt = new Date();
        this.updatedAt = new Date();
        await model('Message').updateOne(
            { _id: this.id },
            { 
                $set: { 
                    status: this.status,
                    readAt: this.readAt,
                    updatedAt: this.updatedAt
                }
            }
        );
    }
}

// Create and export the Mongoose model
export default model<Message>('Message', Schema.from(Message));