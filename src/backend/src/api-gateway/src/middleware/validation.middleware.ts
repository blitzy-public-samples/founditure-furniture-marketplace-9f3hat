// External dependencies
import { Request, Response, NextFunction, RequestHandler } from 'express'; // v4.18.0
import * as Joi from 'joi'; // v17.9.0

// Internal dependencies
import { 
  validateModel, 
  validateSchema, 
  sanitizeInput, 
  ValidationResult, 
  ValidationOptions, 
  SanitizeOptions 
} from '../../shared/utils/validation';
import { ValidationError, formatError } from '../../shared/utils/error';

/**
 * Human Tasks:
 * 1. Configure validation error monitoring thresholds in monitoring system
 * 2. Set up validation error logging infrastructure
 * 3. Configure rate limiting for validation endpoints
 * 4. Define custom validation rules specific to business domain
 */

/**
 * Extended Express Request interface with validated data properties
 * Requirement: 3.2.2 Data Management Strategy - Input validation and data sanitization
 */
export interface ValidatedRequest extends Request {
  validatedBody?: any;
  validatedQuery?: any;
  validatedParams?: any;
}

/**
 * Default sanitization options for request data
 * Requirement: 3.3.1 API Security - Input validation and request sanitization
 */
const defaultSanitizeOptions: SanitizeOptions = {
  stripHtml: true,
  trim: true,
  lowercase: false
};

/**
 * Default validation options
 * Requirement: 3.2.2 Data Management Strategy - Consistent validation
 */
const defaultValidationOptions: ValidationOptions = {
  skipMissingProperties: false,
  whitelist: true
};

/**
 * Express middleware factory that creates a validation middleware for request validation
 * Requirement: 3.3.1 API Security - Input validation, rate limiting, and request sanitization
 * @param schema Joi schema for validation
 * @param options Validation options
 */
export function validateRequest(
  schema: Joi.Schema,
  options: ValidationOptions = defaultValidationOptions
): RequestHandler {
  return async (req: ValidatedRequest, res: Response, next: NextFunction): Promise<void> => {
    try {
      // Extract data to validate
      const dataToValidate = {
        body: req.body,
        query: req.query,
        params: req.params
      };

      // Sanitize input data
      const sanitizedData = sanitizeInput(dataToValidate, defaultSanitizeOptions);

      // Validate against schema
      const result: ValidationResult = await validateSchema(sanitizedData, schema);

      if (!result.isValid) {
        const error = new ValidationError('Request validation failed', {
          errors: result.errors
        });
        return next(error);
      }

      // Attach validated data to request
      req.validatedBody = result.value.body;
      req.validatedQuery = result.value.query;
      req.validatedParams = result.value.params;

      next();
    } catch (error) {
      next(new ValidationError('Request validation failed', { error }));
    }
  };
}

/**
 * Middleware specifically for validating request body data
 * Requirement: 3.2.2 Data Management Strategy - Input validation
 * @param schema Joi schema for body validation
 */
export function validateBody(schema: Joi.Schema): RequestHandler {
  return async (req: ValidatedRequest, res: Response, next: NextFunction): Promise<void> => {
    try {
      // Sanitize body data
      const sanitizedBody = sanitizeInput(req.body, defaultSanitizeOptions);

      // Validate body against schema
      const result: ValidationResult = await validateSchema(sanitizedBody, schema);

      if (!result.isValid) {
        const error = new ValidationError('Request body validation failed', {
          errors: result.errors
        });
        return next(error);
      }

      // Attach validated body to request
      req.validatedBody = result.value;
      next();
    } catch (error) {
      next(new ValidationError('Body validation failed', { error }));
    }
  };
}

/**
 * Middleware specifically for validating request query parameters
 * Requirement: 3.2.2 Data Management Strategy - Input validation
 * @param schema Joi schema for query validation
 */
export function validateQuery(schema: Joi.Schema): RequestHandler {
  return async (req: ValidatedRequest, res: Response, next: NextFunction): Promise<void> => {
    try {
      // Sanitize query data
      const sanitizedQuery = sanitizeInput(req.query, defaultSanitizeOptions);

      // Validate query against schema
      const result: ValidationResult = await validateSchema(sanitizedQuery, schema);

      if (!result.isValid) {
        const error = new ValidationError('Request query validation failed', {
          errors: result.errors
        });
        return next(error);
      }

      // Attach validated query to request
      req.validatedQuery = result.value;
      next();
    } catch (error) {
      next(new ValidationError('Query validation failed', { error }));
    }
  };
}