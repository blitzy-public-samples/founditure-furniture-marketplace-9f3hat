// External dependencies
import express from 'express'; // v4.18.0
import cors from 'cors'; // v2.8.0
import helmet from 'helmet'; // v7.0.0
import compression from 'compression'; // v1.7.0

// Internal dependencies
import { config } from './config';
import { RecognitionController } from './controllers/recognition.controller';
import { errorHandler } from '../../shared/middleware/error.middleware';
import { requestLoggingMiddleware } from '../../shared/middleware/logging.middleware';

/**
 * Human Tasks:
 * 1. Configure CORS policy for production environment
 * 2. Set up rate limiting and request throttling at API Gateway
 * 3. Configure compression options based on infrastructure capacity
 * 4. Set up monitoring and alerting for service health metrics
 * 5. Configure security headers based on deployment requirements
 */

// Initialize Express application
const app = express();

/**
 * Initializes and configures Express middleware stack
 * Requirement: AI-powered furniture recognition - Core service configuration
 */
function initializeMiddleware(app: express.Application): void {
  // Enable CORS with security options
  app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
    methods: ['GET', 'POST'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    exposedHeaders: ['X-Request-ID'],
    credentials: true,
    maxAge: 86400 // 24 hours
  }));

  // Add Helmet security headers
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        imgSrc: ["'self'", 'data:', 'https:'],
        scriptSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"]
      }
    },
    crossOriginEmbedderPolicy: true,
    crossOriginOpenerPolicy: true,
    crossOriginResourcePolicy: { policy: "cross-origin" },
    dnsPrefetchControl: true,
    frameguard: { action: 'deny' },
    hidePoweredBy: true,
    hsts: true,
    ieNoOpen: true,
    noSniff: true,
    referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
    xssFilter: true
  }));

  // Enable request compression
  app.use(compression({
    level: 6, // Balanced compression level
    threshold: 1024, // Compress responses larger than 1KB
    filter: (req, res) => {
      if (req.headers['x-no-compression']) {
        return false;
      }
      return compression.filter(req, res);
    }
  }));

  // Add request logging middleware with ELK integration
  app.use(requestLoggingMiddleware);

  // Configure JSON body parser with size limits
  app.use(express.json({
    limit: '10mb',
    strict: true,
    verify: (req, res, buf) => {
      // Store raw body for signature verification if needed
      (req as any).rawBody = buf;
    }
  }));

  // Set up URL-encoded parser with extended mode
  app.use(express.urlencoded({
    extended: true,
    limit: '10mb'
  }));
}

/**
 * Sets up API routes and controllers with error handling
 * Requirement: Image Recognition System - API endpoint configuration
 */
function initializeControllers(app: express.Application): void {
  // Initialize RecognitionController instance
  const recognitionController = new RecognitionController();

  // Mount recognition routes at /api/recognition
  app.post('/api/recognition/analyze', recognitionController.recognize);
  app.post('/api/recognition/moderate', recognitionController.moderate);
  app.get('/api/recognition/:id/history', recognitionController.getRecognitionHistory);

  // Add global error handling middleware
  app.use(errorHandler);

  // Configure 404 handler for undefined routes
  app.use((req, res) => {
    res.status(404).json({
      success: false,
      status: 404,
      message: `Route not found: ${req.originalUrl}`
    });
  });
}

/**
 * Starts the Express server on configured port with graceful shutdown
 * Requirement: AI-powered furniture recognition - Service initialization
 */
async function startServer(app: express.Application): Promise<void> {
  try {
    // Get port from config
    const { port, env, serviceName } = config;

    // Start HTTP server on configured port
    const server = app.listen(port, () => {
      console.log(`${serviceName} is running in ${env} mode on port ${port}`);
    });

    // Configure graceful shutdown handlers
    const shutdown = async () => {
      console.log('Received shutdown signal, closing HTTP server...');
      
      server.close(() => {
        console.log('HTTP server closed successfully');
        process.exit(0);
      });

      // Force close after 10 seconds
      setTimeout(() => {
        console.error('Could not close connections in time, forcefully shutting down');
        process.exit(1);
      }, 10000);
    };

    process.on('SIGTERM', shutdown);
    process.on('SIGINT', shutdown);

  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Initialize application
initializeMiddleware(app);
initializeControllers(app);

// Start server if not in test environment
if (process.env.NODE_ENV !== 'test') {
  startServer(app);
}

// Export app instance for testing
export { app };