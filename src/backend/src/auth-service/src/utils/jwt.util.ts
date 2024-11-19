// External dependencies
import * as jwt from 'jsonwebtoken'; // v9.0.0
import * as config from 'config'; // v3.3.9

// Internal dependencies
import { User, UserRole } from '../models/user.model';

/**
 * Human Tasks:
 * 1. Ensure JWT secrets are properly configured in config files for different environments
 * 2. Set up secure key rotation mechanism for JWT secrets
 * 3. Configure proper token expiration times based on security requirements
 * 4. Implement token blacklist mechanism for revoked tokens
 * 5. Set up monitoring for token usage and potential security issues
 */

// Requirement: 5.1.1 Authentication Methods - JWT token payload structure
export interface JWTPayload {
  userId: string;
  email: string;
  role: UserRole;
  iat?: number;
  exp?: number;
}

// Requirement: 5.1.1 Authentication Methods - Token response structure
export interface TokenResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

// Requirement: 5.1.1 Authentication Methods - JWT Tokens for session management
export async function generateAccessToken(user: User): Promise<string> {
  const payload: JWTPayload = {
    userId: user.id,
    email: user.email,
    role: user.role
  };

  // Access token expires in 15 minutes
  return jwt.sign(payload, config.get<string>('jwt.accessTokenSecret'), {
    expiresIn: '15m',
    algorithm: 'HS256'
  });
}

// Requirement: 5.3.2 Security Controls - Token validation with role-based authorization
export async function verifyToken(token: string): Promise<JWTPayload> {
  try {
    const decoded = jwt.verify(token, config.get<string>('jwt.accessTokenSecret')) as JWTPayload;
    
    // Validate payload structure
    if (!decoded.userId || !decoded.email || !decoded.role) {
      throw new Error('Invalid token payload structure');
    }

    return decoded;
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      throw new Error('Token has expired');
    } else if (error instanceof jwt.JsonWebTokenError) {
      throw new Error('Invalid token');
    }
    throw error;
  }
}

// Requirement: 5.1.1 Authentication Methods - Secure token rotation
export async function generateTokenPair(user: User): Promise<TokenResponse> {
  // Generate access token
  const accessToken = await generateAccessToken(user);

  // Generate refresh token with 30 day expiration
  const refreshToken = jwt.sign(
    {
      userId: user.id,
      email: user.email,
      role: user.role,
      tokenType: 'refresh'
    },
    config.get<string>('jwt.refreshTokenSecret'),
    {
      expiresIn: '30d',
      algorithm: 'HS256'
    }
  );

  // Calculate access token expiration (15 minutes from now)
  const expiresIn = 15 * 60; // 15 minutes in seconds

  return {
    accessToken,
    refreshToken,
    expiresIn
  };
}

// Requirement: 5.1.1 Authentication Methods - JWT Tokens with secure token rotation
export async function refreshAccessToken(refreshToken: string): Promise<string> {
  try {
    // Verify refresh token
    const decoded = jwt.verify(
      refreshToken,
      config.get<string>('jwt.refreshTokenSecret')
    ) as JWTPayload & { tokenType: string };

    // Validate that this is actually a refresh token
    if (decoded.tokenType !== 'refresh') {
      throw new Error('Invalid token type');
    }

    // Create new access token with current user data
    const payload: JWTPayload = {
      userId: decoded.userId,
      email: decoded.email,
      role: decoded.role
    };

    // Generate new access token
    return jwt.sign(payload, config.get<string>('jwt.accessTokenSecret'), {
      expiresIn: '15m',
      algorithm: 'HS256'
    });
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      throw new Error('Refresh token has expired');
    } else if (error instanceof jwt.JsonWebTokenError) {
      throw new Error('Invalid refresh token');
    }
    throw error;
  }
}