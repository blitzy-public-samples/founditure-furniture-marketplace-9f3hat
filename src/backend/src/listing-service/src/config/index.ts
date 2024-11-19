// External dependencies
import dotenv from 'dotenv'; // v16.0.0
import mongoose from 'mongoose'; // v7.0.0

// Internal dependencies
import { BaseModel } from '../../shared/interfaces/model.interface';
import { VALIDATION_RULES } from '../../shared/constants';

/**
 * Human Tasks:
 * 1. Create .env file with required environment variables
 * 2. Configure AWS credentials in deployment environment
 * 3. Set up MongoDB cluster and obtain connection string
 * 4. Configure service endpoints in deployment environment
 * 5. Review and adjust rate limiting values based on load testing
 */

/**
 * Interface defining the structure of the listing service configuration
 * Requirement: 2.2.1 Core Components - Microservices architecture with Node.js
 */
interface Config {
  port: number;
  mongoUri: string;
  jwtSecret: string;
  environment: string;
  apiVersion: string;
  serviceEndpoints: {
    authService: string;
    messagingService: string;
  };
  aws: {
    accessKeyId: string;
    secretAccessKey: string;
    region: string;
    bucketName: string;
  };
}

/**
 * Validates that all required environment variables are present and correctly formatted
 * Requirement: 2.2.1 Core Components - Microservices architecture with Node.js
 * Requirement: 2.3.2 Data Storage Solutions - MongoDB configuration
 */
const validateConfig = (): void => {
  const requiredEnvVars = [
    'PORT',
    'MONGO_URI',
    'JWT_SECRET',
    'NODE_ENV',
    'API_VERSION',
    'AUTH_SERVICE_URL',
    'MESSAGING_SERVICE_URL',
    'AWS_ACCESS_KEY_ID',
    'AWS_SECRET_ACCESS_KEY',
    'AWS_REGION',
    'AWS_BUCKET_NAME'
  ];

  const missingEnvVars = requiredEnvVars.filter(envVar => !process.env[envVar]);
  if (missingEnvVars.length > 0) {
    throw new Error(`Missing required environment variables: ${missingEnvVars.join(', ')}`);
  }

  // Validate port number
  const port = parseInt(process.env.PORT || '', 10);
  if (isNaN(port) || port < 1024 || port > 65535) {
    throw new Error('PORT must be a number between 1024 and 65535');
  }

  // Validate MongoDB URI format
  try {
    mongoose.Connection.prototype.parseUri(process.env.MONGO_URI || '');
  } catch (error) {
    throw new Error('Invalid MONGO_URI format');
  }

  // Validate API version format
  const apiVersionRegex = /^v\d+$/;
  if (!apiVersionRegex.test(process.env.API_VERSION || '')) {
    throw new Error('API_VERSION must be in format "v1", "v2", etc.');
  }

  // Validate AWS region format
  const awsRegionRegex = /^[a-z]{2}-[a-z]+-\d{1}$/;
  if (!awsRegionRegex.test(process.env.AWS_REGION || '')) {
    throw new Error('Invalid AWS_REGION format');
  }

  // Validate AWS credentials
  if (!process.env.AWS_ACCESS_KEY_ID || !/^[A-Z0-9]{20}$/.test(process.env.AWS_ACCESS_KEY_ID)) {
    throw new Error('Invalid AWS_ACCESS_KEY_ID format');
  }
  if (!process.env.AWS_SECRET_ACCESS_KEY || process.env.AWS_SECRET_ACCESS_KEY.length < 40) {
    throw new Error('Invalid AWS_SECRET_ACCESS_KEY format');
  }
};

/**
 * Loads and validates environment configuration
 * Requirement: 2.2.1 Core Components - Microservices architecture with Node.js
 * Requirement: 3.3.1 API Architecture - REST/HTTP/2 with rate limiting
 */
const loadConfig = (): Config => {
  // Load environment variables
  dotenv.config();

  // Validate configuration
  validateConfig();

  // Construct and return typed configuration object
  return {
    port: parseInt(process.env.PORT || '3000', 10),
    mongoUri: process.env.MONGO_URI as string,
    jwtSecret: process.env.JWT_SECRET as string,
    environment: process.env.NODE_ENV as string,
    apiVersion: process.env.API_VERSION as string,
    serviceEndpoints: {
      authService: process.env.AUTH_SERVICE_URL as string,
      messagingService: process.env.MESSAGING_SERVICE_URL as string
    },
    aws: {
      accessKeyId: process.env.AWS_ACCESS_KEY_ID as string,
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY as string,
      region: process.env.AWS_REGION as string,
      bucketName: process.env.AWS_BUCKET_NAME as string
    }
  };
};

/**
 * Exported configuration object
 * Requirement: 2.2.1 Core Components - Microservices architecture with Node.js
 * Requirement: 2.3.2 Data Storage Solutions - MongoDB for document storage
 * Requirement: 3.3.1 API Architecture - REST/HTTP/2 with rate limiting
 */
export const config = loadConfig();