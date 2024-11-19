// External dependencies
import winston from 'winston'; // v3.10.0
import DailyRotateFile from 'winston-daily-rotate-file'; // v4.7.1

// Internal dependencies
import { ERROR_MESSAGES } from '../constants';
import { formatError } from './error';

/**
 * Human Tasks:
 * 1. Configure ELK Stack endpoints in production environment
 * 2. Set up log retention policies and storage infrastructure
 * 3. Configure log shipping to centralized logging system
 * 4. Set up log monitoring and alerting thresholds
 * 5. Configure log access permissions and security policies
 */

// Custom log levels with numeric priorities
const LOG_LEVELS = {
  error: 0,
  warn: 1,
  info: 2,
  http: 3,
  debug: 4
};

/**
 * Formats log messages with consistent structure
 * Requirement: 2.4.1 System Monitoring - Centralized log aggregation
 */
const formatLogMessage = (info: any): string => {
  const {
    level,
    message,
    timestamp,
    service,
    requestId,
    ...metadata
  } = info;

  // Format error objects if present
  if (metadata.error) {
    metadata.error = formatError(metadata.error);
  }

  return JSON.stringify({
    timestamp: timestamp || new Date().toISOString(),
    service,
    level,
    message,
    requestId,
    ...metadata
  });
};

/**
 * Creates and configures Winston logger instance
 * Requirement: 2.4 Cross-Cutting Concerns - System-wide logging
 */
const createLogger = (service: string): winston.Logger => {
  // Create Winston logger with custom levels
  const logger = winston.createLogger({
    levels: LOG_LEVELS,
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.errors({ stack: true }),
      winston.format.json()
    )
  });

  // Console transport for development
  if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    }));
  }

  // File rotation transport for production
  const fileRotateTransport = new DailyRotateFile({
    filename: `logs/${service}-%DATE%.log`,
    datePattern: 'YYYY-MM-DD',
    maxSize: '20m',
    maxFiles: '14d',
    zippedArchive: true,
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.json()
    )
  });

  // Handle transport errors
  fileRotateTransport.on('error', (error) => {
    console.error('Error in log transport:', error);
  });

  logger.add(fileRotateTransport);

  // Configure ELK Stack transport in production
  if (process.env.NODE_ENV === 'production' && process.env.ELASTICSEARCH_URL) {
    // Add Elasticsearch transport configuration here
    // This would typically use winston-elasticsearch transport
  }

  return logger;
};

/**
 * Logger class providing structured logging methods
 * Requirement: 5.3.4 Security Monitoring - Log collection and analysis
 */
export class Logger {
  private logger: winston.Logger;
  private service: string;

  constructor(service: string) {
    this.service = service;
    this.logger = createLogger(service);
  }

  error(message: string, error?: Error, metadata: Record<string, any> = {}): void {
    const errorData = error ? formatError(error) : {};
    this.logger.error(message, {
      service: this.service,
      ...errorData,
      ...metadata,
      stack: error?.stack
    });
  }

  warn(message: string, metadata: Record<string, any> = {}): void {
    this.logger.warn(message, {
      service: this.service,
      ...metadata
    });
  }

  info(message: string, metadata: Record<string, any> = {}): void {
    this.logger.info(message, {
      service: this.service,
      ...metadata
    });
  }

  debug(message: string, metadata: Record<string, any> = {}): void {
    this.logger.debug(message, {
      service: this.service,
      ...metadata
    });
  }
}

// Export factory function and Logger class
export { createLogger };