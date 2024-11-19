// External dependencies
import express from 'express'; // v4.18.x
import cors from 'cors'; // v2.8.x
import helmet from 'helmet'; // v7.0.x
import compression from 'compression'; // v1.7.x
import * as admin from 'firebase-admin'; // v11.x

// Internal dependencies
import config from './config';
import { NotificationController } from './controllers/notification.controller';
import { errorHandler, notFoundHandler } from '../../shared/middleware/error.middleware';
import { Logger } from '../../shared/utils/logger';

/**
 * Human Tasks:
 * 1. Configure Firebase Admin SDK credentials in environment variables
 * 2. Set up CORS policy for allowed origins in production
 * 3. Configure rate limiting and request throttling at API Gateway
 * 4. Set up monitoring for server health metrics
 * 5. Configure proper security headers for production deployment
 */

// Initialize logger
const logger = new Logger('NotificationService');

/**
 * Main application class for the notification microservice
 * Requirements addressed:
 * - Push Notification System (1.3 Scope/Core Features)
 * - Real-time Messaging (2.2.1 Core Components/Messaging Service)
 * - System Monitoring (2.4.1 System Monitoring)
 */
class App {
  private app: express.Application;
  private port: number;

  constructor() {
    this.app = express();
    this.port = parseInt(process.env.PORT || '3000', 10);

    this.initializeFirebase();
    this.initializeMiddleware();
    this.initializeControllers();
  }

  /**
   * Initializes Firebase Admin SDK with configuration
   * Requirement: Push Notification System - Firebase integration
   */
  private initializeFirebase(): void {
    try {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: config.firebase.projectId,
          clientEmail: config.firebase.clientEmail,
          privateKey: config.firebase.privateKey
        }),
        databaseURL: config.firebase.options.databaseURL,
        storageBucket: config.firebase.options.storageBucket
      });
      logger.info('Firebase Admin SDK initialized successfully');
    } catch (error) {
      logger.error('Failed to initialize Firebase Admin SDK', error);
      throw error;
    }
  }

  /**
   * Sets up Express middleware stack
   * Requirement: System Monitoring - Security and performance middleware
   */
  private initializeMiddleware(): void {
    // Security middleware
    this.app.use(helmet());
    this.app.use(cors({
      origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
      allowedHeaders: ['Content-Type', 'Authorization'],
      credentials: true
    }));

    // Performance middleware
    this.app.use(compression());
    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true }));

    // Request logging
    this.app.use((req, res, next) => {
      logger.info(`Incoming ${req.method} request to ${req.path}`, {
        query: req.query,
        ip: req.ip,
        userAgent: req.get('user-agent')
      });
      next();
    });
  }

  /**
   * Initializes API routes and controllers
   * Requirements:
   * - Push Notification System - Notification endpoints
   * - Real-time Messaging - Message notification support
   */
  private initializeControllers(): void {
    const notificationController = new NotificationController();

    // API routes
    this.app.use('/api/notifications', notificationController.router);

    // Error handling
    this.app.use(notFoundHandler);
    this.app.use(errorHandler);
  }

  /**
   * Starts the Express server
   * Requirement: System Monitoring - Server health logging
   */
  public listen(): void {
    this.app.listen(this.port, () => {
      logger.info(`Notification service listening on port ${this.port}`, {
        port: this.port,
        environment: process.env.NODE_ENV,
        timestamp: new Date().toISOString()
      });
    }).on('error', (error) => {
      logger.error('Failed to start notification service', error);
      process.exit(1);
    });

    // Graceful shutdown handler
    process.on('SIGTERM', () => {
      logger.info('SIGTERM received, initiating graceful shutdown');
      process.exit(0);
    });
  }
}

export default App;