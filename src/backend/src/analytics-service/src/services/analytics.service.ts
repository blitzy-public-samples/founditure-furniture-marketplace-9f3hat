// External dependencies
import { injectable } from 'inversify'; // v5.1.1
import { Counter, Gauge } from 'prom-client'; // v14.2.0
import mongoose from 'mongoose'; // v7.5.0
import dayjs from 'dayjs'; // v1.11.9

// Internal dependencies
import { UserMetrics, ListingMetrics } from '../models/metrics.model';
import { calculateUserEngagement, calculateEnvironmentalImpact } from '../utils/metrics.util';
import { Logger } from '../../../shared/utils/logger';

/**
 * Human Tasks:
 * 1. Configure Prometheus metrics endpoint for scraping
 * 2. Set up Grafana dashboards for metrics visualization
 * 3. Configure alerting thresholds for key metrics
 * 4. Set up data retention policies for analytics data
 * 5. Configure backup strategy for metrics database
 */

@injectable()
export class AnalyticsService {
  private readonly logger: Logger;
  private readonly userRegistrations: Counter;
  private readonly furnitureRecoveries: Counter;
  private readonly activeUsers: Gauge;
  private readonly communityGrowth: Gauge;

  constructor(logger: Logger) {
    this.logger = logger;

    // Initialize Prometheus metrics
    // Requirement: User Adoption Tracking - Track 100,000 active users target
    this.userRegistrations = new Counter({
      name: 'founditure_user_registrations_total',
      help: 'Total number of user registrations'
    });

    // Requirement: Furniture Recovery Metrics - Monitor 50,000 items recovered annually
    this.furnitureRecoveries = new Counter({
      name: 'founditure_furniture_recoveries_total',
      help: 'Total number of furniture items recovered'
    });

    // Requirement: User Engagement - Monitor 70% monthly active user retention
    this.activeUsers = new Gauge({
      name: 'founditure_active_users',
      help: 'Current number of active users'
    });

    // Requirement: Community Growth - Track 25% month-over-month community growth
    this.communityGrowth = new Gauge({
      name: 'founditure_community_growth_rate',
      help: 'Month-over-month community growth rate percentage'
    });

    this.logger.info('Analytics service initialized with Prometheus metrics');
  }

  /**
   * Tracks and updates user activity metrics with engagement scoring
   * Requirement: User Engagement - Monitor 70% monthly active user retention
   */
  public async trackUserActivity(metrics: UserMetrics): Promise<void> {
    try {
      this.logger.info('Tracking user activity', { userId: metrics.userId });

      // Validate metrics data
      if (!metrics.userId || !metrics.lastActive) {
        throw new Error('Invalid user metrics data');
      }

      // Calculate engagement score
      const engagementScore = calculateUserEngagement({
        userId: metrics.userId,
        listingsCreated: metrics.listingsCreated,
        totalPoints: metrics.totalPoints,
        lastActive: metrics.lastActive
      });

      // Update user metrics in database
      await mongoose.model('UserMetrics').updateOne(
        { userId: metrics.userId },
        {
          $set: {
            lastActive: metrics.lastActive,
            engagementScore,
            isActive: true
          },
          $inc: {
            listingsCreated: metrics.listingsCreated,
            totalPoints: metrics.totalPoints
          }
        },
        { upsert: true }
      );

      // Update Prometheus gauges
      this.activeUsers.inc();

      this.logger.info('User activity tracked successfully', {
        userId: metrics.userId,
        engagementScore
      });
    } catch (error) {
      this.logger.error('Error tracking user activity', error as Error);
      throw error;
    }
  }

  /**
   * Records and processes furniture recovery metrics with environmental impact
   * Requirement: Furniture Recovery Metrics - Monitor 50,000 items recovered annually
   * Requirement: Environmental Impact - Track progress towards 1,000 tons diverted
   */
  public async trackFurnitureRecovery(listing: ListingMetrics): Promise<void> {
    try {
      this.logger.info('Tracking furniture recovery', { listingId: listing.listingId });

      // Validate listing data
      if (!listing.listingId || listing.wasCollected === undefined) {
        throw new Error('Invalid listing metrics data');
      }

      // Increment recovery counter if item was collected
      if (listing.wasCollected) {
        this.furnitureRecoveries.inc();

        // Calculate environmental impact
        const impact = calculateEnvironmentalImpact([listing]);

        // Update recovery metrics in database
        await mongoose.model('ListingMetrics').updateOne(
          { listingId: listing.listingId },
          {
            $set: {
              wasCollected: true,
              viewCount: listing.viewCount,
              messageCount: listing.messageCount,
              environmentalImpact: impact
            }
          },
          { upsert: true }
        );

        this.logger.info('Furniture recovery tracked successfully', {
          listingId: listing.listingId,
          impact
        });
      }
    } catch (error) {
      this.logger.error('Error tracking furniture recovery', error as Error);
      throw error;
    }
  }

