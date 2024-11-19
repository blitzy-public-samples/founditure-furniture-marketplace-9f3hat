// External dependencies
import { Schema, model } from 'mongoose'; // v7.5.0

// Internal dependencies
import { BaseModel, AuditableModel } from '../../../shared/interfaces/model.interface';

/**
 * Human Tasks:
 * 1. Configure MongoDB connection with proper indexes for optimal query performance
 * 2. Set up AWS Rekognition service credentials for AI recognition
 * 3. Configure audit logging middleware to track furniture data changes
 * 4. Set up proper validation thresholds for confidence scores in environment variables
 */

/**
 * Interface defining the structure of furniture data for AI recognition
 * Requirement: AI-powered furniture recognition (1.2 System Overview)
 * Requirement: Image Recognition System (2.2.1 Core Components)
 */
export interface IFurniture extends BaseModel, AuditableModel {
  id: string;
  name: string;
  category: string;
  condition: string;
  dimensions: {
    width: number;
    height: number;
    depth: number;
  };
  recognition: {
    confidenceScore: number;
    labels: string[];
    recognizedAt: Date;
  };
  imageUrls: string[];
  metadata: {
    color: string;
    material: string;
    style: string;
  };
  createdAt: Date;
  updatedAt: Date;
  isActive: boolean;
  createdBy: string;
  updatedBy: string;
  version: number;
  auditLogs: AuditLog[];
}

/**
 * Mongoose schema for furniture data with AI recognition attributes
 * Implements validation and indexing for optimal query performance
 */
class FurnitureSchema {
  private schema: Schema;

  constructor() {
    this.schema = new Schema({
      // Base model fields
      id: {
        type: String,
        required: true,
        unique: true,
        index: true
      },
      name: {
        type: String,
        required: true,
        trim: true,
        maxlength: 100
      },
      category: {
        type: String,
        required: true,
        index: true,
        enum: ['chair', 'table', 'sofa', 'bed', 'storage', 'other']
      },
      condition: {
        type: String,
        required: true,
        enum: ['new', 'excellent', 'good', 'fair', 'poor']
      },
      dimensions: {
        width: {
          type: Number,
          required: true,
          min: 0
        },
        height: {
          type: Number,
          required: true,
          min: 0
        },
        depth: {
          type: Number,
          required: true,
          min: 0
        }
      },
      recognition: {
        confidenceScore: {
          type: Number,
          required: true,
          min: 0,
          max: 100,
          validate: {
            validator: this.validateConfidenceScore,
            message: 'Confidence score must be between 0 and 100'
          },
          index: true
        },
        labels: [{
          type: String,
          required: true
        }],
        recognizedAt: {
          type: Date,
          required: true,
          default: Date.now
        }
      },
      imageUrls: [{
        type: String,
        required: true,
        validate: {
          validator: (url: string) => /^https?:\/\/.+/.test(url),
          message: 'Image URL must be a valid HTTP/HTTPS URL'
        }
      }],
      metadata: {
        color: {
          type: String,
          required: true
        },
        material: {
          type: String,
          required: true
        },
        style: {
          type: String,
          required: true
        }
      },
      // Auditable model fields
      isActive: {
        type: Boolean,
        required: true,
        default: true,
        index: true
      },
      createdBy: {
        type: String,
        required: true
      },
      updatedBy: {
        type: String,
        required: true
      },
      version: {
        type: Number,
        required: true,
        default: 1
      },
      auditLogs: [{
        entityId: String,
        entityType: {
          type: String,
          default: 'Furniture'
        },
        action: {
          type: String,
          enum: ['CREATE', 'UPDATE', 'DELETE']
        },
        userId: String,
        timestamp: Date,
        changes: Schema.Types.Mixed
      }]
    }, {
      timestamps: true,
      versionKey: 'version'
    });

    // Create compound indexes for common queries
    this.schema.index({ category: 1, 'recognition.confidenceScore': -1 });
    this.schema.index({ createdAt: -1, category: 1 });
    this.schema.index({ 'metadata.material': 1, category: 1 });
  }

  /**
   * Validates the AI recognition confidence score
   * Ensures the score meets minimum threshold requirements
   */
  private validateConfidenceScore(score: number): boolean {
    if (typeof score !== 'number') return false;
    if (score < 0 || score > 100) return false;
    
    // Minimum confidence threshold (configurable)
    const minConfidenceThreshold = process.env.MIN_CONFIDENCE_THRESHOLD || 50;
    return score >= minConfidenceThreshold;
  }

  /**
   * Returns the Mongoose schema instance
   */
  public getSchema(): Schema {
    return this.schema;
  }
}

// Create and export the Mongoose model
const furnitureSchema = new FurnitureSchema();
export const Furniture = model<IFurniture>('Furniture', furnitureSchema.getSchema());