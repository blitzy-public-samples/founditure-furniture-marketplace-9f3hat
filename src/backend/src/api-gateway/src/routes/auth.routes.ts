// External dependencies
import express, { Router } from 'express'; // v4.18.0

// Internal dependencies
import { AuthController } from '../../../auth-service/src/controllers/auth.controller';
import { authenticate } from '../middleware/auth.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import { createRateLimiter } from '../middleware/rateLimit.middleware';

/**
 * Human Tasks:
 * 1. Configure rate limiting Redis instance for authentication routes
 * 2. Set up authentication event logging and monitoring
 * 3. Configure proper CORS settings for authentication endpoints
 * 4. Set up monitoring for failed authentication attempts
 * 5. Implement account lockout mechanism after failed attempts
 * 6. Configure proper session management settings
 */

// Rate limiting configuration for auth routes
// Requirement: 5.3.1 Network Security/API Gateway - Rate limiting for auth endpoints
const AUTH_RATE_LIMIT = {
  windowMs: 900000, // 15 minutes
  max: 100 // 100 requests per window
};

/**
 * Initializes authentication routes with middleware chains
 * Requirement: 5.1.1 Authentication Methods - Implementation of authentication routes
 * @param authController Instance of AuthController for handling auth operations
 * @returns Configured Express router with auth routes
 */
export function initializeAuthRoutes(authController: AuthController): Router {
  const router = express.Router();

  // Initialize rate limiter middleware
  const rateLimiter = createRateLimiter(AUTH_RATE_LIMIT);

  // User registration endpoint
  // Requirement: 5.1.1 Authentication Methods - User registration with secure storage
  router.post(
    '/register',
    rateLimiter,
    validateRequest(RegisterDto),
    authController.register
  );

  // User login endpoint
  // Requirement: 5.1.1 Authentication Methods - Email/password authentication
  router.post(
    '/login',
    rateLimiter,
    validateRequest(LoginDto),
    authController.login
  );

  // Token refresh endpoint
  // Requirement: 5.1.1 Authentication Methods - Token refresh mechanism
  router.post(
    '/refresh',
    rateLimiter,
    authenticate,
    validateRequest(RefreshTokenDto),
    authController.refreshToken
  );

  // User logout endpoint
  // Requirement: 5.1.1 Authentication Methods - Secure session management
  router.post(
    '/logout',
    rateLimiter,
    authenticate,
    authController.logout
  );

  // OAuth callback endpoint
  // Requirement: 5.1.1 Authentication Methods - Social OAuth authentication
  router.get(
    '/oauth/:provider/callback',
    rateLimiter,
    authController.oauthCallback
  );

  return router;
}

// Export configured router instance
// Requirement: 5.3.1 Network Security/API Gateway - Secure routing implementation
export const authRouter = initializeAuthRoutes(new AuthController());