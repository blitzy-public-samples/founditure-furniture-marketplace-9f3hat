// External dependencies
import { Injectable } from '@nestjs/common';
import { Model } from 'mongoose'; // v7.5.0
import { validate } from 'class-validator'; // v0.14.0
import { plainToClass } from 'class-transformer'; // v0.5.1

// Internal dependencies
import { Message, MessageType, MessageStatus } from '../models/message.model';
import { Service } from '../../../shared/interfaces/service.interface';
import { SocketManager } from '../utils/socket.util';

/**
 * Human Tasks:
 * 1. Configure MongoDB replica set for real-time updates
 * 2. Set up Redis cluster for WebSocket scaling
 * 3. Configure proper monitoring for message delivery tracking
 * 4. Set up proper logging for message events
 * 5. Implement message retention policy based on business requirements
 */

/**
 * Data transfer object for message creation with validation
 * Requirement: 2.2.1 Core Components/Messaging Service - Message validation
 */
export class CreateMessageDto {
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
}

/**
 * Service class implementing messaging functionality with real-time capabilities
 * Requirement: 2.2.1 Core Components/Messaging Service - Real-time communication
 */
@Injectable()
export class MessageService implements Service<Message> {
    constructor(
        private readonly messageModel: Model<Message>,
        private readonly socketManager: SocketManager
    ) {}

    /**
     * Creates and sends a new message with real-time delivery
     * Requirement: 2.2.1 Core Components/Messaging Service - Message creation and delivery
     */
    async createMessage(messageData: CreateMessageDto, senderId: string): Promise<Message> {
        // Validate message data
        const errors = await validate(plainToClass(CreateMessageDto, messageData));
        if (errors.length > 0) {
            throw new Error('Invalid message data: ' + JSON.stringify(errors));
        }

        // Create message document
        const message = new Message({
            senderId,
            receiverId: messageData.receiverId,
            listingId: messageData.listingId,
            content: messageData.content,
            type: messageData.type || MessageType.TEXT,
            status: MessageStatus.SENT,
            threadId: [senderId, messageData.receiverId].sort().join('-')
        });

        // Save message to database
        const savedMessage = await this.messageModel.create(message);

        // Create or get socket room and send real-time notification
        const roomId = await this.socketManager.createRoom({
            roomId: message.threadId,
            participants: [senderId, messageData.receiverId],
            listingId: messageData.listingId,
            createdAt: new Date(),
            isActive: true
        });

        await this.socketManager.sendMessage({
            senderId,
            receiverId: messageData.receiverId,
            listingId: messageData.listingId,
            content: messageData.content,
            type: messageData.type,
            threadId: message.threadId
        }, roomId);

        return savedMessage;
    }

    /**
     * Retrieves message thread between users for a listing with pagination
     * Requirement: 2.2.1 Core Components/Messaging Service - Message thread management
     */
    async getMessageThread(listingId: string, userId: string, options: FilterOptions): Promise<Message[]> {
        const { page = 1, limit = 50, sortOrder = 'desc' } = options;
        const skip = (page - 1) * limit;

        const messages = await this.messageModel
            .find({
                listingId,
                $or: [
                    { senderId: userId },
                    { receiverId: userId }
                ],
                isDeleted: false
            })
            .sort({ createdAt: sortOrder })
            .skip(skip)
            .limit(limit)
            .exec();

        return messages;
    }

    /**
     * Updates message status to read with real-time notification
     * Requirement: 2.2.1 Core Components/Messaging Service - Message status tracking
     */
    async markMessageAsRead(messageId: string, userId: string): Promise<void> {
        const message = await this.findById(messageId);
        if (!message) {
            throw new Error('Message not found');
        }

        // Verify user is the receiver
        if (message.receiverId !== userId) {
            throw new Error('Unauthorized to mark message as read');
        }

        // Update message status
        await message.markAsRead();

        // Emit read receipt via socket
        await this.socketManager.sendMessage({
            senderId: userId,
            receiverId: message.senderId,
            listingId: message.listingId,
            content: 'Message read',
            type: MessageType.SYSTEM,
            threadId: message.threadId
        }, message.threadId);
    }

    /**
     * Soft deletes a message with participant notification
     * Requirement: 2.2.1 Core Components/Messaging Service - Message lifecycle management
     */
    async deleteMessage(messageId: string, userId: string): Promise<boolean> {
        const message = await this.findById(messageId);
        if (!message) {
            throw new Error('Message not found');
        }

        // Verify user is a participant
        if (message.senderId !== userId && message.receiverId !== userId) {
            throw new Error('Unauthorized to delete message');
        }

        // Perform soft delete
        message.isDeleted = true;
        message.deletedAt = new Date();
        message.deletedBy = userId;
        await message.save();

        // Notify thread participants
        await this.socketManager.sendMessage({
            senderId: userId,
            receiverId: message.senderId === userId ? message.receiverId : message.senderId,
            listingId: message.listingId,
            content: 'Message deleted',
            type: MessageType.SYSTEM,
            threadId: message.threadId
        }, message.threadId);

        return true;
    }

    /**
     * Service interface implementation
     */
    async create(data: Partial<Message>, userId: string): Promise<Message> {
        return this.createMessage(data as CreateMessageDto, userId);
    }

    async findAll(options: FilterOptions): Promise<Message[]> {
        const { filters = {}, page = 1, limit = 50, sortOrder = 'desc' } = options;
        return this.messageModel
            .find({ ...filters, isDeleted: false })
            .sort({ createdAt: sortOrder })
            .skip((page - 1) * limit)
            .limit(limit)
            .exec();
    }

    async findById(id: string): Promise<Message | null> {
        return this.messageModel.findOne({ _id: id, isDeleted: false }).exec();
    }

    async update(id: string, data: Partial<Message>, userId: string): Promise<Message> {
        const message = await this.findById(id);
        if (!message) {
            throw new Error('Message not found');
        }

        // Verify user is the sender
        if (message.senderId !== userId) {
            throw new Error('Unauthorized to update message');
        }

        Object.assign(message, data);
        message.updatedBy = userId;
        return message.save();
    }

    async delete(id: string, userId: string): Promise<boolean> {
        return this.deleteMessage(id, userId);
    }

    async validate(data: Partial<Message>): Promise<ValidationResult> {
        const errors = await validate(plainToClass(Message, data));
        return {
            isValid: errors.length === 0,
            errors: errors.map(error => ({
                field: error.property,
                message: Object.values(error.constraints || {}).join(', '),
                code: 'VALIDATION_ERROR'
            }))
        };
    }
}