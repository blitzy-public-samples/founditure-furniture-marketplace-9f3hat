/**
 * Human Tasks:
 * 1. Configure rate limiting middleware for points-related endpoints
 * 2. Set up monitoring alerts for suspicious points activity
 * 3. Configure request validation middleware
 * 4. Review and adjust error handling strategies
 * 5. Set up API documentation generation
 */

// External dependencies
import { Request, Response } from 'express'; // v4.18.0
import httpStatus from 'http-status'; // v1.6.0

// Internal dependencies
import { Controller } from '../../../shared/interfaces/controller.interface';
import { PointsService } from '../services/points.service';
import { IPointsTransaction } from '../models/points.model';
import { Logger } from '../../../shared/utils/logger';
import { ValidationError } from '../../../shared/utils/error';
import { PAGINATION_DEFAULTS } from '../../../shared/constants';

/**
 * Controller handling HTTP requests for points-related operations
 * Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
 * Requirement: 2.3.1 API Gateway - Standardized REST endpoints
 */
export class PointsController implements Controller<IPointsTransaction> {
  private logger: Logger;

  constructor(private pointsService: PointsService) {
    this.logger = new Logger('PointsController');
  }

  /**
   * Awards points to a user for specific actions
   * Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
   * Requirement: 1.2 System Overview/Success Criteria - User Engagement through gamification
   */
  public awardPoints = async (req: Request, res: Response): Promise<Response> => {
    try {
      const { userId, amount, source, referenceId } = req.body;

      // Validate required fields
      if (!userId || !amount || !source) {
        throw new ValidationError('Missing required fields', {
          userId,
          amount,
          source
        });
      }

      const transaction = await this.pointsService.awardPoints(
        userId,
        amount,
        source,
        referenceId
      );

      this.logger.info('Points awarded successfully', {
        userId,
        amount,
        source,
        transactionId: transaction.id
      });

      return res.status(httpStatus.CREATED).json({
        success: true,
        status: httpStatus.CREATED,
        message: 'Points awarded successfully',
        data: transaction
      });
    } catch (error) {
      this.logger.error('Error awarding points', error as Error, {
        body: req.body
      });
      throw error;
    }
  };

  /**
   * Retrieves user's current points balance and stats
   * Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
   */
  public getUserPoints = async (req: Request, res: Response): Promise<Response> => {
    try {
      const { userId } = req.params;

      if (!userId) {
        throw new ValidationError('User ID is required');
      }

      const pointsData = await this.pointsService.getUserPoints(userId);

      return res.status(httpStatus.OK).json({
        success: true,
        status: httpStatus.OK,
        message: 'User points retrieved successfully',
        data: pointsData
      });
    } catch (error) {
      this.logger.error('Error retrieving user points', error as Error, {
        params: req.params
      });
      throw error;
    }
  };

  /**
   * Retrieves paginated points transaction history for a user
   * Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
   */
  public getTransactionHistory = async (req: Request, res: Response): Promise<Response> => {
    try {
      const { userId } = req.params;
      const { 
        page = 1, 
        limit = PAGINATION_DEFAULTS.DEFAULT_PAGE_SIZE,
        sortBy = 'createdAt',
        sortOrder = 'desc',
        ...filters 
      } = req.query;

      if (!userId) {
        throw new ValidationError('User ID is required');
      }

      const transactions = await this.pointsService.getTransactionHistory(userId, {
        page: Number(page),
        limit: Math.min(Number(limit), PAGINATION_DEFAULTS.MAX_PAGE_SIZE),
        sortBy: String(sortBy),
        sortOrder: String(sortOrder),
        filters
      });

      return res.status(httpStatus.OK).json({
        success: true,
        status: httpStatus.OK,
        message: 'Transaction history retrieved successfully',
        data: transactions
      });
    } catch (error) {
      this.logger.error('Error retrieving transaction history', error as Error, {
        params: req.params,
        query: req.query
      });
      throw error;
    }
  };

