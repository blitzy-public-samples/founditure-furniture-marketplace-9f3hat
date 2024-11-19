/**
 * Human Tasks:
 * 1. Configure environment variables for service ports and hosts
 * 2. Set up Google Maps API credentials in deployment environment
 * 3. Configure monitoring and logging infrastructure
 * 4. Set up rate limiting and security policies at API Gateway
 * 5. Configure CORS settings for allowed origins
 */

// External dependencies
import express from 'express'; // v4.18.0
import cors from 'cors'; // v2.8.0
import helmet from 'helmet'; // v7.0.0
import compression from 'compression'; // v1.7.0
import { Container } from 'inversify'; // v6.0.0
import { InversifyExpressServer } from 'inversify-express-utils'; // v6.4.0

// Internal dependencies
import { service, maps } from './config';
import { LocationController } from './controllers/location.controller';
import { errorHandler } from '../../shared/middleware/error.middleware';
import { requestLoggingMiddleware } from '../../shared/middleware/logging.middleware';
import { Logger } from '../../shared/utils/logger';

// Initialize logger
const logger = new Logger('LocationService');

// Initialize DI container
const container = new Container();

// Create Express application
const app = express();

/**
 * Configures Express middleware stack with security, logging and parsing features
 * Requirements:
 * - System Monitoring - Integration with centralized logging
 * - API Architecture - Security and performance optimizations
 */
function setupMiddleware(): void {
  // Enable CORS with configured options
  app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
    maxAge: 86400 // 24 hours
  }));

  // Add security headers
  app.use(helmet());

  // Enable response compression
  app.use(compression());

  // Parse JSON request bodies
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true }));

  // Add request logging middleware with ELK integration
  app.use(requestLoggingMiddleware);

  // Configure inversify bindings
  container.bind<LocationController>(LocationController).toSelf();
}

/**
 * Configures error handling middleware for standardized error responses
 * Requirements:
 * - Error Handling - Centralized error handling
 * - System Monitoring - Error tracking and logging
 */
function setupErrorHandling(): void {
  // Add 404 handler for undefined routes
  app.use((req, res, next) => {
    const error = new Error(`Route not found: ${req.originalUrl}`);
    error.name = 'NotFoundError';
    next(error);
  });

  // Add global error handling middleware
  app.use(errorHandler);
}

/**
 * Starts the Express server on configured port and host
 * Requirements:
 * - System Monitoring - Service health monitoring
 * - Location-based Discovery - Core service initialization
 */
async function startServer(): Promise<void> {
  try {
    // Create InversifyExpressServer
    const server = new InversifyExpressServer(container, null, {
      rootPath: '/api/v1/locations'
    }, app);

    // Configure middleware and error handling
    setupMiddleware();
    setupErrorHandling();

    // Build and start the server
    const application = server.build();
    application.listen(service.port, service.host, () => {
      logger.info('Location Service started successfully', {
        port: service.port,
        host: service.host,
        environment: service.environment,
        mapsProvider: maps.provider
      });
    });
  } catch (error) {
    logger.error('Failed to start Location Service', error as Error);
    process.exit(1);
  }
}

// Start server if not in test environment
if (process.env.NODE_ENV !== 'test') {
  startServer();
}

// Export app instance for testing
export { app };