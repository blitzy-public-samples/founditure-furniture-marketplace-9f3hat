/**
 * Human Tasks:
 * 1. Configure MongoDB indexes for points transactions and user points collections
 * 2. Set up monitoring alerts for suspicious points activity patterns
 * 3. Configure rate limiting for points-related operations
 * 4. Review and adjust level progression formula with product team
 * 5. Set up automated backup for points-related collections
 */

// External dependencies
import mongoose from 'mongoose'; // v7.5.0
import { Subject } from 'rxjs'; // v7.8.1

// Internal dependencies
import { Service } from '../../../shared/interfaces/service.interface';
import { IPointsTransaction, IUserPoints, PointsTransactionType, PointsSourceType } from '../models/points.model';
import { Logger } from '../../../shared/utils/logger';

/**
 * Points event interface for reactive updates
 * Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
 */
interface PointsEvent {
  userId: string;
  type: PointsTransactionType;
  amount: number;
  source: PointsSourceType;
  newTotal: number;
  newLevel?: number;
}

/**
 * Points service implementation for managing user points and transactions
 * Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
 * Requirement: 1.2 System Overview/Success Criteria - User Engagement through gamification
 */
export class PointsService implements Service<IPointsTransaction> {
  private logger: Logger;
  private pointsEvents$: Subject<PointsEvent>;
  private readonly LEVEL_MULTIPLIER = 100; // Points needed per level
  private readonly MAX_LEVEL = 100;

  constructor(
    private transactionModel: mongoose.Model<IPointsTransaction>,
    private userPointsModel: mongoose.Model<IUserPoints>
  ) {
    this.logger = new Logger('PointsService');
    this.pointsEvents$ = new Subject<PointsEvent>();
    this.setupTransactionMonitoring();
  }

  /**
   * Awards points to a user for specific actions
   * Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
   */
  async awardPoints(
    userId: string,
    amount: number,
    source: PointsSourceType,
    referenceId: string
  ): Promise<IPointsTransaction> {
    try {
      // Validate points amount
      if (amount <= 0) {
        throw new Error('Points amount must be positive');
      }

      // Create points transaction
      const transaction = await this.create({
        userId,
        amount,
        type: PointsTransactionType.EARNED,
        source,
        referenceId,
        isActive: true,
        createdBy: userId,
        updatedBy: userId
      }, userId);

      // Update user points
      const userPoints = await this.userPointsModel.findOneAndUpdate(
        { userId },
        {
          $inc: {
            totalPoints: amount,
            lifetimePoints: amount,
            'stats.earned': amount,
            [`stats.bySource.${source}`]: amount
          }
        },
        { new: true, upsert: true }
      );

      // Calculate new level
      const oldLevel = userPoints.level;
      const newLevel = this.calculateLevel(userPoints.totalPoints);

      // Update level if changed
      if (newLevel !== oldLevel) {
        await this.userPointsModel.updateOne(
          { userId },
          { $set: { level: newLevel } }
        );
      }

      // Emit points awarded event
      this.pointsEvents$.next({
        userId,
        type: PointsTransactionType.EARNED,
        amount,
        source,
        newTotal: userPoints.totalPoints,
        newLevel: newLevel !== oldLevel ? newLevel : undefined
      });

      this.logger.info('Points awarded successfully', {
        userId,
        amount,
        source,
        newLevel
      });

      return transaction;
    } catch (error) {
      this.logger.error('Error awarding points', error as Error, {
        userId,
        amount,
        source
      });
      throw error;
    }
  }

  /**
   * Retrieves user's points balance and statistics
   * Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
   */
  async getUserPoints(userId: string): Promise<IUserPoints> {
    try {
      const userPoints = await this.userPointsModel.findOne({ userId });
      if (!userPoints) {
        // Initialize new user points record
        return this.userPointsModel.create({
          userId,
          totalPoints: 0,
          lifetimePoints: 0,
          level: 1,
          stats: {
            earned: 0,
            spent: 0,
            bonus: 0,
            achievement: 0,
            bySource: Object.values(PointsSourceType).reduce((acc, source) => {
              acc[source] = 0;
              return acc;
            }, {} as Record<PointsSourceType, number>)
          },
          isActive: true,
          createdBy: userId,
          updatedBy: userId
        });
      }
      return userPoints;
    } catch (error) {
      this.logger.error('Error retrieving user points', error as Error, { userId });
      throw error;
    }
  }

