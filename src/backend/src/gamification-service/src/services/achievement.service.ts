// External dependencies
import mongoose from 'mongoose'; // v7.5.0
import { Subject } from 'rxjs'; // v7.8.1

// Internal dependencies
import { Service } from '../../../shared/interfaces/service.interface';
import { IAchievement, IUserAchievement } from '../models/achievement.model';
import { ValidationError } from '../../../shared/utils/error';
import { Logger } from '../../../shared/utils/logger';

/**
 * Human Tasks:
 * 1. Configure MongoDB indexes for achievement collections
 * 2. Set up monitoring for achievement completion rates
 * 3. Configure caching strategy for frequently accessed achievements
 * 4. Set up alerts for unusual achievement completion patterns
 */

/**
 * Achievement event interface for real-time updates
 * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
 */
interface AchievementEvent {
  userId: string;
  achievementId: string;
  type: 'PROGRESS' | 'COMPLETED';
  timestamp: Date;
  data: any;
}

/**
 * Service implementation for managing user achievements and progress
 * Requirement: Gamification System - User Engagement: 70% monthly active user retention
 */
export class AchievementService implements Service<IAchievement> {
  private logger: Logger;
  private achievementEvents$: Subject<AchievementEvent>;

  constructor() {
    this.logger = new Logger('AchievementService');
    this.achievementEvents$ = new Subject<AchievementEvent>();
    this.setupProgressMonitoring();
  }

  /**
   * Creates a new achievement definition
   * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
   */
  async create(data: Partial<IAchievement>, userId: string): Promise<IAchievement> {
    try {
      // Validate achievement data
      const validationResult = await this.validate(data);
      if (!validationResult.isValid) {
        throw new ValidationError('Invalid achievement data', { errors: validationResult.errors });
      }

      // Create achievement document
      const achievement = new mongoose.Model<IAchievement>('Achievement', {
        ...data,
        createdBy: userId,
        updatedBy: userId,
        createdAt: new Date(),
        updatedAt: new Date(),
        isActive: true
      });

      await achievement.save();

      this.logger.info('Achievement created', {
        achievementId: achievement.id,
        name: achievement.name,
        category: achievement.category,
        userId
      });

      return achievement;
    } catch (error) {
      this.logger.error('Error creating achievement', error as Error);
      throw error;
    }
  }

  /**
   * Updates user's progress towards an achievement
   * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
   */
  async trackProgress(
    userId: string,
    achievementId: string,
    progress: number
  ): Promise<IUserAchievement> {
    try {
      // Find existing progress or create new
      let userAchievement = await mongoose.Model.findOne<IUserAchievement>({
        userId,
        achievementId,
        isActive: true
      });

      const achievement = await this.findById(achievementId);
      if (!achievement) {
        throw new ValidationError('Achievement not found');
      }

      if (!userAchievement) {
        userAchievement = new mongoose.Model<IUserAchievement>({
          userId,
          achievementId,
          progress: 0,
          isCompleted: false,
          createdAt: new Date(),
          updatedAt: new Date(),
          isActive: true
        });
      }

      // Update progress
      userAchievement.progress = Math.min(progress, 100);
      userAchievement.updatedAt = new Date();

      // Check completion
      const isCompleted = await this.validateCompletion(userAchievement, achievement);
      if (isCompleted && !userAchievement.isCompleted) {
        userAchievement.isCompleted = true;
        userAchievement.completedAt = new Date();

        // Emit completion event
        this.achievementEvents$.next({
          userId,
          achievementId,
          type: 'COMPLETED',
          timestamp: new Date(),
          data: {
            achievement,
            progress: userAchievement.progress
          }
        });

        this.logger.info('Achievement completed', {
          userId,
          achievementId,
          name: achievement.name
        });
      }

      await userAchievement.save();

      // Emit progress event
      this.achievementEvents$.next({
        userId,
        achievementId,
        type: 'PROGRESS',
        timestamp: new Date(),
        data: {
          achievement,
          progress: userAchievement.progress
        }
      });

      return userAchievement;
    } catch (error) {
      this.logger.error('Error tracking achievement progress', error as Error);
      throw error;
    }
  }

  /**
   * Retrieves all achievements and progress for a user
   * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
   */
  async getUserAchievements(userId: string): Promise<IUserAchievement[]> {
    try {
      const userAchievements = await mongoose.Model.find<IUserAchievement>({
        userId,
        isActive: true
      }).populate('achievementId');

      return userAchievements;
    } catch (error) {
      this.logger.error('Error retrieving user achievements', error as Error);
      throw error;
    }
  }

  /**
   * Validates if achievement criteria are met
   * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
   */
  private async validateCompletion(
    userAchievement: IUserAchievement,
    achievement: IAchievement
  ): Promise<boolean> {
    try {
      // Check if progress meets criteria
      if (userAchievement.progress < 100) {
        return false;
      }

      // Validate specific achievement criteria
      const criteriaValid = await this.validateCriteria(userAchievement, achievement.criteria);
      return criteriaValid;
    } catch (error) {
      this.logger.error('Error validating achievement completion', error as Error);
      throw error;
    }
  }

  /**
   * Validates achievement criteria based on type
   */
  private async validateCriteria(
    userAchievement: IUserAchievement,
    criteria: Record<string, any>
  ): Promise<boolean> {
    // Implement specific criteria validation logic
    return true;
  }

  /**
   * Sets up monitoring for achievement progress
   */
  private setupProgressMonitoring(): void {
    this.achievementEvents$.subscribe(event => {
      this.logger.debug('Achievement event received', { event });
      // Implement additional monitoring logic
    });
  }

  /**
   * Required Service interface methods
   */
  async findAll(options: any): Promise<IAchievement[]> {
    return mongoose.Model.find<IAchievement>({ isActive: true });
  }

  async findById(id: string): Promise<IAchievement | null> {
    return mongoose.Model.findOne<IAchievement>({ _id: id, isActive: true });
  }

  async update(id: string, data: Partial<IAchievement>, userId: string): Promise<IAchievement> {
    const achievement = await this.findById(id);
    if (!achievement) {
      throw new ValidationError('Achievement not found');
    }

    Object.assign(achievement, data, {
      updatedBy: userId,
      updatedAt: new Date()
    });

    await achievement.save();
    return achievement;
  }

  async validate(data: Partial<IAchievement>): Promise<{ isValid: boolean; errors: any[] }> {
    const errors = [];

    if (!data.name) {
      errors.push({ field: 'name', message: 'Name is required' });
    }
    if (!data.description) {
      errors.push({ field: 'description', message: 'Description is required' });
    }
    if (!data.category) {
      errors.push({ field: 'category', message: 'Category is required' });
    }
    if (typeof data.pointsReward !== 'number' || data.pointsReward < 0) {
      errors.push({ field: 'pointsReward', message: 'Valid points reward is required' });
    }
    if (!data.criteria) {
      errors.push({ field: 'criteria', message: 'Criteria is required' });
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}