// External dependencies
import { Server, Socket } from 'socket.io'; // v4.7.0
import { createAdapter } from '@socket.io/redis-adapter'; // v8.2.1
import { createClient, RedisClientType } from 'redis'; // v4.6.0
import { Server as HttpServer } from 'http';

// Internal dependencies
import { Message, MessageType, MessageStatus } from '../models/message.model';

/**
 * Human Tasks:
 * 1. Configure Redis cluster settings in environment variables
 * 2. Set up proper SSL/TLS certificates for WebSocket connections
 * 3. Configure proper CORS settings for allowed origins
 * 4. Set up monitoring for WebSocket connections and events
 * 5. Configure proper authentication middleware and token validation
 */

/**
 * Interface for socket message payload
 * Requirement: 2.2.1 Core Components/Messaging Service - Real-time communication
 */
export interface SocketMessage {
    senderId: string;
    receiverId: string;
    listingId: string;
    content: string;
    type: MessageType;
    threadId: string;
}

/**
 * Interface for socket room management
 * Requirement: 2.2.1 Core Components/Messaging Service - Real-time communication
 */
export interface SocketRoom {
    roomId: string;
    participants: string[];
    listingId: string;
    createdAt: Date;
    isActive: boolean;
}

/**
 * Singleton class for managing WebSocket connections and message handling
 * Requirement: 2.2.1 Core Components/Messaging Service - Real-time communication using WebSocket and Redis
 */
export class SocketManager {
    private static instance: SocketManager;
    private io: Server;
    private redisClient: RedisClientType;
    private activeRooms: Map<string, SocketRoom>;
    private userSocketMap: Map<string, string>;

    private constructor(httpServer: HttpServer, redisConfig: any) {
        // Initialize Socket.IO with CORS and authentication settings
        this.io = new Server(httpServer, {
            cors: {
                origin: process.env.ALLOWED_ORIGINS?.split(',') || [],
                methods: ['GET', 'POST'],
                credentials: true
            },
            pingTimeout: 60000,
            pingInterval: 25000
        });

        // Initialize Redis client for pub/sub
        this.redisClient = createClient(redisConfig);
        this.redisClient.connect().catch(err => {
            console.error('Redis connection error:', err);
        });

        // Configure Redis adapter for Socket.IO clustering
        const pubClient = this.redisClient.duplicate();
        const subClient = this.redisClient.duplicate();

        Promise.all([pubClient.connect(), subClient.connect()]).then(() => {
            this.io.adapter(createAdapter(pubClient, subClient));
        });

        // Initialize maps for room and user socket management
        this.activeRooms = new Map<string, SocketRoom>();
        this.userSocketMap = new Map<string, string>();

        // Set up connection handling
        this.io.on('connection', this.handleConnection.bind(this));

        // Set up error handlers
        this.io.on('error', (error: Error) => {
            console.error('Socket.IO error:', error);
        });
    }

    /**
     * Get singleton instance
     */
    public static getInstance(httpServer: HttpServer, redisConfig: any): SocketManager {
        if (!SocketManager.instance) {
            SocketManager.instance = new SocketManager(httpServer, redisConfig);
        }
        return SocketManager.instance;
    }

    /**
     * Handle new socket connections with authentication
     * Requirement: 2.2.1 Core Components/Messaging Service - Real-time communication
     */
    public async handleConnection(socket: Socket): Promise<void> {
        try {
            // Verify authentication token
            const token = socket.handshake.auth.token;
            if (!token) {
                throw new Error('Authentication required');
            }

            const userId = await this.verifyToken(token);
            if (!userId) {
                throw new Error('Invalid token');
            }

            // Add user to socket map
            this.userSocketMap.set(userId, socket.id);
            socket.data.userId = userId;

            // Join user's personal room
            socket.join(`user:${userId}`);

            // Set up message event handlers
            socket.on('message', async (message: SocketMessage) => {
                try {
                    const roomId = await this.createRoom({
                        roomId: `${message.threadId}`,
                        participants: [message.senderId, message.receiverId],
                        listingId: message.listingId,
                        createdAt: new Date(),
                        isActive: true
                    });
                    await this.sendMessage(message, roomId);
                } catch (error) {
                    console.error('Message handling error:', error);
                    socket.emit('error', { message: 'Failed to send message' });
                }
            });

            // Set up typing event handlers
            socket.on('typing', (data: { roomId: string; isTyping: boolean }) => {
                socket.to(data.roomId).emit('userTyping', {
                    userId: socket.data.userId,
                    isTyping: data.isTyping
                });
            });

            // Set up read receipt handlers
            socket.on('messageRead', async (messageId: string) => {
                try {
                    const message = new Message({ id: messageId });
                    await message.markAsRead();
                    socket.to(`user:${message.senderId}`).emit('messageStatus', {
                        messageId,
                        status: MessageStatus.READ
                    });
                } catch (error) {
                    console.error('Read receipt error:', error);
                }
            });

            // Handle disconnection
            socket.on('disconnect', () => {
                this.handleDisconnection(socket);
            });

        } catch (error) {
            console.error('Connection handling error:', error);
            socket.disconnect(true);
        }
    }

