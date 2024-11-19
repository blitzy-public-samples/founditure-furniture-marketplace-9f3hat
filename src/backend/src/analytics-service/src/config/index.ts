// External dependencies
import dotenv from 'dotenv'; // v16.3.1
import * as promClient from 'prom-client'; // v14.2.0

// Internal dependencies
import { SERVICE_ENDPOINTS } from '../../../shared/constants';
import { Logger } from '../../../shared/utils/logger';

/**
 * Human Tasks:
 * 1. Configure MongoDB connection string in environment variables
 * 2. Set up Prometheus server endpoint and scraping interval
 * 3. Configure ELK Stack endpoints for log shipping
 * 4. Review and adjust metrics retention periods based on storage capacity
 * 5. Set up alerts and dashboards in monitoring system
 */

// Initialize environment variables
dotenv.config();

// Initialize logger for configuration management
const logger = new Logger('analytics-service-config');

/**
 * Validates MongoDB URI format and connection string
 * @param uri MongoDB connection string
 * @returns boolean indicating if URI is valid
 */
const isValidMongoUri = (uri: string): boolean => {
  const mongoUrlPattern = /^mongodb(\+srv)?:\/\/.+/;
  return mongoUrlPattern.test(uri);
};

/**
 * Validates all required configuration values
 * Requirement: 2.4.1 System Monitoring - Component Details
 */
export const validateConfig = (): void => {
  const requiredEnvVars = ['NODE_ENV', 'ANALYTICS_SERVICE_PORT', 'ANALYTICS_MONGODB_URI'];
  const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);

  if (missingVars.length > 0) {
    const error = `Missing required environment variables: ${missingVars.join(', ')}`;
    logger.error(error);
    throw new Error(error);
  }

  if (!isValidMongoUri(process.env.ANALYTICS_MONGODB_URI!)) {
    const error = 'Invalid MongoDB connection string format';
    logger.error(error);
    throw new Error(error);
  }

  const port = parseInt(process.env.ANALYTICS_SERVICE_PORT || '3005', 10);
  if (isNaN(port) || port <= 0 || port > 65535) {
    const error = 'Invalid port number specified';
    logger.error(error);
    throw new Error(error);
  }

  logger.info('Configuration validation successful');
};

/**
 * Metrics configuration class for Prometheus integration
 * Requirement: 2.4.1 System Monitoring - Metrics collection using Prometheus
 */
export class MetricsConfig {
  private readonly collectionInterval: number;
  private readonly retentionPeriod: number;
  private readonly registry: promClient.Registry;

  constructor(options: { collectionInterval?: number; retentionPeriod?: number }) {
    this.collectionInterval = options.collectionInterval || 15; // seconds
    this.retentionPeriod = options.retentionPeriod || 30; // days
    this.registry = new promClient.Registry();

    // Initialize Prometheus client
    promClient.collectDefaultMetrics({
      register: this.registry,
      prefix: 'founditure_analytics_',
      gcDurationBuckets: [0.001, 0.01, 0.1, 1, 2, 5]
    });

    // Success criteria metrics
    // Requirement: 1.2 System Overview/Success Criteria
    this.initializeCustomMetrics();

    logger.info('Metrics configuration initialized', {
      collectionInterval: this.collectionInterval,
      retentionPeriod: this.retentionPeriod
    });
  }

  private initializeCustomMetrics(): void {
    new promClient.Gauge({
      name: 'founditure_user_adoption_rate',
      help: 'Monthly active user adoption rate',
      registers: [this.registry]
    });

    new promClient.Counter({
      name: 'founditure_furniture_recovery_count',
      help: 'Total number of furniture items recovered',
      registers: [this.registry]
    });

    new promClient.Gauge({
      name: 'founditure_community_growth_rate',
      help: 'Community growth rate percentage',
      registers: [this.registry]
    });
  }

  public getMetricsConfig(): Record<string, any> {
    return {
      collectionInterval: this.collectionInterval,
      retentionPeriod: this.retentionPeriod,
      registry: this.registry
    };
  }
}

/**
 * Load and initialize service configuration
 * Requirement: 3.2.2 Data Management Strategy
 */
export const loadConfig = (): Record<string, any> => {
  validateConfig();

  const config = {
    env: process.env.NODE_ENV || 'development',
    port: parseInt(process.env.ANALYTICS_SERVICE_PORT || '3005', 10),
    mongodb: {
      uri: process.env.ANALYTICS_MONGODB_URI,
      options: {
        useNewUrlParser: true,
        useUnifiedTopology: true,
        retryWrites: true,
        w: 'majority'
      }
    },
    services: {
      auth: SERVICE_ENDPOINTS.AUTH_SERVICE,
      listing: SERVICE_ENDPOINTS.LISTING_SERVICE
    }
  };

  logger.info('Configuration loaded successfully', { env: config.env });
  return config;
};

// Initialize metrics configuration
export const metricsConfig = new MetricsConfig({
  collectionInterval: 15,
  retentionPeriod: 30
});

// Export main configuration object
export const config = loadConfig();