  /**
   * Retrieves user's points transaction history
   * Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
   */
  async getTransactionHistory(userId: string, options: FilterOptions): Promise<IPointsTransaction[]> {
    try {
      const { page = 1, limit = 20, filters = {}, sortBy = 'createdAt', sortOrder = 'desc' } = options;

      const query = {
        userId,
        isActive: true,
        ...filters
      };

      const transactions = await this.transactionModel
        .find(query)
        .sort({ [sortBy]: sortOrder === 'desc' ? -1 : 1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .exec();

      return transactions;
    } catch (error) {
      this.logger.error('Error retrieving transaction history', error as Error, { userId });
      throw error;
    }
  }

  /**
   * Calculates user level based on total points
   * Requirement: 1.2 System Overview/Success Criteria - User Engagement through gamification
   */
  private calculateLevel(points: number): number {
    const level = Math.floor(Math.sqrt(points / this.LEVEL_MULTIPLIER)) + 1;
    return Math.min(Math.max(level, 1), this.MAX_LEVEL);
  }

  /**
   * Sets up monitoring for suspicious points transactions
   * Requirement: 5.3.4 Security Monitoring - Log collection and analysis
   */
  private setupTransactionMonitoring(): void {
    this.pointsEvents$.subscribe(event => {
      // Monitor for potential points abuse
      if (event.amount > 1000) {
        this.logger.warn('Large points transaction detected', {
          userId: event.userId,
          amount: event.amount,
          source: event.source
        });
      }
    });
  }

  /**
   * Creates a new points transaction
   * Requirement: 3.2.2 Data Management Strategy - Consistent data operations
   */
  async create(data: Partial<IPointsTransaction>, userId: string): Promise<IPointsTransaction> {
    try {
      const validationResult = await this.validate(data);
      if (!validationResult.isValid) {
        throw new Error(`Invalid transaction data: ${validationResult.errors.map(e => e.message).join(', ')}`);
      }

      const transaction = new this.transactionModel({
        ...data,
        createdBy: userId,
        updatedBy: userId
      });

      return await transaction.save();
    } catch (error) {
      this.logger.error('Error creating points transaction', error as Error, { data });
      throw error;
    }
  }

  /**
   * Retrieves all points transactions with filtering
   * Requirement: 3.2.2 Data Management Strategy - Consistent data operations
   */
  async findAll(options: FilterOptions): Promise<IPointsTransaction[]> {
    const { page = 1, limit = 20, filters = {}, sortBy = 'createdAt', sortOrder = 'desc' } = options;

    return this.transactionModel
      .find({ isActive: true, ...filters })
      .sort({ [sortBy]: sortOrder === 'desc' ? -1 : 1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .exec();
  }

  /**
   * Retrieves a single points transaction by ID
   * Requirement: 3.2.2 Data Management Strategy - Consistent data operations
   */
  async findById(id: string): Promise<IPointsTransaction | null> {
    return this.transactionModel.findOne({ _id: id, isActive: true });
  }

  /**
   * Updates an existing points transaction
   * Requirement: 3.2.2 Data Management Strategy - Consistent data operations
   */
  async update(id: string, data: Partial<IPointsTransaction>, userId: string): Promise<IPointsTransaction> {
    const validationResult = await this.validate(data);
    if (!validationResult.isValid) {
      throw new Error(`Invalid transaction data: ${validationResult.errors.map(e => e.message).join(', ')}`);
    }

    return this.transactionModel.findOneAndUpdate(
      { _id: id, isActive: true },
      { ...data, updatedBy: userId },
      { new: true }
    );
  }

  /**
   * Soft deletes a points transaction
   * Requirement: 3.2.2 Data Management Strategy - Consistent data operations
   */
  async delete(id: string, userId: string): Promise<boolean> {
    const result = await this.transactionModel.updateOne(
      { _id: id, isActive: true },
      { isActive: false, updatedBy: userId }
    );
    return result.modifiedCount > 0;
  }

  /**
   * Validates points transaction data
   * Requirement: 3.2.2 Data Management Strategy - Consistent validation
   */
  async validate(data: Partial<IPointsTransaction>): Promise<ValidationResult> {
    const errors: ValidationError[] = [];

    if (!data.userId) {
      errors.push({ field: 'userId', message: 'User ID is required', code: 'REQUIRED' });
    }

    if (typeof data.amount !== 'number' || data.amount <= 0) {
      errors.push({ field: 'amount', message: 'Amount must be a positive number', code: 'INVALID_VALUE' });
    }

    if (!Object.values(PointsTransactionType).includes(data.type as PointsTransactionType)) {
      errors.push({ field: 'type', message: 'Invalid transaction type', code: 'INVALID_VALUE' });
    }

    if (!Object.values(PointsSourceType).includes(data.source as PointsSourceType)) {
      errors.push({ field: 'source', message: 'Invalid points source', code: 'INVALID_VALUE' });
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}