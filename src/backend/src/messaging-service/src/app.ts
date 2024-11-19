// External dependencies
import express from 'express'; // v4.18.0
import cors from 'cors'; // v2.8.5
import helmet from 'helmet'; // v7.0.0
import compression from 'compression'; // v1.7.4
import morgan from 'morgan'; // v1.10.0
import { createServer } from 'http';

// Internal dependencies
import { config, logger } from './config';
import { MessageController } from './controllers/message.controller';
import { SocketManager } from './utils/socket.util';

/**
 * Human Tasks:
 * 1. Configure Redis cluster settings in environment variables
 * 2. Set up SSL/TLS certificates for WebSocket connections
 * 3. Configure proper CORS settings for allowed origins
 * 4. Set up monitoring for WebSocket connections and events
 * 5. Configure proper authentication middleware and token validation
 */

/**
 * Main application class that initializes Express server and WebSocket connections
 * Requirement: 2.2.1 Core Components/Messaging Service - WebSocket and Redis-based cluster deployment
 */
export class App {
    private app: express.Application;
    private server: http.Server;
    private socketManager: SocketManager;
    private messageController: MessageController;

    constructor() {
        this.app = express();
        this.server = createServer(this.app);
        this.messageController = new MessageController();
        
        // Initialize middleware stack
        this.initializeMiddleware();
        
        // Initialize WebSocket manager with Redis adapter
        this.socketManager = SocketManager.getInstance(this.server, {
            host: config.redis.host,
            port: config.redis.port,
            password: config.redis.password,
            db: config.redis.db
        });
        
        // Initialize routes
        this.initializeRoutes();
    }

    /**
     * Sets up Express middleware stack with security and monitoring features
     * Requirement: 2.4.1 System Monitoring - Integration with centralized logging
     */
    private initializeMiddleware(): void {
        // Security middleware
        this.app.use(helmet({
            contentSecurityPolicy: {
                directives: {
                    defaultSrc: ["'self'"],
                    connectSrc: ["'self'", 'wss:', 'https:'],
                    imgSrc: ["'self'", 'data:', 'https:'],
                    scriptSrc: ["'self'"],
                    styleSrc: ["'self'", "'unsafe-inline'"]
                }
            },
            crossOriginEmbedderPolicy: true,
            crossOriginOpenerPolicy: true,
            crossOriginResourcePolicy: { policy: "cross-origin" }
        }));

        // CORS configuration
        this.app.use(cors({
            origin: process.env.CORS_ORIGIN?.split(',') || '*',
            methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
            allowedHeaders: ['Content-Type', 'Authorization'],
            credentials: true,
            maxAge: 86400 // 24 hours
        }));

        // Compression middleware
        this.app.use(compression({
            level: 6,
            threshold: 100 * 1024 // 100kb
        }));

        // Request parsing
        this.app.use(express.json({ limit: '1mb' }));
        this.app.use(express.urlencoded({ extended: true, limit: '1mb' }));

        // Logging middleware
        this.app.use(morgan('combined', {
            stream: {
                write: (message: string) => {
                    logger.info(message.trim());
                }
            }
        }));

        // Health check endpoint
        this.app.get('/health', (req, res) => {
            res.status(200).json({
                status: 'healthy',
                timestamp: new Date().toISOString(),
                environment: config.env
            });
        });
    }

    /**
     * Configures API routes with validation and error handling
     * Requirement: 1.2 System Overview/Core Features - Real-time messaging between users
     */
    private initializeRoutes(): void {
        // API version prefix
        const apiPrefix = '/api/v1';

        // Message routes
        this.app.post(`${apiPrefix}/messages`, this.messageController.create);
        this.app.get(`${apiPrefix}/messages/thread/:listingId`, this.messageController.getThread);
        this.app.put(`${apiPrefix}/messages/:messageId/read`, this.messageController.markAsRead);
        this.app.delete(`${apiPrefix}/messages/:messageId`, this.messageController.delete);

        // 404 handler
        this.app.use((req, res) => {
            res.status(404).json({
                success: false,
                status: 404,
                message: 'Resource not found',
                path: req.path
            });
        });

        // Error handler
        this.app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
            logger.error('Unhandled error:', err);
            res.status(500).json({
                success: false,
                status: 500,
                message: 'Internal server error',
                error: process.env.NODE_ENV === 'development' ? err.message : undefined
            });
        });
    }

    /**
     * Starts the HTTP and WebSocket servers
     * Requirement: 2.2.1 Core Components/Messaging Service - WebSocket and Redis-based cluster deployment
     */
    public async listen(): Promise<void> {
        try {
            // Start HTTP server
            this.server.listen(config.port, () => {
                logger.info(`Messaging service started on port ${config.port} in ${config.env} mode`);
                logger.info(`WebSocket server available at ws://localhost:${config.port}${config.socket.path}`);
            });

            // Graceful shutdown handler
            process.on('SIGTERM', () => {
                logger.info('SIGTERM received. Starting graceful shutdown...');
                this.server.close(() => {
                    logger.info('HTTP server closed');
                    process.exit(0);
                });
            });

        } catch (error) {
            logger.error('Failed to start server:', error);
            process.exit(1);
        }
    }
}

export default App;