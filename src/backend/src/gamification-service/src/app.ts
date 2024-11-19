// External dependencies
import express from 'express'; // v4.18.0
import mongoose from 'mongoose'; // v7.0.0
import cors from 'cors'; // v2.8.5
import helmet from 'helmet'; // v6.0.0
import morgan from 'morgan'; // v1.10.0

// Internal dependencies
import { config } from './config';
import { AchievementController } from './controllers/achievement.controller';
import { PointsController } from './controllers/points.controller';
import { Logger } from '../../shared/utils/logger';
import { formatError } from '../../shared/utils/error';

/**
 * Human Tasks:
 * 1. Configure MongoDB connection string in environment variables
 * 2. Set up CORS configuration for production environment
 * 3. Configure rate limiting and request throttling
 * 4. Set up monitoring and alerting for service health
 * 5. Configure logging infrastructure in production
 */

/**
 * Main application class for the gamification microservice
 * Requirement: Gamification System - User Engagement: 70% monthly active user retention
 * Requirement: Core Components - Core Services with microservices architecture
 */
export class App {
  private app: express.Application;
  private port: number;
  private logger: Logger;
  private achievementController: AchievementController;
  private pointsController: PointsController;

  constructor() {
    this.app = express();
    this.port = config.port;
    this.logger = new Logger('GamificationService');

    // Initialize application
    this.initializeMiddleware();
    this.initializeControllers();
    this.initializeRoutes();
    this.initializeErrorHandling();
  }

  /**
   * Initializes application middleware stack
   * Requirement: Core Components - Core Services with microservices architecture
   */
  private initializeMiddleware(): void {
    // Enable CORS
    this.app.use(cors());

    // Security headers
    this.app.use(helmet());

    // Request parsing
    this.app.use(express.json());
    this.app.use(express.urlencoded({ extended: true }));

    // Request logging
    if (process.env.NODE_ENV !== 'production') {
      this.app.use(morgan('dev'));
    }

    // Health check endpoint
    this.app.get('/health', (req, res) => {
      res.status(200).json({ status: 'healthy' });
    });
  }

  /**
   * Initializes service controllers
   * Requirement: Gamification System - Points and achievements tracking
   */
  private initializeControllers(): void {
    this.achievementController = new AchievementController(/* achievementService */);
    this.pointsController = new PointsController(/* pointsService */);
  }

  /**
   * Configures API routes
   * Requirement: API Gateway - Standardized REST endpoints
   */
  private initializeRoutes(): void {
    const router = express.Router();

    // Achievement routes
    router.post('/achievements', this.achievementController.create);
    router.get('/achievements', this.achievementController.findAll);
    router.get('/achievements/:id', this.achievementController.findById);
    router.get('/users/:userId/achievements', this.achievementController.getUserAchievements);
    router.post('/users/:userId/achievements/:id/progress', this.achievementController.trackProgress);

    // Points routes
    router.post('/points/award', this.pointsController.awardPoints);
    router.get('/users/:userId/points', this.pointsController.getUserPoints);
    router.get('/users/:userId/points/history', this.pointsController.getTransactionHistory);

    // Mount routes under API version prefix
    this.app.use('/api/v1', router);

    // 404 handler
    this.app.use((req, res) => {
      res.status(404).json({
        success: false,
        status: 404,
        message: 'Resource not found'
      });
    });
  }

  /**
   * Configures global error handling
   * Requirement: Error Handling - Centralized error handling
   */
  private initializeErrorHandling(): void {
    this.app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
      this.logger.error('Unhandled error', err);
      const formattedError = formatError(err);
      res.status(formattedError.status).json(formattedError);
    });
  }

  /**
   * Initializes MongoDB database connection
   * Requirement: Data Management Strategy - Consistent data operations
   */
  public async initializeDatabase(): Promise<void> {
    try {
      await mongoose.connect(config.mongodb.uri, config.mongodb.options);
      this.logger.info('Connected to MongoDB');
    } catch (error) {
      this.logger.error('MongoDB connection error', error as Error);
      process.exit(1);
    }
  }

  /**
   * Starts the HTTP server
   * Requirement: Core Components - Core Services with microservices architecture
   */
  public async listen(): Promise<void> {
    try {
      await this.initializeDatabase();
      this.app.listen(this.port, () => {
        this.logger.info(`Gamification service listening on port ${this.port}`);
      });
    } catch (error) {
      this.logger.error('Server startup error', error as Error);
      process.exit(1);
    }
  }
}