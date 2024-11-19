// External dependencies
import { Request, Response } from 'express'; // v4.18.0
import { IsNotEmpty, IsMongoId, validateOrReject } from 'class-validator'; // v0.14.0
import { plainToClass } from 'class-transformer'; // v0.5.0

// Internal dependencies
import { Controller, ResponseFormat } from '../../../shared/interfaces/controller.interface';
import { NotificationService } from '../services/notification.service';
import { INotification } from '../models/notification.model';
import { Logger } from '../../../shared/utils/logger';

/**
 * Human Tasks:
 * 1. Configure authentication middleware for protected endpoints
 * 2. Set up request validation middleware
 * 3. Configure rate limiting for notification endpoints
 * 4. Set up monitoring for notification delivery metrics
 * 5. Configure error alerting for failed notification batches
 */

/**
 * Controller handling HTTP requests for notification operations
 * Requirement: Push Notification System - Real-time user alerts
 * Requirement: Real-time Messaging - Message notification support
 * Requirement: Gamification System - Achievement notifications
 */
@Controller('/notifications')
@UseGuards(AuthGuard)
export class NotificationController implements Controller<INotification> {
  private readonly logger: Logger;

  constructor(
    private readonly notificationService: NotificationService,
    logger: Logger
  ) {
    this.logger = logger;
  }

  /**
   * Creates a new notification with push delivery
   * Requirement: Push Notification System - Real-time user alerts
   */
  @Post()
  @UseValidation()
  async create(req: Request, res: Response): Promise<Response<ResponseFormat<INotification>>> {
    try {
      const userId = req.user.id; // From auth middleware
      const notificationData = plainToClass(INotification, req.body);

      // Create notification
      const notification = await this.notificationService.create(notificationData, userId);

      this.logger.info('Notification created successfully', { id: notification.id });

      return res.status(201).json({
        success: true,
        status: 201,
        message: 'Notification created successfully',
        data: notification
      });
    } catch (error) {
      this.logger.error('Failed to create notification', error);
      throw error;
    }
  }

  /**
   * Retrieves all notifications for a user with filtering
   * Requirement: Push Notification System - Notification management
   */
  @Get()
  @UseValidation()
  async findAll(req: Request, res: Response): Promise<Response<ResponseFormat<INotification[]>>> {
    try {
      const userId = req.user.id; // From auth middleware
      const { page = 1, limit = 20, type, isRead } = req.query;

      // Build filter options
      const filterOptions = {
        page: Number(page),
        limit: Number(limit),
        filters: {
          userId,
          ...(type && { type }),
          ...(isRead !== undefined && { isRead: Boolean(isRead) })
        },
        sortBy: 'createdAt',
        sortOrder: 'desc'
      };

      const notifications = await this.notificationService.findAll(filterOptions);

      return res.status(200).json({
        success: true,
        status: 200,
        message: 'Notifications retrieved successfully',
        data: notifications
      });
    } catch (error) {
      this.logger.error('Failed to retrieve notifications', error);
      throw error;
    }
  }

  /**
   * Retrieves a single notification by ID
   * Requirement: Push Notification System - Notification management
   */
  @Get('/:id')
  @UseValidation()
  async findById(req: Request, res: Response): Promise<Response<ResponseFormat<INotification>>> {
    try {
      const { id } = req.params;
      const userId = req.user.id; // From auth middleware

      // Validate notification ID
      await validateOrReject(plainToClass(class { @IsNotEmpty() @IsMongoId() id: string }, { id }));

      const notification = await this.notificationService.findById(id);

      if (!notification) {
        return res.status(404).json({
          success: false,
          status: 404,
          message: 'Notification not found'
        });
      }

      // Verify user owns the notification
      if (notification.userId !== userId) {
        return res.status(403).json({
          success: false,
          status: 403,
          message: 'Not authorized to access this notification'
        });
      }

      return res.status(200).json({
        success: true,
        status: 200,
        message: 'Notification retrieved successfully',
        data: notification
      });
    } catch (error) {
      this.logger.error('Failed to retrieve notification', error);
      throw error;
    }
  }

  /**
   * Marks a notification as read
   * Requirement: Push Notification System - Notification status management
   */
  @Patch('/:id/read')
  @UseValidation()
  async markAsRead(req: Request, res: Response): Promise<Response<ResponseFormat<INotification>>> {
    try {
      const { id } = req.params;
      const userId = req.user.id; // From auth middleware

      // Validate notification ID
      await validateOrReject(plainToClass(class { @IsNotEmpty() @IsMongoId() id: string }, { id }));

      const notification = await this.notificationService.markAsRead(id, userId);

      if (!notification) {
        return res.status(404).json({
          success: false,
          status: 404,
          message: 'Notification not found'
        });
      }

      return res.status(200).json({
        success: true,
        status: 200,
        message: 'Notification marked as read',
        data: notification
      });
    } catch (error) {
      this.logger.error('Failed to mark notification as read', error);
      throw error;
    }
  }

  /**
   * Updates notification delivery status
   * Requirement: Push Notification System - Delivery tracking
   */
  @Patch('/:id/delivered')
  @UseValidation()
  async markAsDelivered(req: Request, res: Response): Promise<Response<ResponseFormat<INotification>>> {
    try {
      const { id } = req.params;

      // Validate notification ID
      await validateOrReject(plainToClass(class { @IsNotEmpty() @IsMongoId() id: string }, { id }));

      const notification = await this.notificationService.markAsDelivered(id);

      if (!notification) {
        return res.status(404).json({
          success: false,
          status: 404,
          message: 'Notification not found'
        });
      }

      return res.status(200).json({
        success: true,
        status: 200,
        message: 'Notification marked as delivered',
        data: notification
      });
    } catch (error) {
      this.logger.error('Failed to mark notification as delivered', error);
      throw error;
    }
  }
}