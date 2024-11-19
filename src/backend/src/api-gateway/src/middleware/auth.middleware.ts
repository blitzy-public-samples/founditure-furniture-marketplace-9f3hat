// External dependencies
import * as express from 'express'; // v4.18.0

// Internal dependencies
import { verifyToken, JWTPayload } from '../../../auth-service/src/utils/jwt.util';
import { AuthenticationError, AuthorizationError } from '../../../shared/utils/error';

/**
 * Human Tasks:
 * 1. Configure JWT secret keys in environment configuration
 * 2. Set up proper token expiration times based on security requirements
 * 3. Implement token blacklist/revocation mechanism
 * 4. Configure proper CORS settings for API endpoints
 * 5. Set up rate limiting for authentication endpoints
 */

// Requirement: 5.1.1 Authentication Methods - JWT token-based session management
export interface AuthenticatedRequest extends express.Request {
  user?: JWTPayload;
}

// Requirement: 5.1.1 Authentication Methods - JWT Tokens for API authentication
export const authenticate = async (
  req: express.Request,
  res: express.Response,
  next: express.NextFunction
): Promise<void> => {
  try {
    // Extract authorization header
    const authHeader = req.headers.authorization;
    
    // Check if token exists
    if (!authHeader) {
      throw new AuthenticationError('No authentication token provided');
    }

    // Extract token from Bearer scheme
    const token = authHeader.replace('Bearer ', '');
    if (!token) {
      throw new AuthenticationError('Invalid token format');
    }

    try {
      // Verify and decode token
      const decodedToken = await verifyToken(token);

      // Attach user payload to request
      (req as AuthenticatedRequest).user = decodedToken;

      next();
    } catch (error) {
      // Handle specific token verification errors
      if (error instanceof Error) {
        if (error.message === 'Token has expired') {
          throw new AuthenticationError('Authentication token has expired');
        } else if (error.message === 'Invalid token') {
          throw new AuthenticationError('Invalid authentication token');
        }
      }
      throw error;
    }
  } catch (error) {
    // Pass error to error handling middleware
    next(error);
  }
};

// Requirement: 5.1.2 Authorization Model - Role-based access control
export const authorize = (requiredRoles: string[]) => {
  return async (
    req: express.Request,
    res: express.Response,
    next: express.NextFunction
  ): Promise<void> => {
    try {
      const authenticatedReq = req as AuthenticatedRequest;
      
      // Verify user exists in request after authentication
      if (!authenticatedReq.user) {
        throw new AuthenticationError('User not authenticated');
      }

      // Extract user role from authenticated request
      const userRole = authenticatedReq.user.role;

      // Verify user has required role
      if (!requiredRoles.includes(userRole)) {
        throw new AuthorizationError(
          `Access denied. Required roles: ${requiredRoles.join(', ')}`
        );
      }

      next();
    } catch (error) {
      // Pass error to error handling middleware
      next(error);
    }
  };
};