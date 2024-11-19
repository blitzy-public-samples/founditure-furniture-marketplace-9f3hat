// External dependencies
import { Schema, model } from 'mongoose'; // v7.5.0
import { 
  IsNotEmpty, 
  IsMongoId, 
  IsEnum, 
  MinLength, 
  MaxLength, 
  IsOptional, 
  IsUrl, 
  IsBoolean, 
  IsDate 
} from 'class-validator'; // v0.14.0

// Internal dependencies
import { BaseModel } from '../../../shared/interfaces/model.interface';
import { NotificationType } from '../../../shared/types';

/**
 * Human Tasks:
 * 1. Ensure MongoDB indexes are created for frequently queried fields (userId, type, isRead)
 * 2. Configure MongoDB TTL index for notification expiration if needed
 * 3. Set up proper validation error handling middleware
 * 4. Configure notification delivery tracking mechanism
 * 5. Set up monitoring for notification delivery metrics
 */

/**
 * Interface for notification entities with full auditing support
 * Requirement: Push Notification System - Defines structure for real-time user alerts
 * Requirement: Real-time Messaging - Supports message-related notifications
 * Requirement: Gamification System - Enables achievement notifications
 */
export interface INotification extends BaseModel {
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  imageUrl?: string;
  actionUrl?: string;
  metadata?: Record<string, any>;
  isRead: boolean;
  readAt?: Date;
  isDelivered: boolean;
  deliveredAt?: Date;
}

/**
 * Mongoose schema for notification entities with validation
 * Requirement: Push Notification System - Implements notification data structure
 */
@Schema({ timestamps: true })
class NotificationSchema {
  @IsNotEmpty()
  @IsMongoId()
  userId: string;

  @IsNotEmpty()
  @IsEnum(NotificationType)
  type: NotificationType;

  @IsNotEmpty()
  @MinLength(1)
  @MaxLength(100)
  title: string;

  @IsNotEmpty()
  @MinLength(1)
  @MaxLength(500)
  message: string;

  @IsOptional()
  @IsUrl()
  imageUrl?: string;

  @IsOptional()
  @IsUrl()
  actionUrl?: string;

  @IsOptional()
  metadata?: Record<string, any>;

  @IsBoolean()
  isRead: boolean = false;

  @IsOptional()
  @IsDate()
  readAt?: Date;

  @IsBoolean()
  isDelivered: boolean = false;

  @IsOptional()
  @IsDate()
  deliveredAt?: Date;

  /**
   * Transform method for JSON serialization
   * Removes internal MongoDB fields and formats dates
   */
  toJSON() {
    const obj = this.toObject();
    
    // Remove MongoDB internal fields
    delete obj._id;
    delete obj.__v;

    // Convert dates to ISO strings
    if (obj.createdAt) obj.createdAt = obj.createdAt.toISOString();
    if (obj.updatedAt) obj.updatedAt = obj.updatedAt.toISOString();
    if (obj.readAt) obj.readAt = obj.readAt.toISOString();
    if (obj.deliveredAt) obj.deliveredAt = obj.deliveredAt.toISOString();

    // Remove null/undefined fields
    Object.keys(obj).forEach(key => {
      if (obj[key] === null || obj[key] === undefined) {
        delete obj[key];
      }
    });

    return obj;
  }
}

// Create indexes for frequently queried fields
const notificationSchema = new Schema<INotification>(NotificationSchema, { 
  timestamps: true,
  collection: 'notifications'
});

notificationSchema.index({ userId: 1 });
notificationSchema.index({ type: 1 });
notificationSchema.index({ isRead: 1 });
notificationSchema.index({ createdAt: 1 });

/**
 * Mongoose model for notification operations
 * Requirement: Push Notification System - Enables notification CRUD operations
 */
export const NotificationModel = model<INotification>('Notification', notificationSchema);