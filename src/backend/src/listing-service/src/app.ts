// External dependencies
import express from 'express'; // v4.18.0
import cors from 'cors'; // v2.8.0
import helmet from 'helmet'; // v7.0.0
import mongoose from 'mongoose'; // v7.0.0
import compression from 'compression'; // v1.7.0

// Internal dependencies
import { config } from './config';
import { ListingController } from './controllers/listing.controller';
import { errorHandler } from '../../shared/middleware/error.middleware';
import { requestLoggingMiddleware } from '../../shared/middleware/logging.middleware';
import { Logger } from '../../shared/utils/logger';

/**
 * Human Tasks:
 * 1. Configure MongoDB cluster and obtain connection string
 * 2. Set up rate limiting rules in API Gateway
 * 3. Configure CORS allowed origins for production
 * 4. Set up monitoring and alerting thresholds
 * 5. Configure SSL/TLS certificates for HTTPS
 */

// Initialize Express application
const app = express();

// Initialize logger
const logger = new Logger('ListingService');

/**
 * Initializes common Express middleware for the application
 * Requirement: 3.3.1 API Architecture - REST/HTTP/2 with JWT authentication
 */
const initializeMiddleware = (): void => {
  // Enable CORS with credentials
  app.use(cors({
    origin: true,
    credentials: true
  }));

  // Add security headers
  app.use(helmet());

  // Enable gzip compression
  app.use(compression());

  // Parse JSON payloads
  app.use(express.json({ limit: '10mb' }));

  // Parse URL-encoded bodies
  app.use(express.urlencoded({ 
    extended: true,
    limit: '10mb'
  }));

  // Add request logging
  app.use(requestLoggingMiddleware);
};

/**
 * Initializes API route controllers
 * Requirement: Core Features - Location-based furniture discovery
 */
const initializeControllers = (): void => {
  // Create listing controller instance
  const listingController = new ListingController();

  // Register listing routes
  app.use('/api/v1/listings', listingController);

  // Add 404 handler for undefined routes
  app.use((req, res) => {
    res.status(404).json({
      success: false,
      message: `Route ${req.originalUrl} not found`
    });
  });

  // Add global error handler
  app.use(errorHandler);
};

/**
 * Establishes connection to MongoDB database
 * Requirement: 2.2.1 Core Components - Microservices architecture with Node.js
 */
const initializeDatabaseConnection = async (): Promise<void> => {
  try {
    await mongoose.connect(config.mongoUri, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });

    mongoose.connection.on('connected', () => {
      logger.info('Connected to MongoDB database');
    });

    mongoose.connection.on('error', (error) => {
      logger.error('MongoDB connection error', error);
      process.exit(1);
    });

    mongoose.connection.on('disconnected', () => {
      logger.warn('MongoDB connection disconnected');
    });
  } catch (error) {
    logger.error('Failed to connect to MongoDB', error);
    process.exit(1);
  }
};

/**
 * Starts the Express application server
 * Requirement: 2.2.1 Core Components - Microservices architecture with Node.js
 */
const startServer = async (): Promise<void> => {
  try {
    // Initialize database connection
    await initializeDatabaseConnection();

    // Initialize middleware stack
    initializeMiddleware();

    // Initialize controllers and routes
    initializeControllers();

    // Start HTTP server
    app.listen(config.port, () => {
      logger.info(`Listing Service started on port ${config.port}`);
    });

    // Handle graceful shutdown
    process.on('SIGTERM', () => {
      logger.info('SIGTERM received, shutting down gracefully');
      mongoose.connection.close();
      process.exit(0);
    });
  } catch (error) {
    logger.error('Failed to start server', error);
    process.exit(1);
  }
};

// Start server if running directly
if (require.main === module) {
  startServer();
}

// Export app instance for testing
export { app };