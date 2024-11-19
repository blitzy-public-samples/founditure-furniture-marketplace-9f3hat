// External dependencies
import express from 'express'; // v4.18.0
import cors from 'cors'; // v2.8.0
import helmet from 'helmet'; // v7.0.0
import compression from 'compression'; // v1.7.0
import mongoose from 'mongoose'; // v7.0.0
import { injectable, inject } from 'inversify'; // v6.0.0
import * as promClient from 'prom-client'; // v14.2.0

// Internal dependencies
import { config } from './config';
import { AnalyticsController } from './controllers/analytics.controller';
import { Logger } from '../../shared/utils/logger';
import { errorHandler, notFoundHandler } from '../../shared/middleware/error.middleware';
import { requestLoggingMiddleware } from '../../shared/middleware/logging.middleware';

/**
 * Human Tasks:
 * 1. Configure MongoDB connection string in environment variables
 * 2. Set up Prometheus server endpoint and scraping interval
 * 3. Configure CORS policy for production environment
 * 4. Set up ELK Stack endpoints for log shipping
 * 5. Configure rate limiting and request throttling
 */

@injectable()
export class App {
  private express: express.Application;
  private readonly port: number;
  private readonly logger: Logger;
  private readonly analyticsController: AnalyticsController;

  constructor(
    @inject(AnalyticsController) analyticsController: AnalyticsController
  ) {
    this.express = express();
    this.port = config.port;
    this.logger = new Logger('AnalyticsService');
    this.analyticsController = analyticsController;

    this.initializeMiddleware();
    this.initializeRoutes();
    this.initializeMetrics();
  }

  /**
   * Initializes application middleware
   * Requirement: 2.4 Cross-Cutting Concerns - System Monitoring
   */
  private initializeMiddleware(): void {
    // Security middleware
    this.express.use(helmet());
    
    // CORS configuration
    this.express.use(cors({
      origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
      methods: ['GET', 'POST', 'PUT', 'DELETE'],
      allowedHeaders: ['Content-Type', 'Authorization'],
      credentials: true,
      maxAge: 86400 // 24 hours
    }));

    // Request compression
    this.express.use(compression());

    // Body parsing
    this.express.use(express.json({ limit: '10mb' }));
    this.express.use(express.urlencoded({ extended: true, limit: '10mb' }));

    // Request logging
    this.express.use(requestLoggingMiddleware);
  }

  /**
   * Initializes application routes
   * Requirement: 2.4.1 System Monitoring - Component Details
   */
  private initializeRoutes(): void {
    // Health check endpoint
    this.express.get('/health', (req, res) => {
      res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'analytics-service'
      });
    });

    // Metrics endpoint for Prometheus
    this.express.get('/metrics', async (req, res) => {
      try {
        res.set('Content-Type', promClient.register.contentType);
        res.end(await promClient.register.metrics());
      } catch (error) {
        this.logger.error('Error generating metrics', error as Error);
        res.status(500).end();
      }
    });

    // Analytics routes
    this.express.post('/api/analytics/user-activity', 
      (req, res) => this.analyticsController.trackUserActivity(req, res));
    this.express.post('/api/analytics/furniture-recovery', 
      (req, res) => this.analyticsController.trackFurnitureRecovery(req, res));
    this.express.get('/api/analytics/report', 
      (req, res) => this.analyticsController.getAnalyticsReport(req, res));
    this.express.get('/api/analytics/community', 
      (req, res) => this.analyticsController.getCommunityMetrics(req, res));

    // Error handling
    this.express.use(notFoundHandler);
    this.express.use(errorHandler);
  }

  /**
   * Initializes Prometheus metrics collection
   * Requirement: Success Criteria Tracking - Track user adoption and furniture recovery
   */
  private initializeMetrics(): void {
    // Clear default metrics and register custom ones
    promClient.register.clear();

    // Enable default metrics
    promClient.collectDefaultMetrics({
      prefix: 'founditure_analytics_',
      labels: { service: 'analytics-service' }
    });

    // Custom metrics for success criteria tracking
    new promClient.Counter({
      name: 'founditure_user_registrations_total',
      help: 'Total number of user registrations'
    });

    new promClient.Gauge({
      name: 'founditure_active_users',
      help: 'Current number of active users'
    });

    new promClient.Counter({
      name: 'founditure_furniture_items_recovered',
      help: 'Total number of furniture items recovered'
    });

    this.logger.info('Metrics collection initialized');
  }

  /**
   * Starts the Express server and initializes MongoDB connection
   * Requirement: Cross-Cutting Concerns - System Monitoring
   */
  public async listen(): Promise<void> {
    try {
      // Connect to MongoDB
      await mongoose.connect(config.mongodb.uri, config.mongodb.options);
      this.logger.info('Connected to MongoDB');

      // Start server
      this.express.listen(this.port, () => {
        this.logger.info(`Analytics service listening on port ${this.port}`);
        this.logger.info(`Environment: ${config.env}`);
      });
    } catch (error) {
      this.logger.error('Failed to start analytics service', error as Error);
      process.exit(1);
    }

    // Graceful shutdown handling
    process.on('SIGTERM', async () => {
      this.logger.info('SIGTERM received, initiating graceful shutdown');
      
      try {
        await mongoose.connection.close();
        this.logger.info('MongoDB connection closed');
        process.exit(0);
      } catch (error) {
        this.logger.error('Error during graceful shutdown', error as Error);
        process.exit(1);
      }
    });
  }
}

/**
 * Bootstrap function to start the application
 * Requirement: 2.4.1 System Monitoring - Component Details
 */
export async function bootstrap(): Promise<void> {
  try {
    const app = new App(new AnalyticsController(new Logger('AnalyticsController')));
    await app.listen();
  } catch (error) {
    console.error('Failed to bootstrap application:', error);
    process.exit(1);
  }
}