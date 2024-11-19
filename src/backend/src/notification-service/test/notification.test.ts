// External dependencies
import request from 'supertest'; // v6.x
import { MongoMemoryServer } from 'mongodb-memory-server'; // v8.x
import mongoose from 'mongoose'; // v7.5.x

// Internal dependencies
import App from '../src/app';
import { NotificationType } from '../../../shared/types';
import { INotification } from '../src/models/notification.model';

/**
 * Human Tasks:
 * 1. Configure test environment variables for Firebase Admin SDK
 * 2. Set up test coverage reporting and thresholds
 * 3. Configure CI/CD pipeline for automated testing
 * 4. Set up test data cleanup procedures
 * 5. Configure test monitoring and reporting
 */

describe('Notification Service Integration Tests', () => {
  let app: App;
  let mongoServer: MongoMemoryServer;
  let testServer: any;
  let authToken: string;

  // Mock user data for testing
  const testUser = {
    id: '507f1f77bcf86cd799439011',
    email: 'test@example.com'
  };

  // Sample notification data
  const sampleNotification = {
    userId: testUser.id,
    type: NotificationType.MESSAGE,
    title: 'Test Notification',
    message: 'This is a test notification message',
    imageUrl: 'https://example.com/image.jpg',
    actionUrl: 'https://example.com/action'
  };

  /**
   * Setup before all tests
   * Requirements addressed:
   * - Push Notification System (1.3 Scope/Core Features)
   * - Real-time Messaging (2.2.1 Core Components/Messaging Service)
   */
  beforeAll(async () => {
    // Start in-memory MongoDB server
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();

    // Configure MongoDB connection
    await mongoose.connect(mongoUri);

    // Initialize application
    app = new App();
    testServer = app.listen();

    // Mock authentication token
    authToken = 'Bearer test_token';
  });

  /**
   * Cleanup after all tests
   */
  afterAll(async () => {
    // Close connections and servers
    await mongoose.disconnect();
    await mongoServer.stop();
    await new Promise<void>((resolve) => testServer.close(() => resolve()));
  });

  /**
   * Reset database before each test
   */
  beforeEach(async () => {
    // Clear all collections
    await Promise.all(
      Object.values(mongoose.connection.collections).map(collection =>
        collection.deleteMany({})
      )
    );
  });

  /**
   * Test notification creation endpoint
   * Requirement: Push Notification System - Real-time user alerts
   */
  describe('POST /api/notifications', () => {
    it('should create a new notification successfully', async () => {
      const response = await request(testServer)
        .post('/api/notifications')
        .set('Authorization', authToken)
        .send(sampleNotification);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toMatchObject({
        userId: testUser.id,
        type: NotificationType.MESSAGE,
        title: sampleNotification.title,
        message: sampleNotification.message,
        isRead: false,
        isDelivered: false
      });
    });

    it('should validate required notification fields', async () => {
      const invalidNotification = {
        userId: testUser.id,
        // Missing required fields
      };

      const response = await request(testServer)
        .post('/api/notifications')
        .set('Authorization', authToken)
        .send(invalidNotification);

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });
  });

  /**
   * Test retrieving notifications endpoint
   * Requirement: Push Notification System - Notification management
   */
  describe('GET /api/notifications', () => {
    beforeEach(async () => {
      // Create test notifications
      const notifications = [
        { ...sampleNotification },
        { ...sampleNotification, title: 'Second Notification' },
        { ...sampleNotification, title: 'Third Notification' }
      ];

      await Promise.all(
        notifications.map(notification =>
          request(testServer)
            .post('/api/notifications')
            .set('Authorization', authToken)
            .send(notification)
        )
      );
    });

    it('should retrieve paginated notifications', async () => {
      const response = await request(testServer)
        .get('/api/notifications')
        .set('Authorization', authToken)
        .query({ page: 1, limit: 2 });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data.length).toBe(2);
    });

    it('should filter notifications by type', async () => {
      const response = await request(testServer)
        .get('/api/notifications')
        .set('Authorization', authToken)
        .query({ type: NotificationType.MESSAGE });

      expect(response.status).toBe(200);
      expect(response.body.data.every((n: INotification) => n.type === NotificationType.MESSAGE)).toBe(true);
    });
  });

  /**
   * Test retrieving single notification endpoint
   * Requirement: Push Notification System - Notification management
   */
  describe('GET /api/notifications/:id', () => {
    let testNotificationId: string;

    beforeEach(async () => {
      // Create test notification
      const response = await request(testServer)
        .post('/api/notifications')
        .set('Authorization', authToken)
        .send(sampleNotification);

      testNotificationId = response.body.data.id;
    });

    it('should retrieve notification by ID', async () => {
      const response = await request(testServer)
        .get(`/api/notifications/${testNotificationId}`)
        .set('Authorization', authToken);

      expect(response.status).toBe(200);
      expect(response.body.data.id).toBe(testNotificationId);
    });

    it('should return 404 for non-existent notification', async () => {
      const response = await request(testServer)
        .get('/api/notifications/507f1f77bcf86cd799439011')
        .set('Authorization', authToken);

      expect(response.status).toBe(404);
    });
  });

  /**
   * Test marking notification as read endpoint
   * Requirement: Push Notification System - Notification status management
   */
  describe('PATCH /api/notifications/:id/read', () => {
    let testNotificationId: string;

    beforeEach(async () => {
      // Create test notification
      const response = await request(testServer)
        .post('/api/notifications')
        .set('Authorization', authToken)
        .send(sampleNotification);

      testNotificationId = response.body.data.id;
    });

    it('should mark notification as read', async () => {
      const response = await request(testServer)
        .patch(`/api/notifications/${testNotificationId}/read`)
        .set('Authorization', authToken);

      expect(response.status).toBe(200);
      expect(response.body.data.isRead).toBe(true);
      expect(response.body.data.readAt).toBeDefined();
    });
  });

  /**
   * Test marking notification as delivered endpoint
   * Requirement: Push Notification System - Delivery tracking
   */
  describe('PATCH /api/notifications/:id/delivered', () => {
    let testNotificationId: string;

    beforeEach(async () => {
      // Create test notification
      const response = await request(testServer)
        .post('/api/notifications')
        .set('Authorization', authToken)
        .send(sampleNotification);

      testNotificationId = response.body.data.id;
    });

    it('should mark notification as delivered', async () => {
      const response = await request(testServer)
        .patch(`/api/notifications/${testNotificationId}/delivered`)
        .set('Authorization', authToken);

      expect(response.status).toBe(200);
      expect(response.body.data.isDelivered).toBe(true);
      expect(response.body.data.deliveredAt).toBeDefined();
    });
  });
});