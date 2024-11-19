/**
 * Human Tasks:
 * 1. Configure Redis connection settings in environment variables
 * 2. Set up monitoring and alerting for rate limit exceeded events
 * 3. Configure IP whitelist for trusted clients/services
 * 4. Define path exclusions for health check and monitoring endpoints
 * 5. Set up logging infrastructure for rate limit events
 */

// External dependencies
import rateLimit from 'express-rate-limit'; // v6.7.0
import RedisStore from 'rate-limit-redis'; // v3.0.0
import { RedisClient } from 'redis'; // v4.6.0
import { Request, Response, RequestHandler, NextFunction } from 'express'; // v4.18.0

// Internal dependencies
import { AuthenticationError } from '../../../shared/utils/error';

// Global rate limit settings from environment variables
const RATE_LIMIT_WINDOW_MS = parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000', 10);
const MAX_REQUESTS_PER_WINDOW = parseInt(process.env.MAX_REQUESTS_PER_WINDOW || '100', 10);

/**
 * Interface for rate limiter configuration options
 * Requirement: Rate Limiting - Token Bucket algorithm with configurable limits
 */
export interface RateLimitConfig {
  windowMs: number;
  max: number;
  skipFailedRequests: boolean;
  skipPaths: string[];
  skipIps: string[];
}

/**
 * Custom error handler for rate limit exceeded responses
 * Requirement: API Gateway Security - DDoS protection and request rate limiting
 */
const handleRateLimitExceeded = (req: Request, res: Response): void => {
  const clientIp = req.ip || req.socket.remoteAddress;
  const timestamp = new Date().toISOString();

  // Create rate limit exceeded error with retry information
  const error = new AuthenticationError('Rate limit exceeded', {
    clientIp,
    timestamp,
    path: req.path,
    method: req.method
  });

  // Calculate retry-after time in seconds
  const retryAfter = Math.ceil(RATE_LIMIT_WINDOW_MS / 1000);

  // Log rate limit exceeded event
  console.warn(`Rate limit exceeded for IP ${clientIp}`, {
    path: req.path,
    method: req.method,
    timestamp,
    retryAfter
  });

  // Send error response with retry-after header
  res.setHeader('Retry-After', retryAfter);
  res.status(429).json({
    success: false,
    message: error.message,
    status: error.statusCode,
    code: error.errorCode,
    context: error.context
  });
};

/**
 * Creates and configures the rate limiting middleware using Redis
 * Requirement: Rate Limiting - Token Bucket algorithm with 100 requests/minute rate limit
 * Requirement: API Gateway Security - DDoS protection at API Gateway level
 */
export const createRateLimiter = (redisClient: RedisClient): RequestHandler => {
  // Initialize Redis store for distributed rate limiting
  const store = new RedisStore({
    client: redisClient,
    prefix: 'rate-limit:',
    sendCommand: (...args: string[]) => redisClient.sendCommand(args)
  });

  // Configure rate limiter with token bucket algorithm
  const limiter = rateLimit({
    windowMs: RATE_LIMIT_WINDOW_MS,
    max: MAX_REQUESTS_PER_WINDOW,
    standardHeaders: true, // Return rate limit info in RateLimit-* headers
    legacyHeaders: false, // Disable X-RateLimit-* headers
    store: store,
    skipFailedRequests: false, // Count failed requests against limit
    skipSuccessfulRequests: false, // Count successful requests against limit
    
    // Skip rate limiting for whitelisted IPs and health check paths
    skip: (req: Request) => {
      const whitelistedIps = process.env.RATE_LIMIT_WHITELIST_IPS?.split(',') || [];
      const whitelistedPaths = process.env.RATE_LIMIT_WHITELIST_PATHS?.split(',') || ['/health', '/metrics'];
      
      return (
        whitelistedIps.includes(req.ip || req.socket.remoteAddress || '') ||
        whitelistedPaths.some(path => req.path.startsWith(path))
      );
    },

    // Custom handler for rate limit exceeded
    handler: handleRateLimitExceeded,

    // Custom key generator based on IP and optional user ID
    keyGenerator: (req: Request): string => {
      const clientIp = req.ip || req.socket.remoteAddress || '';
      const userId = (req as any).user?.id || '';
      return `${clientIp}:${userId}`;
    },

    // Draft state for rate limit response
    draft_polli_ratelimit_headers: true
  });

  return limiter;
};