    /**
     * Handle socket disconnections and cleanup
     * Requirement: 2.2.1 Core Components/Messaging Service - Real-time communication
     */
    private handleDisconnection(socket: Socket): void {
        try {
            const userId = socket.data.userId;
            if (userId) {
                // Remove user from socket map
                this.userSocketMap.delete(userId);

                // Notify other participants in shared rooms
                this.io.emit('userOffline', { userId });

                // Clean up room data if empty
                this.activeRooms.forEach((room, roomId) => {
                    if (room.participants.includes(userId)) {
                        const remainingParticipants = room.participants.filter(p => p !== userId);
                        if (remainingParticipants.length === 0) {
                            this.activeRooms.delete(roomId);
                        }
                    }
                });
            }
        } catch (error) {
            console.error('Disconnection handling error:', error);
        }
    }

    /**
     * Create a new chat room with Redis persistence
     * Requirement: 2.2.1 Core Components/Messaging Service - Real-time communication
     */
    public async createRoom(roomData: SocketRoom): Promise<string> {
        try {
            // Validate participant IDs
            if (!roomData.participants || roomData.participants.length < 2) {
                throw new Error('Invalid room participants');
            }

            // Store room data in Redis
            const roomKey = `room:${roomData.roomId}`;
            await this.redisClient.hSet(roomKey, {
                ...roomData,
                participants: JSON.stringify(roomData.participants),
                createdAt: roomData.createdAt.toISOString()
            });

            // Add to active rooms map
            this.activeRooms.set(roomData.roomId, roomData);

            // Add participants to room
            roomData.participants.forEach(participantId => {
                const socketId = this.userSocketMap.get(participantId);
                if (socketId) {
                    this.io.sockets.sockets.get(socketId)?.join(roomData.roomId);
                }
            });

            // Notify participants
            this.io.to(roomData.roomId).emit('roomCreated', {
                roomId: roomData.roomId,
                participants: roomData.participants
            });

            return roomData.roomId;
        } catch (error) {
            console.error('Room creation error:', error);
            throw error;
        }
    }

    /**
     * Send a message to a room with delivery tracking
     * Requirement: 2.2.1 Core Components/Messaging Service - Real-time communication
     */
    public async sendMessage(message: SocketMessage, roomId: string): Promise<void> {
        try {
            // Validate message data and room existence
            if (!this.activeRooms.has(roomId)) {
                throw new Error('Invalid room ID');
            }

            // Create Message instance
            const newMessage = new Message({
                senderId: message.senderId,
                receiverId: message.receiverId,
                listingId: message.listingId,
                content: message.content,
                type: message.type,
                threadId: message.threadId,
                status: MessageStatus.SENT
            });

            // Emit to room participants
            this.io.to(roomId).emit('message', {
                ...message,
                messageId: newMessage.id,
                timestamp: new Date()
            });

            // Handle delivery status
            const receiverSocket = this.userSocketMap.get(message.receiverId);
            if (receiverSocket) {
                await newMessage.markAsDelivered();
                this.io.to(`user:${message.senderId}`).emit('messageStatus', {
                    messageId: newMessage.id,
                    status: MessageStatus.DELIVERED
                });
            }
        } catch (error) {
            console.error('Message sending error:', error);
            throw error;
        }
    }

    /**
     * Verify authentication token
     * @private
     */
    private async verifyToken(token: string): Promise<string | null> {
        try {
            // Token verification logic should be implemented based on your authentication system
            // This is a placeholder that should be replaced with actual token verification
            return token.split(':')[1] || null;
        } catch (error) {
            console.error('Token verification error:', error);
            return null;
        }
    }
}