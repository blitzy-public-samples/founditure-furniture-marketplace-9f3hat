// External dependencies
import mongoose from 'mongoose'; // v7.5.0
import { jest } from '@jest/globals'; // v29.0.0

// Internal dependencies
import { AchievementService } from '../src/services/achievement.service';
import { IAchievement, AchievementCategory, AchievementTier } from '../src/models/achievement.model';

/**
 * Human Tasks:
 * 1. Configure test MongoDB instance with proper indexes
 * 2. Set up test data seeding scripts
 * 3. Configure test coverage reporting
 * 4. Set up CI/CD pipeline integration for automated testing
 */

describe('Achievement Service Tests', () => {
  let achievementService: AchievementService;
  const testUserId = 'test-user-123';
  const mongoUri = process.env.MONGO_TEST_URI || 'mongodb://localhost:27017/gamification-test';

  // Test achievement data
  const validAchievement: Partial<IAchievement> = {
    name: 'First Collection',
    description: 'Complete your first furniture collection',
    category: AchievementCategory.COLLECTOR,
    pointsReward: 100,
    criteria: {
      type: 'collection_count',
      target: 1
    },
    badgeUrl: 'https://badges.example.com/first-collection.png',
    tier: AchievementTier.BRONZE
  };

  /**
   * Setup test environment
   * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
   */
  beforeAll(async () => {
    await mongoose.connect(mongoUri);
    achievementService = new AchievementService();
  });

  /**
   * Cleanup after all tests
   */
  afterAll(async () => {
    await mongoose.connection.dropDatabase();
    await mongoose.disconnect();
  });

  /**
   * Reset database state before each test
   */
  beforeEach(async () => {
    await mongoose.connection.collections.achievements?.deleteMany({});
    await mongoose.connection.collections.userachievements?.deleteMany({});
  });

  describe('Achievement Creation', () => {
    /**
     * Test valid achievement creation
     * Requirement: Gamification System - User Engagement: 70% monthly active user retention
     */
    it('should create valid achievement', async () => {
      const result = await achievementService.create(validAchievement, testUserId);

      expect(result).toBeDefined();
      expect(result.name).toBe(validAchievement.name);
      expect(result.description).toBe(validAchievement.description);
      expect(result.category).toBe(validAchievement.category);
      expect(result.pointsReward).toBe(validAchievement.pointsReward);
      expect(result.criteria).toEqual(validAchievement.criteria);
      expect(result.badgeUrl).toBe(validAchievement.badgeUrl);
      expect(result.tier).toBe(validAchievement.tier);
      expect(result.createdBy).toBe(testUserId);
      expect(result.isActive).toBe(true);
    });

    /**
     * Test invalid achievement creation
     * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
     */
    it('should reject invalid achievement data', async () => {
      const invalidAchievement = {
        name: '', // Invalid: empty name
        description: 'Test description',
        category: 'INVALID_CATEGORY', // Invalid category
        pointsReward: -100 // Invalid: negative points
      };

      await expect(achievementService.create(invalidAchievement, testUserId))
        .rejects
        .toThrow('Invalid achievement data');
    });
  });

  describe('Achievement Progress Tracking', () => {
    let testAchievementId: string;

    beforeEach(async () => {
      const achievement = await achievementService.create(validAchievement, testUserId);
      testAchievementId = achievement.id;
    });

    /**
     * Test progress tracking
     * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
     */
    it('should track user progress correctly', async () => {
      const progress = 50;
      const result = await achievementService.trackProgress(
        testUserId,
        testAchievementId,
        progress
      );

      expect(result).toBeDefined();
      expect(result.userId).toBe(testUserId);
      expect(result.achievementId).toBe(testAchievementId);
      expect(result.progress).toBe(progress);
      expect(result.isCompleted).toBe(false);
      expect(result.completedAt).toBeUndefined();
    });

    /**
     * Test achievement completion
     * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
     */
    it('should handle achievement completion', async () => {
      const result = await achievementService.trackProgress(
        testUserId,
        testAchievementId,
        100
      );

      expect(result).toBeDefined();
      expect(result.progress).toBe(100);
      expect(result.isCompleted).toBe(true);
      expect(result.completedAt).toBeDefined();
    });

    /**
     * Test invalid progress values
     * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
     */
    it('should handle invalid progress values', async () => {
      await expect(achievementService.trackProgress(
        testUserId,
        testAchievementId,
        150 // Invalid: > 100%
      )).resolves.toHaveProperty('progress', 100);

      await expect(achievementService.trackProgress(
        testUserId,
        testAchievementId,
        -50 // Invalid: negative progress
      )).rejects.toThrow();
    });
  });

  describe('User Achievement Queries', () => {
    const achievements = [
      {
        ...validAchievement,
        name: 'Achievement 1',
        category: AchievementCategory.COLLECTOR
      },
      {
        ...validAchievement,
        name: 'Achievement 2',
        category: AchievementCategory.FINDER
      },
      {
        ...validAchievement,
        name: 'Achievement 3',
        category: AchievementCategory.COMMUNITY
      }
    ];

    beforeEach(async () => {
      // Create test achievements
      for (const achievement of achievements) {
        const created = await achievementService.create(achievement, testUserId);
        await achievementService.trackProgress(testUserId, created.id, 50);
      }
    });

    /**
     * Test retrieving all user achievements
     * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
     */
    it('should get all user achievements', async () => {
      const results = await achievementService.getUserAchievements(testUserId);

      expect(results).toHaveLength(achievements.length);
      results.forEach(result => {
        expect(result.userId).toBe(testUserId);
        expect(result.progress).toBe(50);
        expect(result.isCompleted).toBe(false);
      });
    });

    /**
     * Test filtering achievements by category
     * Requirement: Achievement System - Achievements tracking with badges and progress monitoring
     */
    it('should filter by achievement category', async () => {
      const results = await achievementService.getUserAchievements(testUserId);
      const collectorAchievements = results.filter(
        result => result.achievementId.category === AchievementCategory.COLLECTOR
      );

      expect(collectorAchievements).toHaveLength(1);
      expect(collectorAchievements[0].achievementId.name).toBe('Achievement 1');
    });
  });
});