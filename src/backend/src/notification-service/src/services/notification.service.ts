// External dependencies
import { Injectable } from '@nestjs/common'; // v9.0.0
import { Model } from 'mongoose'; // v7.5.0
import { plainToClass } from 'class-transformer'; // v0.5.0
import { validateOrReject } from 'class-validator'; // v0.14.0

// Internal dependencies
import { Service, FilterOptions, ValidationResult } from '../../../shared/interfaces/service.interface';
import { INotification, NotificationModel } from '../models/notification.model';
import { sendPushNotification } from '../utils/push.util';
import { Logger } from '../../../shared/utils/logger';
import { NotificationType } from '../../../shared/types';

/**
 * Human Tasks:
 * 1. Configure Firebase Cloud Messaging credentials in environment
 * 2. Set up monitoring for notification delivery metrics
 * 3. Configure error alerting for failed notification batches
 * 4. Set up notification retention policy and archival strategy
 * 5. Configure rate limiting for notification sending
 */

@Injectable()
export class NotificationService implements Service<INotification> {
  private readonly logger: Logger;

  constructor(
    private readonly Model: Model<INotification>,
    logger: Logger
  ) {
    this.logger = logger;
  }

  /**
   * Creates a new notification and attempts push delivery
   * Requirement: Push Notification System - Real-time user alerts
   */
  async create(data: Partial<INotification>, userId: string): Promise<INotification> {
    try {
      // Validate notification data
      const validationResult = await this.validate(data);
      if (!validationResult.isValid) {
        this.logger.error('Notification validation failed', null, { errors: validationResult.errors });
        throw new Error('Invalid notification data');
      }

      // Create notification document
      const notification = new this.Model({
        ...data,
        userId,
        isRead: false,
        isDelivered: false,
        createdBy: userId,
        updatedBy: userId
      });

      // Save to database
      const savedNotification = await notification.save();
      this.logger.info('Notification created', { id: savedNotification.id });

      // Attempt push notification delivery if applicable
      if (data.type !== NotificationType.SYSTEM) {
        try {
          // Get user's device tokens (implementation depends on user service)
          const deviceTokens = await this.getUserDeviceTokens(userId);
          
          if (deviceTokens.length > 0) {
            const delivered = await sendPushNotification(savedNotification, deviceTokens);
            
            if (delivered) {
              await this.markAsDelivered(savedNotification.id);
              this.logger.info('Push notification delivered', { id: savedNotification.id });
            }
          }
        } catch (error) {
          this.logger.error('Push notification delivery failed', error, { id: savedNotification.id });
        }
      }

      return savedNotification;
    } catch (error) {
      this.logger.error('Failed to create notification', error);
      throw error;
    }
  }

  /**
   * Retrieves notifications with filtering and pagination
   * Requirement: Real-time Messaging - Message notification support
   */
  async findAll(options: FilterOptions): Promise<INotification[]> {
    try {
      const { page = 1, limit = 10, filters = {}, sortBy = 'createdAt', sortOrder = 'desc' } = options;
      
      // Build query
      const query = this.Model.find({ isActive: true, ...filters })
        .sort({ [sortBy]: sortOrder })
        .skip((page - 1) * limit)
        .limit(limit);

      const notifications = await query.exec();
      this.logger.info('Retrieved notifications', { count: notifications.length });
      
      return notifications;
    } catch (error) {
      this.logger.error('Failed to retrieve notifications', error);
      throw error;
    }
  }

  /**
   * Retrieves a single notification by ID
   * Requirement: Push Notification System - Notification management
   */
  async findById(id: string): Promise<INotification | null> {
    try {
      const notification = await this.Model.findOne({ _id: id, isActive: true });
      
      if (!notification) {
        this.logger.warn('Notification not found', { id });
        return null;
      }

      return notification;
    } catch (error) {
      this.logger.error('Failed to retrieve notification', error, { id });
      throw error;
    }
  }

  /**
   * Updates an existing notification
   * Requirement: Push Notification System - Notification management
   */
  async update(id: string, data: Partial<INotification>, userId: string): Promise<INotification> {
    try {
      // Validate update data
      const validationResult = await this.validate(data);
      if (!validationResult.isValid) {
        this.logger.error('Notification update validation failed', null, { errors: validationResult.errors });
        throw new Error('Invalid update data');
      }

      const notification = await this.Model.findOneAndUpdate(
        { _id: id, isActive: true },
        { 
          ...data,
          updatedBy: userId,
          updatedAt: new Date()
        },
        { new: true }
      );

      if (!notification) {
        throw new Error('Notification not found');
      }

      this.logger.info('Notification updated', { id });
      return notification;
    } catch (error) {
      this.logger.error('Failed to update notification', error, { id });
      throw error;
    }
  }

  /**
   * Soft deletes a notification
   * Requirement: Push Notification System - Notification management
   */
  async delete(id: string, userId: string): Promise<boolean> {
    try {
      const result = await this.Model.findOneAndUpdate(
        { _id: id, isActive: true },
        { 
          isActive: false,
          updatedBy: userId,
          updatedAt: new Date()
        }
      );

      if (!result) {
        throw new Error('Notification not found');
      }

      this.logger.info('Notification deleted', { id });
      return true;
    } catch (error) {
      this.logger.error('Failed to delete notification', error, { id });
      throw error;
    }
  }

  /**
   * Validates notification data against schema
   * Requirement: Push Notification System - Data validation
   */
  async validate(data: Partial<INotification>): Promise<ValidationResult> {
    try {
      const notification = plainToClass(NotificationModel, data);
      await validateOrReject(notification);
      
      return {
        isValid: true,
        errors: []
      };
    } catch (errors) {
      return {
        isValid: false,
        errors: errors.map(error => ({
          field: error.property,
          message: Object.values(error.constraints)[0],
          code: 'VALIDATION_ERROR'
        }))
      };
    }
  }

  /**
   * Marks a notification as read
   * Requirement: Push Notification System - Notification status management
   */
  async markAsRead(id: string, userId: string): Promise<INotification> {
    try {
      const notification = await this.Model.findOneAndUpdate(
        { _id: id, userId, isActive: true },
        { 
          isRead: true,
          readAt: new Date(),
          updatedBy: userId,
          updatedAt: new Date()
        },
        { new: true }
      );

      if (!notification) {
        throw new Error('Notification not found');
      }

      this.logger.info('Notification marked as read', { id });
      return notification;
    } catch (error) {
      this.logger.error('Failed to mark notification as read', error, { id });
      throw error;
    }
  }

  /**
   * Updates notification delivery status
   * Requirement: Push Notification System - Delivery tracking
   */
  async markAsDelivered(id: string): Promise<INotification> {
    try {
      const notification = await this.Model.findOneAndUpdate(
        { _id: id, isActive: true },
        { 
          isDelivered: true,
          deliveredAt: new Date(),
          updatedAt: new Date()
        },
        { new: true }
      );

      if (!notification) {
        throw new Error('Notification not found');
      }

      this.logger.info('Notification marked as delivered', { id });
      return notification;
    } catch (error) {
      this.logger.error('Failed to mark notification as delivered', error, { id });
      throw error;
    }
  }

  /**
   * Helper method to get user's device tokens
   * Implementation depends on user service integration
   */
  private async getUserDeviceTokens(userId: string): Promise<string[]> {
    // TODO: Implement user service integration to fetch device tokens
    // This is a placeholder implementation
    return [];
  }
}