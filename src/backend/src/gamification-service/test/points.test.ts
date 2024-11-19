// External dependencies
import { MongoMemoryServer } from 'mongodb-memory-server'; // v8.0+
import mongoose from 'mongoose'; // v7.5.0
import { jest } from '@jest/globals'; // v29.0+

// Internal dependencies
import { PointsService } from '../src/services/points.service';
import { IPointsTransaction, IUserPoints, PointsSourceType, PointsTransactionType } from '../src/models/points.model';

/**
 * Human Tasks:
 * 1. Configure test environment variables for MongoDB connection
 * 2. Set up test data seeding scripts if needed
 * 3. Configure test coverage reporting thresholds
 * 4. Set up continuous integration test pipeline
 */

describe('PointsService', () => {
  let mongoServer: MongoMemoryServer;
  let pointsService: PointsService;
  let transactionModel: mongoose.Model<IPointsTransaction>;
  let userPointsModel: mongoose.Model<IUserPoints>;

  // Test user data
  const testUserId = 'test-user-123';
  const testReferenceId = 'test-ref-123';

  beforeAll(async () => {
    // Requirement: 3.2.2 Data Management Strategy - Test database setup
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri);

    // Initialize models
    transactionModel = mongoose.model<IPointsTransaction>('PointsTransaction');
    userPointsModel = mongoose.model<IUserPoints>('UserPoints');

    // Create service instance
    pointsService = new PointsService(transactionModel, userPointsModel);
  });

  afterAll(async () => {
    // Cleanup test database
    await mongoose.disconnect();
    await mongoServer.stop();
  });

  beforeEach(async () => {
    // Clear collections before each test
    await transactionModel.deleteMany({});
    await userPointsModel.deleteMany({});
  });

  test('should award points correctly', async () => {
    // Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
    const pointsAmount = 100;
    const source = PointsSourceType.LISTING_CREATED;

    const transaction = await pointsService.awardPoints(
      testUserId,
      pointsAmount,
      source,
      testReferenceId
    );

    // Verify transaction created correctly
    expect(transaction).toBeDefined();
    expect(transaction.userId).toBe(testUserId);
    expect(transaction.amount).toBe(pointsAmount);
    expect(transaction.type).toBe(PointsTransactionType.EARNED);
    expect(transaction.source).toBe(source);
    expect(transaction.referenceId).toBe(testReferenceId);

    // Verify user points updated
    const userPoints = await pointsService.getUserPoints(testUserId);
    expect(userPoints.totalPoints).toBe(pointsAmount);
    expect(userPoints.lifetimePoints).toBe(pointsAmount);
    expect(userPoints.stats.earned).toBe(pointsAmount);
    expect(userPoints.stats.bySource[source]).toBe(pointsAmount);
  });

  test('should retrieve user points', async () => {
    // Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
    // Setup initial points
    await pointsService.awardPoints(
      testUserId,
      500,
      PointsSourceType.LISTING_CREATED,
      'ref-1'
    );
    await pointsService.awardPoints(
      testUserId,
      300,
      PointsSourceType.ITEM_COLLECTED,
      'ref-2'
    );

    const userPoints = await pointsService.getUserPoints(testUserId);

    // Verify points structure
    expect(userPoints).toBeDefined();
    expect(userPoints.userId).toBe(testUserId);
    expect(userPoints.totalPoints).toBe(800);
    expect(userPoints.lifetimePoints).toBe(800);
    expect(userPoints.level).toBeGreaterThan(1); // Level should increase
    expect(userPoints.stats.earned).toBe(800);
    expect(userPoints.stats.bySource[PointsSourceType.LISTING_CREATED]).toBe(500);
    expect(userPoints.stats.bySource[PointsSourceType.ITEM_COLLECTED]).toBe(300);
  });

  test('should get transaction history', async () => {
    // Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
    // Create multiple transactions
    const transactions = [
      { amount: 100, source: PointsSourceType.LISTING_CREATED, ref: 'ref-1' },
      { amount: 200, source: PointsSourceType.ITEM_COLLECTED, ref: 'ref-2' },
      { amount: 150, source: PointsSourceType.ACHIEVEMENT_COMPLETED, ref: 'ref-3' }
    ];

    for (const tx of transactions) {
      await pointsService.awardPoints(testUserId, tx.amount, tx.source, tx.ref);
    }

    const history = await pointsService.getTransactionHistory(testUserId, {
      page: 1,
      limit: 10,
      filters: {},
      sortBy: 'createdAt',
      sortOrder: 'desc'
    });

    // Verify transaction history
    expect(history).toHaveLength(3);
    expect(history[0].amount).toBe(150); // Most recent first
    expect(history[1].amount).toBe(200);
    expect(history[2].amount).toBe(100);

    // Verify transaction structure
    history.forEach(tx => {
      expect(tx.userId).toBe(testUserId);
      expect(tx.type).toBe(PointsTransactionType.EARNED);
      expect(tx.isActive).toBe(true);
      expect(tx.createdAt).toBeDefined();
      expect(tx.updatedAt).toBeDefined();
    });
  });

  test('should calculate level correctly', async () => {
    // Requirement: 1.2 System Overview/Success Criteria - User Engagement through gamification
    const testCases = [
      { points: 0, expectedLevel: 1 }, // Minimum level
      { points: 100, expectedLevel: 2 },
      { points: 1000, expectedLevel: 4 },
      { points: 10000, expectedLevel: 11 }
    ];

    for (const testCase of testCases) {
      await pointsService.awardPoints(
        testUserId,
        testCase.points,
        PointsSourceType.ACHIEVEMENT_COMPLETED,
        `level-test-${testCase.points}`
      );

      const userPoints = await pointsService.getUserPoints(testUserId);
      expect(userPoints.level).toBe(testCase.expectedLevel);

      // Clear points for next test case
      await userPointsModel.deleteMany({});
      await transactionModel.deleteMany({});
    }
  });

  test('should handle invalid points amount', async () => {
    // Requirement: 3.2.2 Data Management Strategy - Input validation
    await expect(
      pointsService.awardPoints(
        testUserId,
        -100,
        PointsSourceType.LISTING_CREATED,
        'invalid-test'
      )
    ).rejects.toThrow('Points amount must be positive');

    await expect(
      pointsService.awardPoints(
        testUserId,
        0,
        PointsSourceType.LISTING_CREATED,
        'invalid-test'
      )
    ).rejects.toThrow('Points amount must be positive');
  });

  test('should initialize new user points record', async () => {
    // Requirement: 3.1.7 Profile/Points Screen - Points tracking and management
    const newUserId = 'new-user-123';
    const userPoints = await pointsService.getUserPoints(newUserId);

    // Verify initial state
    expect(userPoints.userId).toBe(newUserId);
    expect(userPoints.totalPoints).toBe(0);
    expect(userPoints.lifetimePoints).toBe(0);
    expect(userPoints.level).toBe(1);
    expect(userPoints.stats.earned).toBe(0);
    expect(userPoints.stats.spent).toBe(0);
    expect(userPoints.stats.bonus).toBe(0);
    expect(userPoints.stats.achievement).toBe(0);
    
    // Verify all source types initialized to 0
    Object.values(PointsSourceType).forEach(source => {
      expect(userPoints.stats.bySource[source]).toBe(0);
    });
  });
});