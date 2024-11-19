// External dependencies
import dotenv from 'dotenv'; // v16.0.0
import { ServerOptions } from 'socket.io'; // v4.7.0
import { RedisClientOptions } from 'redis'; // v4.6.0

// Internal dependencies
import { createLogger } from '../../shared/utils/logger';
import { ValidationError } from '../../shared/utils/error';

/**
 * Human Tasks:
 * 1. Set up MongoDB replica set and configure connection string
 * 2. Configure Redis cluster and security settings
 * 3. Set up SSL certificates for WebSocket secure connections
 * 4. Configure environment-specific CORS settings
 * 5. Set up monitoring for WebSocket connections and Redis pub/sub
 */

// Load environment variables
dotenv.config();

/**
 * Validates configuration settings and environment variables
 * Requirement: 2.4.1 System Monitoring - Configuration validation
 */
const validateConfig = (): void => {
  const requiredEnvVars = [
    'MONGODB_URI',
    'REDIS_HOST',
    'REDIS_PORT',
    'JWT_SECRET'
  ];

  // Check required environment variables
  for (const envVar of requiredEnvVars) {
    if (!process.env[envVar]) {
      throw new ValidationError(`Missing required environment variable: ${envVar}`);
    }
  }

  // Validate port number
  const port = parseInt(process.env.MESSAGING_SERVICE_PORT || '3004', 10);
  if (isNaN(port) || port < 1024 || port > 65535) {
    throw new ValidationError('Invalid port number. Must be between 1024 and 65535');
  }

  // Validate MongoDB URI format
  const mongodbUriPattern = /^mongodb(\+srv)?:\/\/.+/;
  if (!mongodbUriPattern.test(process.env.MONGODB_URI!)) {
    throw new ValidationError('Invalid MongoDB connection string format');
  }

  // Validate Redis configuration
  const redisPort = parseInt(process.env.REDIS_PORT!, 10);
  if (isNaN(redisPort) || redisPort < 1 || redisPort > 65535) {
    throw new ValidationError('Invalid Redis port number');
  }

  // Validate JWT secret length
  if (process.env.JWT_SECRET!.length < 32) {
    throw new ValidationError('JWT secret must be at least 32 characters long');
  }

  // Validate CORS origin if provided
  if (process.env.CORS_ORIGIN) {
    try {
      new URL(process.env.CORS_ORIGIN);
    } catch {
      throw new ValidationError('Invalid CORS origin URL format');
    }
  }

  // Validate LOG_LEVEL
  const validLogLevels = ['error', 'warn', 'info', 'http', 'debug'];
  const logLevel = process.env.LOG_LEVEL || 'info';
  if (!validLogLevels.includes(logLevel)) {
    throw new ValidationError('Invalid LOG_LEVEL value');
  }
};

// Validate configuration on startup
validateConfig();

/**
 * Configuration object for the messaging service
 * Requirement: 2.2.1 Core Components/Messaging Service - Real-time communication configuration
 */
export const config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.MESSAGING_SERVICE_PORT || '3004', 10),

  // MongoDB configuration
  // Requirement: 2.2.1 Core Components/Data Storage - MongoDB configuration
  mongodb: {
    uri: process.env.MONGODB_URI!,
    options: {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      retryWrites: true
    }
  },

  // Redis configuration for pub/sub and caching
  // Requirement: 2.2.1 Core Components/Messaging Service - Redis pub/sub configuration
  redis: {
    host: process.env.REDIS_HOST!,
    port: parseInt(process.env.REDIS_PORT!, 10),
    password: process.env.REDIS_PASSWORD,
    db: parseInt(process.env.REDIS_DB || '0', 10)
  } as RedisClientOptions,

  // Socket.IO configuration
  // Requirement: 2.2.1 Core Components/Messaging Service - WebSocket configuration
  socket: {
    path: '/socket.io',
    serveClient: false,
    pingInterval: 10000,
    pingTimeout: 5000,
    cookie: false,
    cors: {
      origin: process.env.CORS_ORIGIN,
      methods: ['GET', 'POST'],
      credentials: true
    }
  } as Partial<ServerOptions>,

  // JWT configuration for WebSocket authentication
  jwt: {
    secret: process.env.JWT_SECRET!,
    expiresIn: '24h'
  },

  // Logging configuration
  // Requirement: 2.4.1 System Monitoring - Logging configuration
  logger: {
    service: 'messaging-service',
    level: process.env.LOG_LEVEL || 'info'
  }
};

// Create logger instance for the messaging service
export const logger = createLogger(config.logger.service);