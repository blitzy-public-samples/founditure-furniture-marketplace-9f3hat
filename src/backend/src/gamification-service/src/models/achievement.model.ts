// External dependencies
import { Schema, model } from 'mongoose'; // v7.5.0

// Internal dependencies
import { BaseModel } from '../../shared/interfaces/model.interface';

/**
 * Human Tasks:
 * 1. Set up MongoDB indexes for optimized achievement queries
 * 2. Configure CDN/storage for badge image URLs
 * 3. Set up monitoring for achievement completion rates
 * 4. Configure caching strategy for frequently accessed achievements
 */

/**
 * Achievement categories enum
 * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
 */
export enum AchievementCategory {
  FINDER = 'FINDER',
  COLLECTOR = 'COLLECTOR',
  COMMUNITY = 'COMMUNITY',
  MILESTONE = 'MILESTONE'
}

/**
 * Achievement tiers enum
 * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
 */
export enum AchievementTier {
  BRONZE = 'BRONZE',
  SILVER = 'SILVER',
  GOLD = 'GOLD',
  PLATINUM = 'PLATINUM'
}

/**
 * Achievement interface extending BaseModel
 * Requirement: Gamification System - User Engagement: 70% monthly active user retention
 */
export interface IAchievement extends BaseModel {
  name: string;
  description: string;
  category: AchievementCategory;
  pointsReward: number;
  criteria: Record<string, any>;
  badgeUrl: string;
  tier: AchievementTier;
  createdBy: string;
  updatedBy: string;
}

/**
 * User Achievement Progress interface extending BaseModel
 * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
 */
export interface IUserAchievement extends BaseModel {
  userId: string;
  achievementId: string;
  progress: number;
  isCompleted: boolean;
  completedAt?: Date;
  metadata?: Record<string, any>;
  createdBy: string;
  updatedBy: string;
}

/**
 * Achievement Schema definition
 * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
 */
const AchievementSchema = new Schema({
  name: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    index: true
  },
  description: {
    type: String,
    required: true,
    trim: true
  },
  category: {
    type: String,
    enum: Object.values(AchievementCategory),
    required: true,
    index: true
  },
  pointsReward: {
    type: Number,
    required: true,
    min: 0,
    validate: {
      validator: Number.isInteger,
      message: 'Points reward must be an integer'
    }
  },
  criteria: {
    type: Schema.Types.Mixed,
    required: true
  },
  badgeUrl: {
    type: String,
    required: true,
    trim: true,
    validate: {
      validator: (v: string) => /^https?:\/\/.+/.test(v),
      message: 'Badge URL must be a valid URL'
    }
  },
  tier: {
    type: String,
    enum: Object.values(AchievementTier),
    required: true,
    index: true
  },
  isActive: {
    type: Boolean,
    default: true,
    index: true
  },
  createdAt: {
    type: Date,
    default: Date.now,
    index: true
  },
  updatedAt: {
    type: Date,
    default: Date.now
  },
  createdBy: {
    type: String,
    required: true,
    index: true
  },
  updatedBy: {
    type: String,
    required: true
  }
}, {
  timestamps: true,
  versionKey: false,
  toJSON: {
    virtuals: true,
    transform: function(doc, ret) {
      ret.id = ret._id;
      delete ret._id;
      return ret;
    }
  }
});

/**
 * Achievement Schema indexes
 * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
 */
AchievementSchema.index({ name: 1, category: 1 }, { unique: true });
AchievementSchema.index({ tier: 1, pointsReward: -1 });
AchievementSchema.index({ isActive: 1, category: 1 });

/**
 * Achievement Schema middleware
 */
AchievementSchema.pre('save', function(next) {
  if (this.isNew) {
    this.createdAt = new Date();
  }
  this.updatedAt = new Date();
  next();
});

/**
 * Achievement Model
 * Requirement: Gamification System - User Engagement: 70% monthly active user retention
 */
const Achievement = model<IAchievement>('Achievement', AchievementSchema);

export default Achievement;