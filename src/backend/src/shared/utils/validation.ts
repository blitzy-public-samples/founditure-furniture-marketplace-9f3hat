// External dependencies
import { validate, ValidatorOptions, ValidationError as ClassValidatorError } from 'class-validator'; // v0.14.0
import { plainToClass, ClassTransformOptions } from 'class-transformer'; // v0.5.1
import * as Joi from 'joi'; // v17.9.0
import * as dns from 'dns';
import { promisify } from 'util';

// Internal dependencies
import { ValidationError } from '../utils/error';
import { BaseModel } from '../interfaces/model.interface';

/**
 * Human Tasks:
 * 1. Configure validation error monitoring and alerting thresholds
 * 2. Set up validation error logging infrastructure
 * 3. Define custom validation rules specific to business domain
 * 4. Configure email validation DNS lookup timeouts
 */

/**
 * Interface for validation results with error details
 * Requirement: 3.2.2 Data Management Strategy - Input validation and data sanitization
 */
export interface ValidationResult {
  isValid: boolean;
  errors: ValidationError[];
  value: any;
}

/**
 * Interface for validation options and rules
 * Requirement: 3.2.2 Data Management Strategy - Consistent validation
 */
export interface ValidationOptions extends ValidatorOptions {
  skipMissingProperties: boolean;
  whitelist: boolean;
  groups?: string[];
}

/**
 * Interface for input sanitization options
 * Requirement: 3.3.1 API Security - Input validation and request sanitization
 */
export interface SanitizeOptions {
  stripHtml: boolean;
  trim: boolean;
  lowercase: boolean;
}

/**
 * Validates a model instance against its schema and validation rules
 * Requirement: 3.2.2 Data Management Strategy - Input validation
 */
export async function validateModel(
  model: BaseModel,
  options: ValidationOptions = { skipMissingProperties: false, whitelist: true }
): Promise<ValidationResult> {
  try {
    // Validate required BaseModel fields
    if (!model.id || !model.createdAt || !model.updatedAt || model.isActive === undefined ||
        !model.createdBy || !model.updatedBy) {
      return {
        isValid: false,
        errors: [new ValidationError('Missing required BaseModel fields')],
        value: model
      };
    }

    // Run class-validator decorators validation
    const errors: ClassValidatorError[] = await validate(model, options);

    if (errors.length > 0) {
      // Transform class-validator errors to ValidationError format
      const validationErrors = errors.map(error => new ValidationError(
        Object.values(error.constraints || {}).join(', '),
        { property: error.property, value: error.value }
      ));

      return {
        isValid: false,
        errors: validationErrors,
        value: model
      };
    }

    return {
      isValid: true,
      errors: [],
      value: model
    };
  } catch (error) {
    throw new ValidationError('Model validation failed', { error });
  }
}

/**
 * Validates data against a Joi schema with custom rules
 * Requirement: 3.2.2 Data Management Strategy - Data validation
 */
export async function validateSchema(
  data: object,
  schema: Joi.Schema
): Promise<ValidationResult> {
  try {
    const validationResult = await schema.validateAsync(data, {
      abortEarly: false,
      stripUnknown: true
    });

    return {
      isValid: true,
      errors: [],
      value: validationResult
    };
  } catch (error) {
    if (error instanceof Joi.ValidationError) {
      const validationErrors = error.details.map(detail => 
        new ValidationError(detail.message, {
          path: detail.path,
          type: detail.type
        })
      );

      return {
        isValid: false,
        errors: validationErrors,
        value: data
      };
    }
    throw new ValidationError('Schema validation failed', { error });
  }
}

/**
 * Sanitizes input data to prevent XSS and injection attacks
 * Requirement: 3.3.1 API Security - Request sanitization
 */
export function sanitizeInput(
  input: any,
  options: SanitizeOptions = { stripHtml: true, trim: true, lowercase: false }
): any {
  if (typeof input === 'string') {
    let sanitized = input;

    if (options.stripHtml) {
      // Remove HTML tags
      sanitized = sanitized.replace(/<[^>]*>/g, '');
      // Escape special characters
      sanitized = sanitized
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#x27;')
        .replace(/\//g, '&#x2F;');
    }

    if (options.trim) {
      sanitized = sanitized.trim();
    }

    if (options.lowercase) {
      sanitized = sanitized.toLowerCase();
    }

    return sanitized;
  }

  if (Array.isArray(input)) {
    return input.map(item => sanitizeInput(item, options));
  }

  if (typeof input === 'object' && input !== null) {
    const sanitized: Record<string, any> = {};
    for (const [key, value] of Object.entries(input)) {
      sanitized[key] = sanitizeInput(value, options);
    }
    return sanitized;
  }

  return input;
}

/**
 * Validates email format and domain using RFC 5322 regex and DNS lookup
 * Requirement: 3.2.2 Data Management Strategy - Input validation
 */
export async function validateEmail(email: string): Promise<boolean> {
  // RFC 5322 compliant email regex
  const emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;

  if (!emailRegex.test(email)) {
    return false;
  }

  try {
    // Extract domain from email
    const domain = email.split('@')[1];
    
    // Verify domain has valid MX records
    const resolveMx = promisify(dns.resolveMx);
    const mxRecords = await resolveMx(domain);
    
    return mxRecords.length > 0;
  } catch (error) {
    return false;
  }
}