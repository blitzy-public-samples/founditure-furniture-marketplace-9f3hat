// External dependencies
import dotenv from 'dotenv'; // v16.0.3

// Internal dependencies
import { API_RATE_LIMITS, SERVICE_ENDPOINTS } from '../../../shared/constants';

/**
 * Human Tasks:
 * 1. Configure environment variables in .env file for production deployment
 * 2. Set up TLS certificates for HTTPS encryption
 * 3. Configure frontend URL in environment for CORS
 * 4. Review and adjust rate limiting settings based on load testing
 * 5. Validate service endpoints are correctly configured in deployment
 */

// Initialize environment variables
dotenv.config();

/**
 * Interface for CORS configuration options
 * Requirement: 2.2.1 Core Components/API Gateway - Kong Gateway configuration
 */
export interface CorsOptions {
  origin: string[];
  methods: string[];
  allowedHeaders: string[];
  credentials: boolean;
  maxAge: number;
}

/**
 * Interface for rate limiting configuration
 * Requirement: 3.3.1 API Architecture - Token Bucket rate limiting
 */
export interface RateLimitConfig {
  windowMs: number;
  maxRequests: number;
  skipFailedRequests: boolean;
  keyPrefix: string;
}

/**
 * Main configuration interface for API Gateway settings
 * Requirement: 2.2.1 Core Components/API Gateway - Kong Gateway configuration
 */
export interface Config {
  env: string;
  port: number;
  corsOptions: CorsOptions;
  rateLimitConfig: RateLimitConfig;
  services: typeof SERVICE_ENDPOINTS;
}

/**
 * CORS configuration with security headers
 * Requirement: 5.2 Data Security/5.2.1 Encryption Standards - Security controls
 */
const corsOptions: CorsOptions = {
  origin: [process.env.FRONTEND_URL as string],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400 // 24 hours
};

/**
 * Rate limiting configuration using token bucket algorithm
 * Requirement: 3.3.1 API Architecture - Token Bucket with 100 requests/minute rate limiting
 */
const rateLimitConfig: RateLimitConfig = {
  windowMs: 60000, // 1 minute in milliseconds
  maxRequests: API_RATE_LIMITS.REQUESTS_PER_MINUTE,
  skipFailedRequests: true,
  keyPrefix: 'rl:'
};

/**
 * Main configuration object for API Gateway
 * Requirement: 2.2.1 Core Components/API Gateway - Kong Gateway configuration
 * Requirement: 5.2 Data Security/5.2.1 Encryption Standards - Security controls
 */
export const config: Config = {
  env: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT) || 3000,
  corsOptions,
  rateLimitConfig,
  services: SERVICE_ENDPOINTS
};