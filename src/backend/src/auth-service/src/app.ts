/**
 * Human Tasks:
 * 1. Configure rate limiting settings in production environment
 * 2. Set up monitoring and alerting for authentication service
 * 3. Configure proper SSL/TLS certificates for HTTPS
 * 4. Review and adjust security headers for production
 * 5. Set up proper logging infrastructure in production
 */

// External dependencies
import express from 'express'; // v4.18.0
import cors from 'cors'; // v2.8.0
import helmet from 'helmet'; // v7.0.0
import compression from 'compression'; // v1.7.0
import morgan from 'morgan'; // v1.10.0

// Internal dependencies
import { config } from './config';
import { AuthController } from './controllers/auth.controller';
import { errorHandler, notFoundHandler } from '../../shared/middleware/error.middleware';
import { Logger } from '../../shared/utils/logger';

// Initialize logger
const logger = new Logger('AuthService');

/**
 * Main application class that bootstraps the authentication service
 * Requirement: 5.1.1 Authentication Methods - Implements email/password and social OAuth authentication
 */
export class App {
  public app: express.Application;
  private port: number;

  constructor() {
    this.app = express();
    this.port = config.port;
    
    this.initializeMiddleware();
    this.initializeControllers();
    
    logger.info('Authentication service initialized', {
      port: this.port,
      environment: process.env.NODE_ENV
    });
  }

  /**
   * Configures and sets up Express middleware stack with security controls
   * Requirement: 5.3.2 Security Controls - Input validation, access controls, and encryption
   */
  private initializeMiddleware(): void {
    // Enable CORS with configured options
    this.app.use(cors(config.cors));

    // Set security headers with Helmet
    this.app.use(helmet({
      contentSecurityPolicy: true,
      crossOriginEmbedderPolicy: true,
      crossOriginOpenerPolicy: true,
      crossOriginResourcePolicy: true,
      dnsPrefetchControl: true,
      frameguard: true,
      hidePoweredBy: true,
      hsts: true,
      ieNoOpen: true,
      noSniff: true,
      originAgentCluster: true,
      permittedCrossDomainPolicies: true,
      referrerPolicy: true,
      xssFilter: true
    }));

    // Enable gzip compression
    this.app.use(compression());

    // Configure request logging
    this.app.use(morgan('combined', {
      stream: {
        write: (message: string) => logger.info(message.trim())
      }
    }));

    // Parse JSON bodies with size limit
    this.app.use(express.json({ 
      limit: '10kb'
    }));

    // Parse URL-encoded bodies
    this.app.use(express.urlencoded({ 
      extended: false,
      limit: '10kb'
    }));
  }

  /**
   * Sets up authentication route handlers and error middleware
   * Requirement: 3.3.1 API Architecture - REST/HTTP/2 with JWT + OAuth2 authentication
   */
  private initializeControllers(): void {
    // Initialize auth controller
    const authController = new AuthController();

    // Mount auth routes
    this.app.use('/api/v1/auth', authController);

    // Handle 404 errors
    this.app.use(notFoundHandler);

    // Global error handler
    this.app.use(errorHandler);
  }

  /**
   * Starts the Express server on configured port
   * Requirement: 5.3.2 Security Controls - Secure server configuration
   */
  public async listen(): Promise<void> {
    try {
      this.app.listen(this.port, () => {
        logger.info(`Authentication service listening on port ${this.port}`);
      });
    } catch (error) {
      logger.error('Failed to start authentication service', error);
      process.exit(1);
    }
  }
}

export default App;