// External dependencies
import { Injectable } from '@nestjs/common'; // v9.0.0
import { Model } from 'mongoose'; // v7.5.0
import { validate } from 'class-validator'; // v0.14.0

// Internal dependencies
import { User, AuthProvider } from '../models/user.model';
import { Service } from '../../../shared/interfaces/service.interface';
import { generateAccessToken, generateTokenPair, verifyToken } from '../utils/jwt.util';

/**
 * Human Tasks:
 * 1. Configure proper JWT secret keys in environment configuration
 * 2. Set up rate limiting for authentication endpoints
 * 3. Configure proper logging for authentication events
 * 4. Set up monitoring for failed authentication attempts
 * 5. Implement account lockout mechanism after failed attempts
 * 6. Configure proper session management settings
 */

// Interfaces for authentication data validation
export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterData {
  email: string;
  password: string;
  displayName: string;
  provider: AuthProvider;
  providerId?: string;
}

export interface AuthResponse {
  user: User;
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

// Requirement: 5.1.1 Authentication Methods - Core authentication service implementation
@Injectable()
export class AuthService implements Service<User> {
  constructor(private readonly userModel: Model<User>) {}

  // Requirement: 5.1.1 Authentication Methods - Email/password authentication
  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    // Validate credentials format
    const errors = await validate(credentials);
    if (errors.length > 0) {
      throw new Error('Invalid credentials format');
    }

    // Find user by email
    const user = await this.userModel.findOne({ 
      email: credentials.email,
      isActive: true,
      isDeleted: false
    });

    if (!user) {
      throw new Error('User not found');
    }

    // Verify password
    const isValid = await user.validatePassword(credentials.password);
    if (!isValid) {
      throw new Error('Invalid password');
    }

    // Generate token pair
    const tokens = await generateTokenPair(user);

    // Update last login timestamp
    user.lastLoginAt = new Date();
    await user.save();

    return {
      user,
      ...tokens
    };
  }

  // Requirement: 5.1.1 Authentication Methods - User registration with secure storage
  async register(data: RegisterData): Promise<AuthResponse> {
    // Validate registration data
    const errors = await validate(data);
    if (errors.length > 0) {
      throw new Error('Invalid registration data');
    }

    // Check email uniqueness
    const existingUser = await this.userModel.findOne({ email: data.email });
    if (existingUser) {
      throw new Error('Email already registered');
    }

    // Create new user instance
    const user = new User({
      email: data.email,
      provider: data.provider,
      providerId: data.providerId,
      profile: {
        displayName: data.displayName,
        avatarUrl: '',
        bio: '',
        phoneNumber: '',
        dateOfBirth: new Date(),
        interests: []
      }
    });

    // Hash password for email provider
    if (data.provider === AuthProvider.EMAIL) {
      user.passwordHash = await user.hashPassword(data.password);
    }

    // Save user to database
    await user.save();

    // Generate initial token pair
    const tokens = await generateTokenPair(user);

    return {
      user,
      ...tokens
    };
  }

  // Requirement: 5.1.1 Authentication Methods - Token refresh mechanism
  async refreshToken(refreshToken: string): Promise<string> {
    // Verify refresh token
    const decoded = await verifyToken(refreshToken);

    // Validate user exists and is active
    const user = await this.validateUser(decoded.userId);
    if (!user) {
      throw new Error('Invalid user');
    }

    // Generate new access token
    return generateAccessToken(user);
  }

  // Requirement: 5.1.2 Authorization Model - User validation for authorization
  async validateUser(userId: string): Promise<User> {
    const user = await this.userModel.findOne({
      _id: userId,
      isActive: true,
      isDeleted: false
    });

    if (!user) {
      throw new Error('User not found or inactive');
    }

    return user;
  }

  // Service interface implementation
  async create(data: Partial<User>, userId: string): Promise<User> {
    const user = new this.userModel(data);
    user.createdBy = userId;
    return user.save();
  }

  async validate(data: Partial<User>): Promise<{ isValid: boolean; errors: any[] }> {
    const errors = await validate(data);
    return {
      isValid: errors.length === 0,
      errors
    };
  }
}