  /**
   * Generates comprehensive analytics report for specified time period
   * Requirement: User Adoption Tracking - Track progress towards 100,000 active users
   * Requirement: Environmental Impact - Track progress towards 1,000 tons diverted
   */
  public async generateAnalyticsReport(startDate: Date, endDate: Date): Promise<object> {
    try {
      this.logger.info('Generating analytics report', { startDate, endDate });

      // Validate date range
      if (!startDate || !endDate || startDate >= endDate) {
        throw new Error('Invalid date range for analytics report');
      }

      // Gather user engagement metrics
      const userMetrics = await mongoose.model('UserMetrics').aggregate([
        {
          $match: {
            lastActive: { $gte: startDate, $lte: endDate },
            isActive: true
          }
        },
        {
          $group: {
            _id: null,
            totalUsers: { $sum: 1 },
            avgEngagementScore: { $avg: '$engagementScore' },
            totalListingsCreated: { $sum: '$listingsCreated' }
          }
        }
      ]);

      // Calculate furniture recovery statistics
      const recoveryMetrics = await mongoose.model('ListingMetrics').aggregate([
        {
          $match: {
            createdAt: { $gte: startDate, $lte: endDate },
            wasCollected: true
          }
        },
        {
          $group: {
            _id: null,
            totalRecoveries: { $sum: 1 },
            avgViewCount: { $avg: '$viewCount' },
            avgMessageCount: { $avg: '$messageCount' }
          }
        }
      ]);

      // Compile comprehensive report
      const report = {
        period: {
          start: startDate,
          end: endDate
        },
        userMetrics: userMetrics[0] || {
          totalUsers: 0,
          avgEngagementScore: 0,
          totalListingsCreated: 0
        },
        recoveryMetrics: recoveryMetrics[0] || {
          totalRecoveries: 0,
          avgViewCount: 0,
          avgMessageCount: 0
        },
        environmentalImpact: await this.calculateTotalEnvironmentalImpact(startDate, endDate)
      };

      this.logger.info('Analytics report generated successfully');
      return report;
    } catch (error) {
      this.logger.error('Error generating analytics report', error as Error);
      throw error;
    }
  }

  /**
   * Monitors and updates community growth metrics by region
   * Requirement: Community Growth - Track 25% month-over-month community growth
   */
  public async trackCommunityGrowth(region: string): Promise<void> {
    try {
      this.logger.info('Tracking community growth', { region });

      // Validate region parameter
      if (!region) {
        throw new Error('Invalid region parameter');
      }

      // Calculate active users in region
      const currentMonth = dayjs().startOf('month');
      const lastMonth = currentMonth.subtract(1, 'month');

      const [currentMonthUsers, lastMonthUsers] = await Promise.all([
        mongoose.model('UserMetrics').countDocuments({
          region,
          lastActive: { $gte: currentMonth.toDate() },
          isActive: true
        }),
        mongoose.model('UserMetrics').countDocuments({
          region,
          lastActive: { 
            $gte: lastMonth.toDate(),
            $lt: currentMonth.toDate()
          },
          isActive: true
        })
      ]);

      // Calculate growth rate
      const growthRate = lastMonthUsers > 0 
        ? ((currentMonthUsers - lastMonthUsers) / lastMonthUsers) * 100 
        : 0;

      // Update community metrics in database
      await mongoose.model('CommunityMetrics').updateOne(
        { region },
        {
          $set: {
            activeUsers: currentMonthUsers,
            growthRate,
            lastUpdated: new Date()
          }
        },
        { upsert: true }
      );

      // Update Prometheus gauge
      this.communityGrowth.set(growthRate);

      this.logger.info('Community growth tracked successfully', {
        region,
        currentMonthUsers,
        growthRate
      });
    } catch (error) {
      this.logger.error('Error tracking community growth', error as Error);
      throw error;
    }
  }

  /**
   * Helper method to calculate total environmental impact for a time period
   */
  private async calculateTotalEnvironmentalImpact(
    startDate: Date,
    endDate: Date
  ): Promise<{ wasteReduction: number; carbonSavings: number; totalItems: number }> {
    const recoveredItems = await mongoose.model('ListingMetrics').find({
      createdAt: { $gte: startDate, $lte: endDate },
      wasCollected: true
    });

    return calculateEnvironmentalImpact(recoveredItems);
  }
}