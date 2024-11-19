// Internal dependencies
import { FurnitureCondition, UserRole } from '../types';

/**
 * Human Tasks:
 * 1. Configure environment variables for service endpoints in deployment environments
 * 2. Review and adjust rate limiting values based on infrastructure capacity
 * 3. Validate JWT expiry times align with security requirements
 * 4. Review point values with product team for gamification effectiveness
 */

/**
 * API rate limiting configuration
 * Requirement: 3.3.1 API Architecture - Token Bucket with 100 requests/minute rate limiting
 */
export const API_RATE_LIMITS = {
  REQUESTS_PER_MINUTE: 100,
  MAX_BURST: 150 // Allow slight bursts above the per-minute limit
} as const;

/**
 * Authentication related constants
 * Requirement: 5.1 Security Requirements - JWT-based authentication
 */
export const AUTH_CONSTANTS = {
  JWT_EXPIRY: 3600, // 1 hour in seconds
  REFRESH_TOKEN_EXPIRY: 2592000, // 30 days in seconds
  PASSWORD_MIN_LENGTH: 8
} as const;

/**
 * Default pagination values for consistent data retrieval
 * Requirement: 3.2.2 Data Management Strategy - Consistent data operations
 */
export const PAGINATION_DEFAULTS = {
  DEFAULT_PAGE_SIZE: 20,
  MAX_PAGE_SIZE: 100
} as const;

/**
 * Gamification point values for user engagement
 * Requirement: 1.2 System Overview/Success Criteria - 70% monthly active user retention through gamification
 */
export const POINTS_CONFIG = {
  LISTING_CREATED: 50, // Points for creating a furniture listing
  ITEM_COLLECTED: 100, // Points for successful furniture collection
  QUICK_COLLECTION: 150 // Bonus points for collecting within 24 hours
} as const;

/**
 * Data validation rules for consistent input validation
 * Requirement: 3.2.2 Data Management Strategy - Consistent data operations and business rules
 */
export const VALIDATION_RULES = {
  TITLE_MIN_LENGTH: 10,
  TITLE_MAX_LENGTH: 100,
  DESCRIPTION_MAX_LENGTH: 1000
} as const;

/**
 * Standardized error messages for consistent API responses
 * Requirement: 2.3.1 API Gateway - Standardized API interfaces and response formats
 */
export const ERROR_MESSAGES = {
  INVALID_CREDENTIALS: 'Invalid email or password provided',
  UNAUTHORIZED: 'You are not authorized to perform this action',
  VALIDATION_ERROR: 'The provided data failed validation'
} as const;

/**
 * Microservice endpoint URLs for service discovery
 * Requirement: 2.2.1 Core Components - Core Services with microservices architecture
 */
export const SERVICE_ENDPOINTS = {
  AUTH_SERVICE: process.env.AUTH_SERVICE_URL || 'http://auth-service:3000',
  LISTING_SERVICE: process.env.LISTING_SERVICE_URL || 'http://listing-service:3001',
  MESSAGING_SERVICE: process.env.MESSAGING_SERVICE_URL || 'http://messaging-service:3002'
} as const;

// Using const assertions for all objects to ensure they are read-only
// and their values cannot be modified at runtime