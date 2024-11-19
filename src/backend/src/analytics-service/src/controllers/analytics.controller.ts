// External dependencies
import { Request, Response } from 'express'; // v4.18.0
import { injectable, inject } from 'inversify'; // v6.0.0
import { controller, httpPost, httpGet } from 'inversify-express-utils';

// Internal dependencies
import { Controller } from '../../../shared/interfaces/controller.interface';
import { AnalyticsService } from '../services/analytics.service';
import { UserMetrics } from '../models/metrics.model';
import { Logger } from '../../../shared/utils/logger';
import { ValidationError } from '../../../shared/utils/error';

/**
 * Human Tasks:
 * 1. Configure Prometheus metrics endpoint for scraping
 * 2. Set up Grafana dashboards for analytics visualization
 * 3. Configure alerting thresholds for key metrics
 * 4. Set up data retention policies for analytics data
 * 5. Configure backup strategy for analytics database
 */

@controller('/analytics')
@injectable()
export class AnalyticsController implements Controller<UserMetrics> {
  private readonly logger: Logger;

  constructor(
    @inject(AnalyticsService) private readonly analyticsService: AnalyticsService
  ) {
    this.logger = new Logger('AnalyticsController');
  }

  /**
   * Tracks user activity and engagement metrics
   * Requirement: User Adoption Tracking - Track progress towards 100,000 active users target
   */
  @httpPost('/user-activity')
  @authorize('user')
  public async trackUserActivity(req: Request, res: Response): Promise<Response> {
    try {
      this.logger.info('Processing user activity tracking request', { userId: req.body.userId });

      // Validate request body against UserMetrics interface
      const metrics: UserMetrics = {
        userId: req.body.userId,
        listingsCreated: req.body.listingsCreated || 0,
        totalPoints: req.body.totalPoints || 0,
        lastActive: new Date(),
        ...req.body
      };

      if (!metrics.userId) {
        throw new ValidationError('User ID is required');
      }

      // Track user activity through analytics service
      await this.analyticsService.trackUserActivity(metrics);

      return res.status(200).json({
        success: true,
        message: 'User activity tracked successfully',
        data: metrics
      });
    } catch (error) {
      this.logger.error('Error tracking user activity', error as Error);
      throw error;
    }
  }

  /**
   * Records furniture recovery and environmental impact metrics
   * Requirement: Furniture Recovery Metrics - Monitor 50,000 items recovered annually
   * Requirement: Environmental Impact - Track progress towards 1,000 tons diverted
   */
  @httpPost('/furniture-recovery')
  @authorize('user')
  public async trackFurnitureRecovery(req: Request, res: Response): Promise<Response> {
    try {
      this.logger.info('Processing furniture recovery tracking', { listingId: req.body.listingId });

      // Validate recovery metrics
      if (!req.body.listingId || req.body.wasCollected === undefined) {
        throw new ValidationError('Invalid furniture recovery metrics');
      }

      // Track recovery through analytics service
      await this.analyticsService.trackFurnitureRecovery({
        listingId: req.body.listingId,
        furnitureType: req.body.furnitureType,
        condition: req.body.condition,
        wasCollected: req.body.wasCollected,
        viewCount: req.body.viewCount || 0,
        messageCount: req.body.messageCount || 0
      });

      return res.status(200).json({
        success: true,
        message: 'Furniture recovery tracked successfully',
        data: {
          listingId: req.body.listingId,
          wasCollected: req.body.wasCollected
        }
      });
    } catch (error) {
      this.logger.error('Error tracking furniture recovery', error as Error);
      throw error;
    }
  }

  /**
   * Retrieves comprehensive analytics report for specified period
   * Requirement: User Adoption Tracking - Track and measure progress
   * Requirement: Environmental Impact - Track waste diversion progress
   */
  @httpGet('/report')
  @authorize('admin')
  public async getAnalyticsReport(req: Request, res: Response): Promise<Response> {
    try {
      this.logger.info('Generating analytics report', { query: req.query });

      // Validate date range
      const startDate = req.query.startDate ? new Date(req.query.startDate as string) : undefined;
      const endDate = req.query.endDate ? new Date(req.query.endDate as string) : undefined;

      if (startDate && endDate && startDate >= endDate) {
        throw new ValidationError('Invalid date range');
      }

      // Generate report through analytics service
      const report = await this.analyticsService.generateAnalyticsReport(startDate, endDate);

      return res.status(200).json({
        success: true,
        message: 'Analytics report generated successfully',
        data: report
      });
    } catch (error) {
      this.logger.error('Error generating analytics report', error as Error);
      throw error;
    }
  }

  /**
   * Retrieves community growth and engagement metrics by region
   * Requirement: User Engagement - Monitor 70% monthly active user retention
   */
  @httpGet('/community')
  @authorize('admin')
  public async getCommunityMetrics(req: Request, res: Response): Promise<Response> {
    try {
      const region = req.query.region as string;
      this.logger.info('Retrieving community metrics', { region });

      // Validate region parameter
      if (!region) {
        throw new ValidationError('Region parameter is required');
      }

      // Track community growth through analytics service
      const metrics = await this.analyticsService.trackCommunityGrowth(region);

      return res.status(200).json({
        success: true,
        message: 'Community metrics retrieved successfully',
        data: metrics
      });
    } catch (error) {
      this.logger.error('Error retrieving community metrics', error as Error);
      throw error;
    }
  }

  // Implementing required Controller interface methods
  public async create(req: Request, res: Response): Promise<Response> {
    return this.trackUserActivity(req, res);
  }

  public async findAll(req: Request, res: Response): Promise<Response> {
    return this.getAnalyticsReport(req, res);
  }
}