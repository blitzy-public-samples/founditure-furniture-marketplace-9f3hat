/**
 * Human Tasks:
 * 1. Ensure MongoDB indexes are created during application startup
 * 2. Configure MongoDB change streams for real-time points updates if needed
 * 3. Set up proper user context management for audit fields (createdBy/updatedBy)
 * 4. Configure monitoring for points transactions to detect potential abuse
 */

// External dependencies
import { Schema, model } from 'mongoose'; // v7.5.0

// Internal dependencies
import { BaseModel } from '../../shared/interfaces/model.interface';

/**
 * Points Transaction Types Enum
 * Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
 */
export enum PointsTransactionType {
  EARNED = 'EARNED',
  SPENT = 'SPENT',
  BONUS = 'BONUS',
  ACHIEVEMENT = 'ACHIEVEMENT'
}

/**
 * Points Source Types Enum
 * Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
 */
export enum PointsSourceType {
  LISTING_CREATED = 'LISTING_CREATED',
  ITEM_COLLECTED = 'ITEM_COLLECTED',
  ACHIEVEMENT_COMPLETED = 'ACHIEVEMENT_COMPLETED',
  COMMUNITY_ACTION = 'COMMUNITY_ACTION'
}

/**
 * Points Transaction Interface
 * Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
 * Requirement: 3.2.2 Data Management Strategy - Implements consistent data structure
 */
export interface IPointsTransaction extends BaseModel {
  userId: string;
  amount: number;
  type: PointsTransactionType;
  source: PointsSourceType;
  referenceId?: string;
  metadata?: Record<string, any>;
  createdBy: string;
  updatedBy: string;
}

/**
 * User Points Interface
 * Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
 * Requirement: 1.2 System Overview/Success Criteria - User Engagement through gamification
 */
export interface IUserPoints extends BaseModel {
  userId: string;
  totalPoints: number;
  level: number;
  lifetimePoints: number;
  stats: {
    earned: number;
    spent: number;
    bonus: number;
    achievement: number;
    bySource: {
      [key in PointsSourceType]: number;
    };
  };
  createdBy: string;
  updatedBy: string;
}

/**
 * Points Transaction Schema
 * Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
 * Requirement: 3.2.2 Data Management Strategy - Implements consistent data structure
 */
const PointsTransactionSchema = new Schema({
  userId: {
    type: String,
    required: true,
    index: true,
  },
  amount: {
    type: Number,
    required: true,
  },
  type: {
    type: String,
    enum: Object.values(PointsTransactionType),
    required: true,
    index: true,
  },
  source: {
    type: String,
    enum: Object.values(PointsSourceType),
    required: true,
    index: true,
  },
  referenceId: {
    type: String,
    required: false,
    sparse: true,
  },
  metadata: {
    type: Schema.Types.Mixed,
    required: false,
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
    required: true,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
    required: true,
  },
  createdBy: {
    type: String,
    required: true,
  },
  updatedBy: {
    type: String,
    required: true,
  },
}, {
  timestamps: true,
  versionKey: false,
});

/**
 * Indexes for optimizing queries
 * Requirement: 3.2.2 Data Management Strategy - Implements consistent data structure
 */
PointsTransactionSchema.index({ userId: 1, createdAt: -1 });
PointsTransactionSchema.index({ userId: 1, type: 1 });
PointsTransactionSchema.index({ userId: 1, source: 1 });

/**
 * Pre-save middleware to ensure updatedAt is set
 */
PointsTransactionSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

/**
 * Points Transaction Model
 * Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
 */
const PointsTransaction = model<IPointsTransaction>('PointsTransaction', PointsTransactionSchema);

export default PointsTransaction;