  /**
   * Creates a new points transaction
   * Requirement: 3.2.2 Data Management Strategy - Consistent data operations
   */
  public create = async (req: Request, res: Response): Promise<Response> => {
    try {
      const transaction = await this.pointsService.create(
        req.body,
        req.body.userId
      );

      return res.status(httpStatus.CREATED).json({
        success: true,
        status: httpStatus.CREATED,
        message: 'Points transaction created successfully',
        data: transaction
      });
    } catch (error) {
      this.logger.error('Error creating points transaction', error as Error, {
        body: req.body
      });
      throw error;
    }
  };

  /**
   * Retrieves all points transactions with filtering
   * Requirement: 3.2.2 Data Management Strategy - Consistent data operations
   */
  public findAll = async (req: Request, res: Response): Promise<Response> => {
    try {
      const { 
        page = 1, 
        limit = PAGINATION_DEFAULTS.DEFAULT_PAGE_SIZE,
        sortBy = 'createdAt',
        sortOrder = 'desc',
        ...filters 
      } = req.query;

      const transactions = await this.pointsService.findAll({
        page: Number(page),
        limit: Math.min(Number(limit), PAGINATION_DEFAULTS.MAX_PAGE_SIZE),
        sortBy: String(sortBy),
        sortOrder: String(sortOrder),
        filters
      });

      return res.status(httpStatus.OK).json({
        success: true,
        status: httpStatus.OK,
        message: 'Points transactions retrieved successfully',
        data: transactions
      });
    } catch (error) {
      this.logger.error('Error retrieving points transactions', error as Error, {
        query: req.query
      });
      throw error;
    }
  };

  /**
   * Retrieves a single points transaction by ID
   * Requirement: 3.2.2 Data Management Strategy - Consistent data operations
   */
  public findById = async (req: Request, res: Response): Promise<Response> => {
    try {
      const { id } = req.params;

      if (!id) {
        throw new ValidationError('Transaction ID is required');
      }

      const transaction = await this.pointsService.findById(id);

      if (!transaction) {
        return res.status(httpStatus.NOT_FOUND).json({
          success: false,
          status: httpStatus.NOT_FOUND,
          message: 'Points transaction not found'
        });
      }

      return res.status(httpStatus.OK).json({
        success: true,
        status: httpStatus.OK,
        message: 'Points transaction retrieved successfully',
        data: transaction
      });
    } catch (error) {
      this.logger.error('Error retrieving points transaction', error as Error, {
        params: req.params
      });
      throw error;
    }
  };

  /**
   * Updates an existing points transaction
   * Requirement: 3.2.2 Data Management Strategy - Consistent data operations
   */
  public update = async (req: Request, res: Response): Promise<Response> => {
    try {
      const { id } = req.params;
      const { userId } = req.body;

      if (!id) {
        throw new ValidationError('Transaction ID is required');
      }

      const transaction = await this.pointsService.update(
        id,
        req.body,
        userId
      );

      return res.status(httpStatus.OK).json({
        success: true,
        status: httpStatus.OK,
        message: 'Points transaction updated successfully',
        data: transaction
      });
    } catch (error) {
      this.logger.error('Error updating points transaction', error as Error, {
        params: req.params,
        body: req.body
      });
      throw error;
    }
  };

  /**
   * Soft deletes a points transaction
   * Requirement: 3.2.2 Data Management Strategy - Consistent data operations
   */
  public delete = async (req: Request, res: Response): Promise<Response> => {
    try {
      const { id } = req.params;
      const { userId } = req.body;

      if (!id) {
        throw new ValidationError('Transaction ID is required');
      }

      const deleted = await this.pointsService.delete(id, userId);

      return res.status(httpStatus.OK).json({
        success: true,
        status: httpStatus.OK,
        message: 'Points transaction deleted successfully',
        data: { deleted }
      });
    } catch (error) {
      this.logger.error('Error deleting points transaction', error as Error, {
        params: req.params
      });
      throw error;
    }
  };
}