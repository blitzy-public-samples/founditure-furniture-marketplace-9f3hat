// External dependencies
import { Request, Response } from 'express'; // v4.18.0
import { StatusCodes } from 'http-status'; // v1.6.0

// Internal dependencies
import { Controller } from '../../../shared/interfaces/controller.interface';
import { AchievementService } from '../services/achievement.service';
import { IAchievement } from '../models/achievement.model';
import { ValidationError } from '../../../shared/utils/error';
import { Logger } from '../../../shared/utils/logger';

/**
 * Human Tasks:
 * 1. Configure rate limiting for achievement endpoints
 * 2. Set up monitoring for achievement completion rates
 * 3. Configure caching strategy for frequently accessed achievements
 * 4. Set up alerts for unusual achievement patterns
 * 5. Configure request validation middleware
 */

/**
 * Controller handling HTTP requests for achievement management with standardized responses
 * Requirement: Gamification System - User Engagement: 70% monthly active user retention
 * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
 */
export class AchievementController implements Controller<IAchievement> {
  private achievementService: AchievementService;
  private logger: Logger;

  constructor(achievementService: AchievementService) {
    this.achievementService = achievementService;
    this.logger = new Logger('AchievementController');
  }

  /**
   * Creates a new achievement definition
   * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
   */
  public async create(req: Request, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        throw new ValidationError('User ID is required');
      }

      const achievementData = req.body;
      const requiredFields = ['name', 'description', 'category', 'pointsReward', 'criteria', 'tier'];
      
      for (const field of requiredFields) {
        if (!achievementData[field]) {
          throw new ValidationError(`${field} is required`);
        }
      }

      const achievement = await this.achievementService.create(achievementData, userId);

      this.logger.info('Achievement created', {
        achievementId: achievement.id,
        name: achievement.name,
        userId
      });

      return res.status(StatusCodes.CREATED).json({
        success: true,
        status: StatusCodes.CREATED,
        message: 'Achievement created successfully',
        data: achievement
      });
    } catch (error) {
      this.logger.error('Error creating achievement', error as Error);
      throw error;
    }
  }

  /**
   * Retrieves all achievements with optional filtering
   * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
   */
  public async findAll(req: Request, res: Response): Promise<Response> {
    try {
      const { category, tier, isActive } = req.query;
      const filters = {
        ...(category && { category }),
        ...(tier && { tier }),
        ...(isActive !== undefined && { isActive: Boolean(isActive) })
      };

      const achievements = await this.achievementService.findAll({ filters });

      return res.status(StatusCodes.OK).json({
        success: true,
        status: StatusCodes.OK,
        message: 'Achievements retrieved successfully',
        data: achievements
      });
    } catch (error) {
      this.logger.error('Error retrieving achievements', error as Error);
      throw error;
    }
  }

  /**
   * Retrieves a single achievement by ID
   * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
   */
  public async findById(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const achievement = await this.achievementService.findById(id);

      if (!achievement) {
        throw new ValidationError('Achievement not found');
      }

      return res.status(StatusCodes.OK).json({
        success: true,
        status: StatusCodes.OK,
        message: 'Achievement retrieved successfully',
        data: achievement
      });
    } catch (error) {
      this.logger.error('Error retrieving achievement', error as Error);
      throw error;
    }
  }

  /**
   * Retrieves all achievements and progress for a user
   * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
   */
  public async getUserAchievements(req: Request, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        throw new ValidationError('User ID is required');
      }

      const achievements = await this.achievementService.getUserAchievements(userId);

      return res.status(StatusCodes.OK).json({
        success: true,
        status: StatusCodes.OK,
        message: 'User achievements retrieved successfully',
        data: achievements
      });
    } catch (error) {
      this.logger.error('Error retrieving user achievements', error as Error);
      throw error;
    }
  }

  /**
   * Updates user's progress towards an achievement
   * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
   */
  public async trackProgress(req: Request, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        throw new ValidationError('User ID is required');
      }

      const { id: achievementId } = req.params;
      const { progress } = req.body;

      if (typeof progress !== 'number' || progress < 0 || progress > 100) {
        throw new ValidationError('Progress must be a number between 0 and 100');
      }

      const updatedProgress = await this.achievementService.trackProgress(
        userId,
        achievementId,
        progress
      );

      return res.status(StatusCodes.OK).json({
        success: true,
        status: StatusCodes.OK,
        message: 'Achievement progress updated successfully',
        data: updatedProgress
      });
    } catch (error) {
      this.logger.error('Error updating achievement progress', error as Error);
      throw error;
    }
  }
}