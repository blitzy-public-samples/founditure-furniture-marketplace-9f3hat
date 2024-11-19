// External dependencies
import { describe, beforeEach, afterEach, it, expect, jest } from '@jest/globals'; // v29.0.0
import { MockInstance } from 'jest-mock'; // v29.0.0
import dayjs from 'dayjs'; // v1.11.9

// Internal dependencies
import { AnalyticsService } from '../src/services/analytics.service';
import { UserMetrics, ListingMetrics } from '../src/models/metrics.model';
import { Logger } from '../../../shared/utils/logger';

/**
 * Human Tasks:
 * 1. Configure test environment variables for MongoDB connection
 * 2. Set up test Prometheus server endpoint
 * 3. Configure test data retention policies
 * 4. Set up test coverage reporting
 * 5. Configure CI/CD pipeline test stages
 */

describe('AnalyticsService', () => {
  let analyticsService: AnalyticsService;
  let mockLogger: jest.Mocked<Logger>;
  let mockCounter: jest.Mocked<any>;
  let mockGauge: jest.Mocked<any>;

  beforeEach(() => {
    // Mock Logger
    mockLogger = {
      info: jest.fn(),
      error: jest.fn(),
      warn: jest.fn(),
      debug: jest.fn()
    } as jest.Mocked<Logger>;

    // Mock Prometheus metrics
    mockCounter = {
      inc: jest.fn(),
      labels: jest.fn().mockReturnThis()
    };

    mockGauge = {
      set: jest.fn(),
      inc: jest.fn(),
      dec: jest.fn(),
      labels: jest.fn().mockReturnThis()
    };

    // Initialize service with mocks
    analyticsService = new AnalyticsService(mockLogger);
    (analyticsService as any).userRegistrations = mockCounter;
    (analyticsService as any).furnitureRecoveries = mockCounter;
    (analyticsService as any).activeUsers = mockGauge;
    (analyticsService as any).communityGrowth = mockGauge;
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('trackUserActivity', () => {
    // Requirement: User Adoption Tracking - Track 100,000 active users target
    it('should successfully track user activity and update metrics', async () => {
      const userMetrics: UserMetrics = {
        userId: 'user123',
        listingsCreated: 5,
        totalPoints: 500,
        lastActive: new Date(),
        isActive: true,
        createdBy: 'system',
        updatedBy: 'system'
      };

      await analyticsService.trackUserActivity(userMetrics);

      expect(mockLogger.info).toHaveBeenCalledWith(
        'Tracking user activity',
        expect.any(Object)
      );
      expect(mockGauge.inc).toHaveBeenCalled();
    });

    it('should throw error for invalid user metrics', async () => {
      const invalidMetrics = {
        userId: '',
        listingsCreated: 0,
        totalPoints: 0
      } as unknown as UserMetrics;

      await expect(analyticsService.trackUserActivity(invalidMetrics))
        .rejects
        .toThrow('Invalid user metrics data');
    });

    // Requirement: User Engagement - Verify 70% monthly active user retention
    it('should calculate and store engagement score', async () => {
      const userMetrics: UserMetrics = {
        userId: 'user123',
        listingsCreated: 10,
        totalPoints: 1000,
        lastActive: new Date(),
        isActive: true,
        createdBy: 'system',
        updatedBy: 'system'
      };

      await analyticsService.trackUserActivity(userMetrics);

      expect(mockLogger.info).toHaveBeenCalledWith(
        'User activity tracked successfully',
        expect.objectContaining({
          userId: 'user123',
          engagementScore: expect.any(Number)
        })
      );
    });
  });

  describe('trackFurnitureRecovery', () => {
    // Requirement: Furniture Recovery Metrics - Validate 50,000 items recovered annually
    it('should track successful furniture recovery', async () => {
      const listingMetrics: ListingMetrics = {
        listingId: 'listing123',
        viewCount: 50,
        messageCount: 10,
        wasCollected: true,
        isActive: true,
        createdBy: 'system',
        updatedBy: 'system'
      };

      await analyticsService.trackFurnitureRecovery(listingMetrics);

      expect(mockCounter.inc).toHaveBeenCalled();
      expect(mockLogger.info).toHaveBeenCalledWith(
        'Furniture recovery tracked successfully',
        expect.any(Object)
      );
    });

    it('should throw error for invalid listing metrics', async () => {
      const invalidMetrics = {
        listingId: '',
        viewCount: 0
      } as unknown as ListingMetrics;

      await expect(analyticsService.trackFurnitureRecovery(invalidMetrics))
        .rejects
        .toThrow('Invalid listing metrics data');
    });

    // Requirement: Environmental Impact - Test 1,000 tons waste diversion tracking
    it('should calculate environmental impact for recovered items', async () => {
      const listingMetrics: ListingMetrics = {
        listingId: 'listing123',
        viewCount: 50,
        messageCount: 10,
        wasCollected: true,
        isActive: true,
        createdBy: 'system',
        updatedBy: 'system'
      };

      await analyticsService.trackFurnitureRecovery(listingMetrics);

      expect(mockLogger.info).toHaveBeenCalledWith(
        'Furniture recovery tracked successfully',
        expect.objectContaining({
          listingId: 'listing123',
          impact: expect.any(Object)
        })
      );
    });
  });

  describe('generateAnalyticsReport', () => {
    it('should generate report for valid date range', async () => {
      const startDate = dayjs().subtract(1, 'month').toDate();
      const endDate = new Date();

      const report = await analyticsService.generateAnalyticsReport(startDate, endDate);

      expect(report).toHaveProperty('period');
      expect(report).toHaveProperty('userMetrics');
      expect(report).toHaveProperty('recoveryMetrics');
      expect(report).toHaveProperty('environmentalImpact');
    });

    it('should throw error for invalid date range', async () => {
      const startDate = new Date();
      const endDate = dayjs().subtract(1, 'month').toDate();

      await expect(analyticsService.generateAnalyticsReport(startDate, endDate))
        .rejects
        .toThrow('Invalid date range for analytics report');
    });

    // Requirement: User Adoption Tracking - Verify progress tracking
    it('should include user adoption metrics in report', async () => {
      const startDate = dayjs().subtract(1, 'month').toDate();
      const endDate = new Date();

      const report = await analyticsService.generateAnalyticsReport(startDate, endDate);

      expect(report.userMetrics).toHaveProperty('totalUsers');
      expect(report.userMetrics).toHaveProperty('avgEngagementScore');
    });
  });

  describe('trackCommunityGrowth', () => {
    it('should track community growth for valid region', async () => {
      const region = 'north-america';

      await analyticsService.trackCommunityGrowth(region);

      expect(mockGauge.set).toHaveBeenCalled();
      expect(mockLogger.info).toHaveBeenCalledWith(
        'Community growth tracked successfully',
        expect.objectContaining({
          region,
          growthRate: expect.any(Number)
        })
      );
    });

    it('should throw error for invalid region', async () => {
      const invalidRegion = '';

      await expect(analyticsService.trackCommunityGrowth(invalidRegion))
        .rejects
        .toThrow('Invalid region parameter');
    });

    // Requirement: User Engagement - Track community growth
    it('should calculate month-over-month growth rate', async () => {
      const region = 'europe';

      await analyticsService.trackCommunityGrowth(region);

      expect(mockLogger.info).toHaveBeenCalledWith(
        'Community growth tracked successfully',
        expect.objectContaining({
          region,
          currentMonthUsers: expect.any(Number),
          growthRate: expect.any(Number)
        })
      );
    });
  });
});