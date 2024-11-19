// External dependencies
import { Schema, model, Document } from 'mongoose'; // v7.5.0
import * as bcrypt from 'bcrypt'; // v5.1.0
import { IsEmail, IsEnum, IsString, IsDate, IsBoolean, IsNumber, IsArray, ValidateNested } from 'class-validator'; // v0.14.0
import { randomBytes } from 'crypto';

// Internal dependencies
import { BaseModel, AuditableModel, SoftDeletable } from '../../../shared/interfaces/model.interface';

/**
 * Human Tasks:
 * 1. Ensure MongoDB is properly configured with authentication and encryption at rest
 * 2. Set up proper password hashing configuration in production environment
 * 3. Configure audit logging middleware to track user model changes
 * 4. Set up proper refresh token rotation and cleanup mechanism
 * 5. Implement proper data backup and recovery procedures for user data
 */

// Requirement: 5.1.2 Authorization Model - Role-based access control with hierarchical user roles
export enum UserRole {
  ADMIN = 'ADMIN',
  MODERATOR = 'MODERATOR',
  VERIFIED_USER = 'VERIFIED_USER',
  BASIC_USER = 'BASIC_USER'
}

// Requirement: 5.1.1 Authentication Methods - Support for multiple authentication providers
export enum AuthProvider {
  EMAIL = 'EMAIL',
  GOOGLE = 'GOOGLE',
  APPLE = 'APPLE',
  FACEBOOK = 'FACEBOOK'
}

// Requirement: 5.1.1 Authentication Methods - Comprehensive user profile management
export interface UserProfile {
  displayName: string;
  avatarUrl: string;
  bio: string;
  phoneNumber: string;
  dateOfBirth: Date;
  interests: string[];
}

// Requirement: 5.1.1 Authentication Methods - Primary authentication using Email/Password and Social OAuth
@Schema({ timestamps: true })
export class User implements BaseModel, AuditableModel, SoftDeletable {
  @IsString()
  id: string;

  @IsEmail()
  email: string;

  @IsString()
  passwordHash: string;

  @IsEnum(UserRole)
  role: UserRole;

  @IsEnum(AuthProvider)
  provider: AuthProvider;

  @IsString()
  providerId?: string;

  @ValidateNested()
  profile: UserProfile;

  @IsNumber()
  points: number;

  @IsArray()
  @IsString({ each: true })
  achievements: string[];

  @IsBoolean()
  emailVerified: boolean;

  @IsDate()
  lastLoginAt?: Date;

  @IsString()
  refreshToken?: string;

  @IsDate()
  refreshTokenExpiresAt?: Date;

  @IsDate()
  createdAt: Date;

  @IsDate()
  updatedAt: Date;

  @IsBoolean()
  isActive: boolean;

  @IsString()
  createdBy: string;

  @IsString()
  updatedBy: string;

  @IsNumber()
  version: number;

  @IsArray()
  auditLogs: Array<{
    entityId: string;
    entityType: string;
    action: string;
    userId: string;
    timestamp: Date;
    changes: Record<string, any>;
  }>;

  @IsBoolean()
  isDeleted: boolean;

  @IsDate()
  deletedAt?: Date;

  @IsString()
  deletedBy?: string;

  constructor(userData: Partial<User>) {
    // Initialize base model properties
    this.id = userData.id || '';
    this.createdAt = userData.createdAt || new Date();
    this.updatedAt = userData.updatedAt || new Date();
    this.isActive = userData.isActive ?? true;
    this.createdBy = userData.createdBy || '';
    this.updatedBy = userData.updatedBy || '';

    // Set default role and provider
    this.role = userData.role || UserRole.BASIC_USER;
    this.provider = userData.provider || AuthProvider.EMAIL;

    // Initialize profile
    this.profile = userData.profile || {
      displayName: '',
      avatarUrl: '',
      bio: '',
      phoneNumber: '',
      dateOfBirth: new Date(),
      interests: []
    };

    // Initialize points and achievements
    this.points = userData.points || 0;
    this.achievements = userData.achievements || [];
    this.emailVerified = userData.emailVerified || false;

    // Initialize audit logging
    this.version = userData.version || 1;
    this.auditLogs = userData.auditLogs || [];

    // Initialize soft deletion properties
    this.isDeleted = userData.isDeleted || false;
    this.deletedAt = userData.deletedAt;
    this.deletedBy = userData.deletedBy;
  }

  // Requirement: 5.2.1 Encryption Standards - Secure storage of user credentials
  async hashPassword(password: string): Promise<string> {
    const salt = await bcrypt.genSalt(12);
    return bcrypt.hash(password, salt);
  }

  // Requirement: 5.1.1 Authentication Methods - Password validation
  async validatePassword(password: string): Promise<boolean> {
    if (!this.passwordHash) return false;
    return bcrypt.compare(password, this.passwordHash);
  }

  // Requirement: 5.1.1 Authentication Methods - JWT token management
  async generateRefreshToken(): Promise<string> {
    // Generate a cryptographically secure random token
    const token = randomBytes(40).toString('hex');
    
    // Set refresh token expiry to 30 days from now
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + 30);

    // Update user document with new refresh token
    this.refreshToken = token;
    this.refreshTokenExpiresAt = expiryDate;

    return token;
  }
}

// Create and export the Mongoose model
export default model<User & Document>('User', Schema.from(User));