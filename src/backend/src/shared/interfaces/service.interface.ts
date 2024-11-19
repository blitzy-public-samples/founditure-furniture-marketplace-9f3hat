// External dependencies
import { Document } from 'mongoose'; // v7.5.0
import { FindOptionsOrder } from 'typeorm'; // v0.3.17

// Internal dependencies
import { BaseModel } from './model.interface';

/**
 * Human Tasks:
 * 1. Ensure proper error handling middleware is configured for validation errors
 * 2. Set up request context management for user tracking
 * 3. Configure logging for service operations
 * 4. Set up monitoring for service performance metrics
 */

/**
 * Enum for sort order options in queries
 * Requirement: 3.2.2 Data Management Strategy - Consistent query operations
 */
export enum SortOrder {
  asc = 'asc',
  desc = 'desc'
}

/**
 * Interface for standardized query filtering, pagination and sorting
 * Requirement: 3.2.2 Data Management Strategy - Consistent data operations
 */
export interface FilterOptions {
  page: number;
  limit: number;
  filters: Record<string, any>;
  sortBy: string;
  sortOrder: SortOrder;
}

/**
 * Interface for detailed validation error information
 * Requirement: 3.2.2 Data Management Strategy - Consistent validation
 */
export interface ValidationError {
  field: string;
  message: string;
  code: string;
}

/**
 * Interface for data validation results with error details
 * Requirement: 3.2.2 Data Management Strategy - Consistent validation
 */
export interface ValidationResult {
  isValid: boolean;
  errors: ValidationError[];
}

/**
 * Base interface that defines standard CRUD and validation operations all services must implement
 * Requirement: 2.2.1 Core Components - Core Services using Node.js with microservices architecture
 * Requirement: 3.2.2 Data Management Strategy - Consistent data operations and business rules
 */
export interface Service<T extends BaseModel> {
  /**
   * Creates a new entity with audit tracking
   * @param data Partial entity data to create
   * @param userId ID of user performing the operation for audit
   * @returns Promise resolving to created entity
   */
  create(data: Partial<T>, userId: string): Promise<T>;

  /**
   * Retrieves all active entities with filtering, pagination and sorting
   * @param options Query options including filters, pagination and sorting
   * @returns Promise resolving to array of matching entities
   */
  findAll(options: FilterOptions): Promise<T[]>;

  /**
   * Retrieves a single active entity by ID
   * @param id Entity identifier
   * @returns Promise resolving to found entity or null
   */
  findById(id: string): Promise<T | null>;

  /**
   * Updates an existing entity with audit tracking
   * @param id Entity identifier
   * @param data Partial entity data to update
   * @param userId ID of user performing the operation for audit
   * @returns Promise resolving to updated entity
   */
  update(id: string, data: Partial<T>, userId: string): Promise<T>;

  /**
   * Soft deletes an existing entity by setting isActive to false
   * @param id Entity identifier
   * @param userId ID of user performing the operation for audit
   * @returns Promise resolving to operation success status
   */
  delete(id: string, userId: string): Promise<boolean>;

  /**
   * Validates entity data against business rules and constraints
   * @param data Partial entity data to validate
   * @returns Promise resolving to validation result with any errors
   */
  validate(data: Partial<T>): Promise<ValidationResult>;
}