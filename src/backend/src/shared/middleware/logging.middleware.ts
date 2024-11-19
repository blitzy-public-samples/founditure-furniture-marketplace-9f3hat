// External dependencies
import { Request, Response, NextFunction } from 'express'; // v4.18.0
import { v4 as uuidv4 } from 'uuid'; // v9.0.0

// Internal dependencies
import { Logger } from '../utils/logger';
import { formatError } from '../utils/error';

/**
 * Human Tasks:
 * 1. Configure log retention policies in ELK Stack
 * 2. Set up log shipping to centralized logging system
 * 3. Configure log monitoring and alerting thresholds
 * 4. Set up distributed tracing system integration
 * 5. Configure request sampling rates for high-traffic environments
 */

// Initialize HTTP logger instance
const logger = new Logger('http');

/**
 * Formats request information for logging with consistent structure
 * Requirement: 2.4.1 System Monitoring - Centralizes logs using ELK Stack
 */
const formatRequestLog = (req: Request, requestId: string): Record<string, any> => {
  const {
    method,
    originalUrl,
    query,
    headers,
    ip,
    body
  } = req;

  // Filter out sensitive headers
  const sanitizedHeaders = { ...headers };
  delete sanitizedHeaders.authorization;
  delete sanitizedHeaders.cookie;

  return {
    requestId,
    timestamp: new Date().toISOString(),
    method,
    url: originalUrl,
    query: Object.keys(query).length ? query : undefined,
    headers: sanitizedHeaders,
    ip,
    userAgent: headers['user-agent'],
    // Only include body for non-GET requests and if content isn't multipart
    body: method !== 'GET' && !headers['content-type']?.includes('multipart/form-data') 
      ? body 
      : undefined
  };
};

/**
 * Formats response information for logging with consistent structure
 * Requirement: 2.4.1 System Monitoring - Centralizes logs using ELK Stack
 */
const formatResponseLog = (
  res: Response, 
  requestId: string, 
  duration: number
): Record<string, any> => {
  return {
    requestId,
    timestamp: new Date().toISOString(),
    statusCode: res.statusCode,
    statusMessage: res.statusMessage,
    duration, // Response time in milliseconds
    headers: res.getHeaders(),
    size: res.get('content-length'),
    // Include response body only for errors
    body: res.statusCode >= 400 ? res.locals.responseBody : undefined
  };
};

/**
 * Express middleware that logs incoming HTTP requests with timing and context information
 * Requirement: 2.4 Cross-Cutting Concerns - System-wide logging and monitoring
 * Requirement: 5.3.4 Security Monitoring - Log collection and analysis
 */
export const requestLoggingMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Generate unique request ID for tracing
  const requestId = uuidv4();
  
  // Record request start time
  const startTime = process.hrtime();

  // Add request ID to response headers for tracing
  res.setHeader('X-Request-ID', requestId);

  // Log initial request details
  logger.info('Incoming request', formatRequestLog(req, requestId));

  // Store original end function
  const originalEnd = res.end;
  const chunks: Buffer[] = [];

  // Override end function to capture response body and timing
  res.end = function(chunk: any, ...args: any[]): any {
    if (chunk) {
      chunks.push(Buffer.from(chunk));
    }

    // Calculate request duration
    const [seconds, nanoseconds] = process.hrtime(startTime);
    const duration = seconds * 1000 + nanoseconds / 1000000;

    // Store response body for error logging
    if (res.statusCode >= 400) {
      const body = Buffer.concat(chunks).toString('utf8');
      try {
        res.locals.responseBody = JSON.parse(body);
      } catch {
        res.locals.responseBody = body;
      }
    }

    // Log response details
    logger.info('Outgoing response', formatResponseLog(res, requestId, duration));

    // Restore and call original end function
    res.end = originalEnd;
    return res.end(chunk, ...args);
  };

  // Error handling
  res.on('error', (error: Error) => {
    logger.error('Response error', error, {
      requestId,
      error: formatError(error)
    });
  });

  next();
};