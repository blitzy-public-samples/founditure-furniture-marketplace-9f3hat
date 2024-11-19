// External dependencies
import { Schema, Document } from 'mongoose'; // v7.5.0

// Internal dependencies
import { BaseModel } from '../../../shared/interfaces/model.interface';
import { EntityStatus } from '../../../shared/types';

/**
 * Human Tasks:
 * 1. Configure MongoDB time-series collections for metrics data
 * 2. Set up data archival and retention policies for metrics
 * 3. Configure proper indexes for time-based queries
 * 4. Ensure proper monitoring for metrics collection performance
 * 5. Set up backup strategy for analytics data
 */

/**
 * Interface for tracking user-related metrics and engagement
 * Requirement: Success Criteria Tracking - Track user adoption metrics
 */
export interface UserMetrics extends BaseModel {
  userId: string;
  listingsCreated: number;
  itemsCollected: number;
  totalPoints: number;
  achievementsEarned: number;
  messagesSent: number;
  lastActive: Date;
  isActive: boolean;
  createdBy: string;
  updatedBy: string;
}

/**
 * Interface for tracking furniture listing performance metrics
 * Requirement: Success Criteria Tracking - Track furniture recovery metrics
 */
export interface ListingMetrics extends BaseModel {
  listingId: string;
  furnitureType: string;
  condition: string;
  location: string;
  viewCount: number;
  messageCount: number;
  timeToCollection: number;
  wasCollected: boolean;
  isActive: boolean;
  createdBy: string;
  updatedBy: string;
}

/**
 * Interface for tracking community-level engagement metrics
 * Requirement: Success Criteria Tracking - Track community growth metrics
 */
export interface CommunityMetrics extends BaseModel {
  region: string;
  activeUsers: number;
  totalListings: number;
  successfulCollections: number;
  averageResponseTime: number;
  communityEngagement: number;
  isActive: boolean;
  createdBy: string;
  updatedBy: string;
}

/**
 * Interface for tracking environmental impact metrics
 * Requirement: Analytics Platform - Measuring environmental impact metrics
 */
export interface EnvironmentalImpact extends BaseModel {
  wasteReduced: number;
  carbonSaved: number;
  itemsRecycled: number;
  impactRegion: string;
  measurementPeriod: Date;
  isActive: boolean;
  createdBy: string;
  updatedBy: string;
}

/**
 * Schema for user metrics with time-based partitioning
 * Requirement: Data Management Strategy - Time-based partitioning
 */
const UserMetricsSchema = new Schema<UserMetrics>({
  userId: { type: String, required: true, index: true },
  listingsCreated: { type: Number, default: 0 },
  itemsCollected: { type: Number, default: 0 },
  totalPoints: { type: Number, default: 0 },
  achievementsEarned: { type: Number, default: 0 },
  messagesSent: { type: Number, default: 0 },
  lastActive: { type: Date, required: true },
  isActive: { type: Boolean, default: true },
  createdBy: { type: String, required: true },
  updatedBy: { type: String, required: true }
}, {
  timestamps: true,
  timeseries: {
    timeField: 'createdAt',
    granularity: 'hours'
  }
});

/**
 * Schema for listing metrics with performance tracking
 * Requirement: Analytics Platform - Measuring platform performance
 */
const ListingMetricsSchema = new Schema<ListingMetrics>({
  listingId: { type: String, required: true, index: true },
  furnitureType: { type: String, required: true },
  condition: { type: String, required: true },
  location: { type: String, required: true },
  viewCount: { type: Number, default: 0 },
  messageCount: { type: Number, default: 0 },
  timeToCollection: { type: Number },
  wasCollected: { type: Boolean, default: false },
  isActive: { type: Boolean, default: true },
  createdBy: { type: String, required: true },
  updatedBy: { type: String, required: true }
}, {
  timestamps: true,
  timeseries: {
    timeField: 'createdAt',
    granularity: 'hours'
  }
});

/**
 * Schema for community metrics with regional tracking
 * Requirement: Success Criteria Tracking - Track community growth
 */
const CommunityMetricsSchema = new Schema<CommunityMetrics>({
  region: { type: String, required: true, index: true },
  activeUsers: { type: Number, default: 0 },
  totalListings: { type: Number, default: 0 },
  successfulCollections: { type: Number, default: 0 },
  averageResponseTime: { type: Number, default: 0 },
  communityEngagement: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true },
  createdBy: { type: String, required: true },
  updatedBy: { type: String, required: true }
}, {
  timestamps: true,
  timeseries: {
    timeField: 'createdAt',
    granularity: 'days'
  }
});

/**
 * Schema for environmental impact metrics with regional tracking
 * Requirement: Analytics Platform - Environmental impact metrics
 */
const EnvironmentalImpactSchema = new Schema<EnvironmentalImpact>({
  wasteReduced: { type: Number, required: true },
  carbonSaved: { type: Number, required: true },
  itemsRecycled: { type: Number, required: true },
  impactRegion: { type: String, required: true, index: true },
  measurementPeriod: { type: Date, required: true },
  isActive: { type: Boolean, default: true },
  createdBy: { type: String, required: true },
  updatedBy: { type: String, required: true }
}, {
  timestamps: true,
  timeseries: {
    timeField: 'measurementPeriod',
    granularity: 'days'
  }
});

// Create indexes for efficient querying
UserMetricsSchema.index({ createdAt: 1 });
ListingMetricsSchema.index({ createdAt: 1 });
CommunityMetricsSchema.index({ createdAt: 1, region: 1 });
EnvironmentalImpactSchema.index({ measurementPeriod: 1, impactRegion: 1 });

// Add status change tracking
[UserMetricsSchema, ListingMetricsSchema, CommunityMetricsSchema, EnvironmentalImpactSchema].forEach(schema => {
  schema.pre('save', function(next) {
    if (this.isModified('isActive')) {
      this.set('updatedAt', new Date());
    }
    next();
  });
});