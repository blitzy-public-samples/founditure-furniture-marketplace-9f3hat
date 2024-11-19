// External dependencies
import { Request, Response } from 'express'; // v4.18.0

// Internal dependencies
import { BaseModel } from '../interfaces/model.interface';
import { FilterOptions, ValidationResult } from '../interfaces/service.interface';
import { ResponseFormat } from '../interfaces/controller.interface';

/**
 * HTTP methods supported by the API endpoints
 * Requirement: 2.3.1 API Gateway - Standardized API interfaces and response formats
 */
export enum HttpMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE',
  PATCH = 'PATCH'
}

/**
 * Status values for entity lifecycle management
 * Requirement: 3.2.2 Data Management Strategy - Consistent data operations
 */
export enum EntityStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  DELETED = 'DELETED',
  PENDING = 'PENDING'
}

/**
 * User authorization roles
 * Requirement: 2.2.1 Core Components - Core Services with microservices architecture
 */
export enum UserRole {
  ADMIN = 'ADMIN',
  MODERATOR = 'MODERATOR',
  USER = 'USER'
}

/**
 * Status values for furniture listings
 * Requirement: 3.2.2 Data Management Strategy - Consistent data operations
 */
export enum ListingStatus {
  AVAILABLE = 'AVAILABLE',
  RESERVED = 'RESERVED',
  COLLECTED = 'COLLECTED',
  EXPIRED = 'EXPIRED'
}

/**
 * Condition ratings for furniture items
 * Requirement: 3.2.2 Data Management Strategy - Consistent data operations
 */
export enum FurnitureCondition {
  EXCELLENT = 'EXCELLENT',
  GOOD = 'GOOD',
  FAIR = 'FAIR',
  POOR = 'POOR'
}

/**
 * Types of messages in the chat system
 * Requirement: 2.2.1 Core Components - Core Services with microservices architecture
 */
export enum MessageType {
  TEXT = 'TEXT',
  IMAGE = 'IMAGE',
  LOCATION = 'LOCATION',
  SYSTEM = 'SYSTEM'
}

/**
 * Types of push notifications
 * Requirement: 2.2.1 Core Components - Core Services with microservices architecture
 */
export enum NotificationType {
  LISTING = 'LISTING',
  MESSAGE = 'MESSAGE',
  ACHIEVEMENT = 'ACHIEVEMENT',
  SYSTEM = 'SYSTEM'
}

/**
 * API error codes for standardized error handling
 * Requirement: 2.3.1 API Gateway - Standardized API interfaces and response formats
 */
export enum ErrorCode {
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  NOT_FOUND = 'NOT_FOUND',
  UNAUTHORIZED = 'UNAUTHORIZED',
  FORBIDDEN = 'FORBIDDEN',
  INTERNAL_ERROR = 'INTERNAL_ERROR'
}

// Re-export types from interfaces for centralized access
export type {
  BaseModel,
  FilterOptions,
  ValidationResult,
  ResponseFormat
};