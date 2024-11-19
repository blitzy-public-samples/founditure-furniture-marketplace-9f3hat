// External dependencies
import { Request, Response } from 'express'; // v4.18.0

// Internal dependencies
import { FilterOptions, ValidationResult } from './service.interface';
import { BaseModel } from './model.interface';

/**
 * Human Tasks:
 * 1. Configure Express middleware for request validation and sanitization
 * 2. Set up error handling middleware for consistent error responses
 * 3. Configure request logging and monitoring middleware
 * 4. Ensure proper CORS and security headers are configured
 * 5. Set up rate limiting and request throttling at API Gateway level
 */

/**
 * Interface for standardized API response format across all endpoints
 * Requirement: 2.3.1 API Gateway - Standardized REST endpoints
 */
export interface ResponseFormat<T = any> {
  success: boolean;
  status: number;
  message: string;
  data?: T;
  errors?: ValidationError[];
}

/**
 * Base interface that defines standard REST endpoints all controllers must implement
 * Requirement: 2.3.1 API Gateway - Kong Gateway with standardized REST endpoints
 * Requirement: 2.2.1 Core Components - Node.js and Express-based microservices
 */
export interface Controller<T extends BaseModel> {
  /**
   * Creates a new resource with validation
   * @param req Express request containing resource data and user context
   * @param res Express response for sending standardized API response
   * @returns Promise resolving to HTTP response with created resource
   */
  create(req: Request, res: Response): Promise<Response<ResponseFormat<T>>>;

  /**
   * Retrieves all resources with pagination, filtering and sorting
   * @param req Express request containing query parameters for filtering
   * @param res Express response for sending standardized API response
   * @returns Promise resolving to HTTP response with array of resources
   */
  findAll(req: Request, res: Response): Promise<Response<ResponseFormat<T[]>>>;

  /**
   * Retrieves a single resource by ID
   * @param req Express request containing resource ID parameter
   * @param res Express response for sending standardized API response
   * @returns Promise resolving to HTTP response with found resource
   */
  findById(req: Request, res: Response): Promise<Response<ResponseFormat<T>>>;

  /**
   * Updates an existing resource with validation
   * @param req Express request containing resource ID and update data
   * @param res Express response for sending standardized API response
   * @returns Promise resolving to HTTP response with updated resource
   */
  update(req: Request, res: Response): Promise<Response<ResponseFormat<T>>>;

  /**
   * Soft deletes an existing resource
   * @param req Express request containing resource ID
   * @param res Express response for sending standardized API response
   * @returns Promise resolving to HTTP response with deletion status
   */
  delete(req: Request, res: Response): Promise<Response<ResponseFormat<boolean>>>;
}