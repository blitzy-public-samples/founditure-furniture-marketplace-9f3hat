// External dependencies
import express, { Router } from 'express'; // v4.18.0

// Internal dependencies
import { authRouter } from './auth.routes';
import messageRouter from './message.routes';
import userRouter from './user.routes';

/**
 * Human Tasks:
 * 1. Configure rate limiting for each route group
 * 2. Set up monitoring and logging for API routes
 * 3. Configure proper CORS settings for API endpoints
 * 4. Set up proper error handling middleware
 * 5. Configure request validation middleware
 * 6. Set up API documentation using OpenAPI/Swagger
 */

// Initialize main router
// Requirement: 2.3.1 Architecture Patterns/API Gateway - Centralized routing
const router = Router();

/**
 * Initializes and configures all API routes with their respective base paths
 * Requirement: 2.3.1 Architecture Patterns/API Gateway - Centralized routing through Kong Gateway
 * Requirement: Core Features - Integration of all core platform features
 */
function initializeRoutes(): Router {
  // Mount authentication routes under /auth
  // Requirement: 5.1.1 Authentication Methods - Authentication routes with JWT and OAuth
  router.use('/auth', authRouter);

  // Mount messaging routes under /messages
  // Requirement: Core Features - Real-time messaging functionality
  router.use('/messages', messageRouter);

  // Mount user routes under /users
  // Requirement: Core Features - User profile and gamification features
  router.use('/users', userRouter);

  // Add health check endpoint for monitoring
  // Requirement: 2.4.1 System Monitoring - Request routing and monitoring
  router.get('/health', (req, res) => {
    res.status(200).json({
      success: true,
      message: 'API Gateway is healthy',
      timestamp: new Date().toISOString(),
      services: {
        auth: 'UP',
        messaging: 'UP',
        user: 'UP'
      }
    });
  });

  return router;
}

// Export configured router with all routes mounted
// Requirement: 2.3.1 Architecture Patterns/API Gateway - Centralized routing
export default initializeRoutes();