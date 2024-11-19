// External dependencies
import { Request, Response, NextFunction } from 'express'; // v4.18.0
import { StatusCodes } from 'http-status-codes'; // v2.2.0

// Internal dependencies
import { Logger } from '../utils/logger';
import { formatError, isOperationalError, BaseError, NotFoundError } from '../utils/error';

/**
 * Human Tasks:
 * 1. Configure error monitoring service (e.g., Sentry) in production environment
 * 2. Set up error alerting thresholds and notification channels
 * 3. Configure error logging retention policies
 * 4. Set up error reporting dashboard for operational monitoring
 * 5. Define error severity levels and escalation procedures
 */

// Initialize logger for error middleware
const logger = new Logger('ErrorMiddleware');

/**
 * Express middleware for handling 404 Not Found errors
 * Requirement: API Error Responses - Standardized error responses with proper status codes
 */
export const notFoundHandler = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const error = new NotFoundError(`Route not found: ${req.originalUrl}`, {
    method: req.method,
    path: req.path,
    query: req.query,
    headers: req.headers,
    ip: req.ip
  });
  next(error);
};

/**
 * Express middleware for centralized error handling
 * Requirements:
 * - Error Handling - Centralized error handling and monitoring across microservices
 * - API Error Responses - Standardized error responses with proper status codes
 * - System Monitoring - Error logging and monitoring integration
 */
export const errorHandler = (
  error: Error,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Log error with context for monitoring
  logger.error('Error occurred during request processing', error, {
    requestId: req.headers['x-request-id'],
    method: req.method,
    path: req.path,
    query: req.query,
    body: req.body,
    ip: req.ip,
    userId: (req as any).user?.id
  });

  // Determine if error is operational
  const isOperational = isOperationalError(error);

  // Get status code from error or default to 500
  const statusCode = (error as BaseError).statusCode || StatusCodes.INTERNAL_SERVER_ERROR;

  // Format error response
  const errorResponse = formatError(error);

  // Send error response to client
  res.status(statusCode).json(errorResponse);

  // Handle non-operational errors in production
  if (!isOperational && process.env.NODE_ENV === 'production') {
    // Log critical error
    logger.error('Non-operational error detected - initiating graceful shutdown', error, {
      critical: true,
      shutdownInitiated: true
    });

    // Trigger graceful shutdown
    process.emit('SIGTERM');
  }

  // Pass error to next error handler if exists
  if (next) {
    next(error);
  }
};