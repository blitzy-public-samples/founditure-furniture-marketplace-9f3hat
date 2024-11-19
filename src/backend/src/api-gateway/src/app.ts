// External dependencies
import express, { Express, Request, Response, NextFunction } from 'express'; // v4.18.0
import helmet from 'helmet'; // v7.0.0
import cors from 'cors'; // v2.8.5
import compression from 'compression'; // v1.7.4
import morgan from 'morgan'; // v1.10.0
import { RedisClient } from 'redis'; // v4.6.0

// Internal dependencies
import { authenticate, authorize } from './middleware/auth.middleware';
import { createRateLimiter } from './middleware/rateLimit.middleware';
import { validateRequest } from './middleware/validation.middleware';
import router from './routes';
import { BaseError, formatError } from '../../shared/utils/error';

/**
 * Human Tasks:
 * 1. Configure Redis connection settings in environment variables
 * 2. Set up monitoring and alerting for API Gateway metrics
 * 3. Configure proper CORS settings for production environment
 * 4. Set up logging infrastructure and log aggregation
 * 5. Configure rate limiting thresholds based on load testing
 * 6. Set up proper security headers for production
 */

// Initialize Express application
const app: Express = express();

// Requirement: 2.1 High-Level Architecture/Component Details - API Gateway configuration
async function initializeMiddleware(app: Express): Promise<void> {
  // Requirement: 2.5 Security Architecture/Security Controls - Security headers
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "'unsafe-inline'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:', 'https:'],
        connectSrc: ["'self'"],
        fontSrc: ["'self'"],
        objectSrc: ["'none'"],
        mediaSrc: ["'self'"],
        frameSrc: ["'none'"],
      },
    },
    crossOriginEmbedderPolicy: true,
    crossOriginOpenerPolicy: true,
    crossOriginResourcePolicy: { policy: "same-site" },
    dnsPrefetchControl: true,
    frameguard: { action: 'deny' },
    hidePoweredBy: true,
    hsts: true,
    ieNoOpen: true,
    noSniff: true,
    referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
    xssFilter: true
  }));

  // Requirement: 2.5 Security Architecture/Security Controls - CORS configuration
  app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    exposedHeaders: ['X-Total-Count'],
    credentials: true,
    maxAge: 86400 // 24 hours
  }));

  // Request parsing middleware
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // Requirement: 2.4 Cross-Cutting Concerns/System Monitoring - Response compression
  app.use(compression());

  // Requirement: 2.4 Cross-Cutting Concerns/System Monitoring - Request logging
  app.use(morgan('combined', {
    skip: (req) => req.path === '/health' || req.path === '/metrics'
  }));

  // Initialize Redis client for rate limiting
  const redisClient = new RedisClient({
    url: process.env.REDIS_URL || 'redis://localhost:6379',
    password: process.env.REDIS_PASSWORD,
    retry_strategy: (options) => Math.min(options.attempt * 100, 3000)
  });

  // Requirement: 2.5 Security Architecture/Security Controls - Rate limiting
  app.use(createRateLimiter(redisClient));
}

// Requirement: 2.1 High-Level Architecture/Component Details - API routes configuration
async function initializeRoutes(app: Express): Promise<void> {
  // Mount main API router
  app.use('/api/v1', router);

  // Health check endpoint
  app.get('/health', (req: Request, res: Response) => {
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    });
  });

  // 404 handler for undefined routes
  app.use((req: Request, res: Response) => {
    res.status(404).json({
      success: false,
      message: 'Resource not found',
      path: req.path
    });
  });

  // Global error handling middleware
  app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    console.error('Unhandled error:', err);
    
    const formattedError = formatError(err);
    const statusCode = err instanceof BaseError ? err.statusCode : 500;

    res.status(statusCode).json(formattedError);
  });
}

// Requirement: 2.1 High-Level Architecture/Component Details - Server initialization
async function startServer(): Promise<void> {
  try {
    // Initialize all middleware
    await initializeMiddleware(app);

    // Initialize routes and error handlers
    await initializeRoutes(app);

    // Start server
    const port = process.env.PORT || 3000;
    app.listen(port, () => {
      console.log(`API Gateway listening on port ${port}`);
    });
  } catch (error) {
    console.error('Failed to start API Gateway:', error);
    process.exit(1);
  }
}

// Start the server
startServer();

// Export app instance for testing
export { app };