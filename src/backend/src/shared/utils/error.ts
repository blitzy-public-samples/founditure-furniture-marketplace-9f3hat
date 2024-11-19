// External dependencies
import { StatusCodes } from 'http-status-codes'; // v2.2.0

// Internal dependencies
import { ErrorCode } from '../types';

/**
 * Human Tasks:
 * 1. Configure error monitoring and alerting system (e.g., Sentry, New Relic)
 * 2. Set up error logging infrastructure for production environment
 * 3. Define error severity levels and alerting thresholds
 * 4. Configure error reporting and analytics dashboard
 */

/**
 * Base error class that extends Error with additional properties
 * Requirement: Error Handling - Centralized error handling and monitoring across microservices
 */
export class BaseError extends Error {
  public readonly statusCode: number;
  public readonly errorCode: ErrorCode;
  public readonly context: Record<string, any>;
  public readonly timestamp: string;

  constructor(
    message: string,
    statusCode: number,
    context: Record<string, any> = {},
    errorCode: ErrorCode = ErrorCode.INTERNAL_ERROR
  ) {
    super(message);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
    this.errorCode = errorCode;
    this.context = context;
    this.timestamp = new Date().toISOString();
    
    // Capture stack trace for error tracking
    Error.captureStackTrace(this, this.constructor);
    
    // Log error details for monitoring
    console.error(`[${this.name}] ${message}`, {
      statusCode,
      errorCode,
      context,
      timestamp: this.timestamp,
      stack: this.stack
    });
  }
}

/**
 * Validation error class for request validation failures
 * Requirement: API Error Responses - Standardized error responses with proper status codes
 */
export class ValidationError extends BaseError {
  constructor(message: string, context: Record<string, any> = {}) {
    super(
      message,
      StatusCodes.BAD_REQUEST,
      context,
      ErrorCode.VALIDATION_ERROR
    );
  }
}

/**
 * Authentication error class for auth failures
 * Requirement: API Error Responses - Standardized error responses with proper status codes
 */
export class AuthenticationError extends BaseError {
  constructor(message: string, context: Record<string, any> = {}) {
    super(
      message,
      StatusCodes.UNAUTHORIZED,
      context,
      ErrorCode.UNAUTHORIZED
    );
  }
}

/**
 * Authorization error class for permission failures
 * Requirement: API Error Responses - Standardized error responses with proper status codes
 */
export class AuthorizationError extends BaseError {
  constructor(message: string, context: Record<string, any> = {}) {
    super(
      message,
      StatusCodes.FORBIDDEN,
      context,
      ErrorCode.FORBIDDEN
    );
  }
}

/**
 * Not found error class for missing resources
 * Requirement: API Error Responses - Standardized error responses with proper status codes
 */
export class NotFoundError extends BaseError {
  constructor(message: string, context: Record<string, any> = {}) {
    super(
      message,
      StatusCodes.NOT_FOUND,
      context,
      ErrorCode.NOT_FOUND
    );
  }
}

/**
 * Formats error object into standardized API error response
 * Requirement: Error Handling - Standardized error formats and logging
 */
export function formatError(error: Error): Record<string, any> {
  const baseResponse = {
    success: false,
    message: error.message || 'An unexpected error occurred',
    timestamp: new Date().toISOString()
  };

  if (error instanceof BaseError) {
    return {
      ...baseResponse,
      status: error.statusCode,
      code: error.errorCode,
      context: error.context,
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    };
  }

  // Handle unknown errors
  return {
    ...baseResponse,
    status: StatusCodes.INTERNAL_SERVER_ERROR,
    code: ErrorCode.INTERNAL_ERROR,
    ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
  };
}

/**
 * Determines if an error is operational (expected) or programming error
 * Requirement: Error Handling - Centralized error handling and monitoring
 */
export function isOperationalError(error: Error): boolean {
  if (error instanceof BaseError) {
    return true;
  }
  return false; // Programming errors should trigger alerts
}