// External dependencies
import { config as dotenvConfig } from 'dotenv'; // v16.0.0
import { AWS } from '@aws-sdk/client-rekognition'; // v3.0.0

// Internal dependencies
import { SERVICE_ENDPOINTS } from '../../../shared/constants';

/**
 * Human Tasks:
 * 1. Set up AWS credentials in environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
 * 2. Configure AWS Rekognition service access and permissions
 * 3. Review and adjust image processing parameters based on performance requirements
 * 4. Set up environment-specific configuration for different deployment environments
 */

// Load environment variables
dotenvConfig();

// Interface for AWS credentials configuration
interface AWSCredentials {
  accessKeyId: string;
  secretAccessKey: string;
}

// Interface for image processing configuration
interface ImageProcessingConfig {
  maxSize: number;
  allowedTypes: string[];
  minConfidence: number;
}

// Basic service configuration
// Requirement: AI-powered furniture recognition - Core service configuration
export const config = {
  port: Number(process.env.AI_SERVICE_PORT) || 3002,
  env: process.env.NODE_ENV || 'development',
  serviceName: 'ai-service',
  authServiceUrl: SERVICE_ENDPOINTS.AUTH_SERVICE
} as const;

// AWS configuration for Rekognition service
// Requirement: Image Recognition System - AWS Rekognition integration
export const awsConfig = {
  region: process.env.AWS_REGION || 'us-east-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || ''
  } as AWSCredentials
} as const;

// Image processing configuration
// Requirement: Image Recognition System - Image processing parameters
export const imageConfig = {
  // Maximum image size in bytes (10MB)
  maxSize: 10 * 1024 * 1024,
  // Allowed MIME types for image upload
  allowedTypes: [
    'image/jpeg',
    'image/png',
    'image/webp'
  ],
  // Minimum confidence score for furniture recognition (70%)
  minConfidence: 70.0
} as const;

// Validate AWS credentials
if (!awsConfig.credentials.accessKeyId || !awsConfig.credentials.secretAccessKey) {
  throw new Error('AWS credentials are required for AI service operation');
}

// Validate service configuration
if (!config.port || !config.env || !config.serviceName) {
  throw new Error('Invalid service configuration');
}

// Freeze configuration objects to prevent modification
Object.freeze(config);
Object.freeze(awsConfig);
Object.freeze(imageConfig);