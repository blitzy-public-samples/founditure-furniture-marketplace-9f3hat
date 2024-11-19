// External dependencies
import { jest } from '@jest/globals'; // v29.0.0
import mongoose from 'mongoose'; // v7.5.0
import { io as Client } from 'socket.io-client'; // v4.7.0
import request from 'supertest'; // v6.3.0

// Internal dependencies
import { Message, MessageType, MessageStatus } from '../src/models/message.model';
import { MessageService } from '../src/services/message.service';

/**
 * Human Tasks:
 * 1. Configure test MongoDB instance with replica set for real-time operations
 * 2. Set up Redis instance for WebSocket testing
 * 3. Configure test environment variables for WebSocket endpoints
 * 4. Ensure proper test data cleanup after test runs
 */

describe('Message Service', () => {
    let messageService: MessageService;
    let mockSocketManager: any;
    let testDb: typeof mongoose;

    // Mock data
    const mockSenderId = new mongoose.Types.ObjectId().toString();
    const mockReceiverId = new mongoose.Types.ObjectId().toString();
    const mockListingId = new mongoose.Types.ObjectId().toString();
    const mockThreadId = [mockSenderId, mockReceiverId].sort().join('-');

    beforeAll(async () => {
        // Requirement: 2.2.1 Core Components/Messaging Service - Test database setup
        testDb = await mongoose.connect(process.env.MONGODB_TEST_URI || 'mongodb://localhost:27017/test', {
            useNewUrlParser: true,
            useUnifiedTopology: true
        });

        // Mock socket manager
        mockSocketManager = {
            createRoom: jest.fn().mockResolvedValue(mockThreadId),
            sendMessage: jest.fn().mockResolvedValue(undefined)
        };

        // Initialize message service with mocked dependencies
        messageService = new MessageService(
            mongoose.model('Message'),
            mockSocketManager
        );
    });

    beforeEach(async () => {
        // Clear test data before each test
        await mongoose.model('Message').deleteMany({});
        jest.clearAllMocks();
    });

    afterAll(async () => {
        await testDb.disconnect();
    });

    describe('createMessage', () => {
        // Requirement: 2.2.1 Core Components/Messaging Service - Message creation and delivery
        it('should create and send a new message successfully', async () => {
            // Arrange
            const messageData = {
                receiverId: mockReceiverId,
                listingId: mockListingId,
                content: 'Test message content',
                type: MessageType.TEXT
            };

            // Act
            const result = await messageService.createMessage(messageData, mockSenderId);

            // Assert
            expect(result).toBeDefined();
            expect(result.senderId).toBe(mockSenderId);
            expect(result.receiverId).toBe(mockReceiverId);
            expect(result.content).toBe(messageData.content);
            expect(result.status).toBe(MessageStatus.SENT);
            expect(result.threadId).toBe(mockThreadId);

            // Verify socket room creation
            expect(mockSocketManager.createRoom).toHaveBeenCalledWith({
                roomId: mockThreadId,
                participants: [mockSenderId, mockReceiverId],
                listingId: mockListingId,
                createdAt: expect.any(Date),
                isActive: true
            });

            // Verify real-time message delivery
            expect(mockSocketManager.sendMessage).toHaveBeenCalledWith({
                senderId: mockSenderId,
                receiverId: mockReceiverId,
                listingId: mockListingId,
                content: messageData.content,
                type: MessageType.TEXT,
                threadId: mockThreadId
            }, mockThreadId);
        });

        // Requirement: 2.2.1 Core Components/Messaging Service - Message validation
        it('should throw error for invalid message data', async () => {
            // Arrange
            const invalidMessageData = {
                receiverId: 'invalid-id',
                listingId: mockListingId,
                content: '',
                type: 'INVALID_TYPE'
            };

            // Act & Assert
            await expect(messageService.createMessage(invalidMessageData, mockSenderId))
                .rejects
                .toThrow('Invalid message data');
        });
    });

    describe('getMessageThread', () => {
        // Requirement: 2.2.1 Core Components/Messaging Service - Message thread management
        it('should retrieve message thread between users for a listing', async () => {
            // Arrange
            const testMessages = [
                new Message({
                    senderId: mockSenderId,
                    receiverId: mockReceiverId,
                    listingId: mockListingId,
                    content: 'Message 1',
                    type: MessageType.TEXT,
                    status: MessageStatus.SENT,
                    threadId: mockThreadId,
                    createdAt: new Date()
                }),
                new Message({
                    senderId: mockReceiverId,
                    receiverId: mockSenderId,
                    listingId: mockListingId,
                    content: 'Message 2',
                    type: MessageType.TEXT,
                    status: MessageStatus.SENT,
                    threadId: mockThreadId,
                    createdAt: new Date(Date.now() + 1000)
                })
            ];

            await mongoose.model('Message').create(testMessages);

            // Act
            const result = await messageService.getMessageThread(mockListingId, mockSenderId, {
                page: 1,
                limit: 10,
                sortOrder: 'desc'
            });

            // Assert
            expect(result).toHaveLength(2);
            expect(result[0].content).toBe('Message 2');
            expect(result[1].content).toBe('Message 1');
            expect(result[0].threadId).toBe(mockThreadId);
            expect(result[1].threadId).toBe(mockThreadId);
        });

        // Requirement: 2.2.1 Core Components/Messaging Service - Message pagination
        it('should handle pagination correctly', async () => {
            // Arrange
            const messages = Array.from({ length: 15 }, (_, i) => new Message({
                senderId: mockSenderId,
                receiverId: mockReceiverId,
                listingId: mockListingId,
                content: `Message ${i + 1}`,
                type: MessageType.TEXT,
                status: MessageStatus.SENT,
                threadId: mockThreadId,
                createdAt: new Date(Date.now() + i * 1000)
            }));

            await mongoose.model('Message').create(messages);

            // Act
            const page1 = await messageService.getMessageThread(mockListingId, mockSenderId, {
                page: 1,
                limit: 10,
                sortOrder: 'desc'
            });

            const page2 = await messageService.getMessageThread(mockListingId, mockSenderId, {
                page: 2,
                limit: 10,
                sortOrder: 'desc'
            });

            // Assert
            expect(page1).toHaveLength(10);
            expect(page2).toHaveLength(5);
        });
    });

    describe('markMessageAsRead', () => {
        // Requirement: 2.2.1 Core Components/Messaging Service - Message status tracking
        it('should update message status to read', async () => {
            // Arrange
            const message = await mongoose.model('Message').create(new Message({
                senderId: mockSenderId,
                receiverId: mockReceiverId,
                listingId: mockListingId,
                content: 'Test message',
                type: MessageType.TEXT,
                status: MessageStatus.DELIVERED,
                threadId: mockThreadId
            }));

            // Act
            await messageService.markMessageAsRead(message.id, mockReceiverId);

            // Assert
            const updatedMessage = await mongoose.model('Message').findById(message.id);
            expect(updatedMessage?.status).toBe(MessageStatus.READ);
            expect(updatedMessage?.readAt).toBeDefined();

            // Verify read receipt notification
            expect(mockSocketManager.sendMessage).toHaveBeenCalledWith({
                senderId: mockReceiverId,
                receiverId: mockSenderId,
                listingId: mockListingId,
                content: 'Message read',
                type: MessageType.SYSTEM,
                threadId: mockThreadId
            }, mockThreadId);
        });

        it('should throw error when unauthorized user tries to mark message as read', async () => {
            // Arrange
            const message = await mongoose.model('Message').create(new Message({
                senderId: mockSenderId,
                receiverId: mockReceiverId,
                listingId: mockListingId,
                content: 'Test message',
                type: MessageType.TEXT,
                status: MessageStatus.DELIVERED,
                threadId: mockThreadId
            }));

            // Act & Assert
            await expect(messageService.markMessageAsRead(message.id, mockSenderId))
                .rejects
                .toThrow('Unauthorized to mark message as read');
        });
    });

    describe('deleteMessage', () => {
        // Requirement: 2.2.1 Core Components/Messaging Service - Message lifecycle management
        it('should soft delete a message', async () => {
            // Arrange
            const message = await mongoose.model('Message').create(new Message({
                senderId: mockSenderId,
                receiverId: mockReceiverId,
                listingId: mockListingId,
                content: 'Test message',
                type: MessageType.TEXT,
                status: MessageStatus.SENT,
                threadId: mockThreadId
            }));

            // Act
            const result = await messageService.deleteMessage(message.id, mockSenderId);

            // Assert
            expect(result).toBe(true);
            const deletedMessage = await mongoose.model('Message').findById(message.id);
            expect(deletedMessage?.isDeleted).toBe(true);
            expect(deletedMessage?.deletedAt).toBeDefined();
            expect(deletedMessage?.deletedBy).toBe(mockSenderId);

            // Verify deletion notification
            expect(mockSocketManager.sendMessage).toHaveBeenCalledWith({
                senderId: mockSenderId,
                receiverId: mockReceiverId,
                listingId: mockListingId,
                content: 'Message deleted',
                type: MessageType.SYSTEM,
                threadId: mockThreadId
            }, mockThreadId);
        });

        it('should throw error when unauthorized user tries to delete message', async () => {
            // Arrange
            const message = await mongoose.model('Message').create(new Message({
                senderId: mockSenderId,
                receiverId: mockReceiverId,
                listingId: mockListingId,
                content: 'Test message',
                type: MessageType.TEXT,
                status: MessageStatus.SENT,
                threadId: mockThreadId
            }));

            const unauthorizedUserId = new mongoose.Types.ObjectId().toString();

            // Act & Assert
            await expect(messageService.deleteMessage(message.id, unauthorizedUserId))
                .rejects
                .toThrow('Unauthorized to delete message');
        });
    });
});