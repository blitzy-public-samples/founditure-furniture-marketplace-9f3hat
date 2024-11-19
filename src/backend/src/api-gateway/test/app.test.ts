// External dependencies
import request from 'supertest'; // v6.3.0
import nock from 'nock'; // v13.3.0

// Internal dependencies
import app from '../src/app';
import { Logger } from '../../../shared/utils/logger';
import { ValidationError, AuthenticationError, AuthorizationError } from '../../../shared/utils/error';

/**
 * Human Tasks:
 * 1. Configure test environment variables for authentication and services
 * 2. Set up test database with sample data for integration tests
 * 3. Configure test monitoring and logging infrastructure
 * 4. Set up test coverage reporting thresholds
 * 5. Configure CI/CD pipeline test stages
 */

// Initialize test logger
const testLogger = new Logger('api-gateway-test');

// Requirement: 2.1 High-Level Architecture/Component Details - Testing request routing
describe('API Gateway Integration Tests', () => {
  // Setup before all tests
  beforeAll(async () => {
    testLogger.info('Starting API Gateway integration tests');
    // Clear any existing nock interceptors
    nock.cleanAll();
    // Set test environment variables
    process.env.NODE_ENV = 'test';
    process.env.JWT_SECRET = 'test-jwt-secret';
    process.env.REDIS_URL = 'redis://localhost:6379';
  });

  // Cleanup after all tests
  afterAll(async () => {
    testLogger.info('Completed API Gateway integration tests');
    // Restore environment
    nock.cleanAll();
    // Clean up any test resources
    await new Promise(resolve => setTimeout(resolve, 500));
  });

  // Requirement: 2.1 High-Level Architecture/Component Details - Testing middleware configuration
  describe('Middleware Configuration', () => {
    it('should configure security headers correctly', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.headers['x-frame-options']).toBe('DENY');
      expect(response.headers['x-xss-protection']).toBe('1; mode=block');
      expect(response.headers['x-content-type-options']).toBe('nosniff');
      expect(response.headers['strict-transport-security']).toBeDefined();
    });

    it('should configure CORS headers correctly', async () => {
      const response = await request(app)
        .options('/api/v1/health')
        .set('Origin', 'http://localhost:3000')
        .expect(204);

      expect(response.headers['access-control-allow-origin']).toBe('http://localhost:3000');
      expect(response.headers['access-control-allow-methods']).toBeDefined();
      expect(response.headers['access-control-allow-headers']).toBeDefined();
    });

    it('should parse JSON request bodies', async () => {
      const testData = { test: 'data' };
      const response = await request(app)
        .post('/api/v1/test')
        .send(testData)
        .expect(404); // Route doesn't exist but body should be parsed

      expect(response.body).toBeDefined();
    });

    it('should apply rate limiting', async () => {
      // Make multiple requests to trigger rate limit
      const requests = Array(150).fill(null).map(() =>
        request(app).get('/health')
      );

      const responses = await Promise.all(requests);
      const tooManyRequests = responses.some(r => r.status === 429);
      expect(tooManyRequests).toBe(true);
    });
  });

  // Requirement: 2.5 Security Architecture/Security Controls - Testing authentication
  describe('Authentication Flow', () => {
    const validToken = 'valid.jwt.token';
    const expiredToken = 'expired.jwt.token';
    const invalidToken = 'invalid.token';

    it('should reject requests without authentication token', async () => {
      const response = await request(app)
        .get('/api/v1/protected')
        .expect(401);

      expect(response.body.message).toBe('No authentication token provided');
    });

    it('should reject requests with invalid JWT format', async () => {
      const response = await request(app)
        .get('/api/v1/protected')
        .set('Authorization', `Bearer ${invalidToken}`)
        .expect(401);

      expect(response.body.message).toBe('Invalid authentication token');
    });

    it('should reject requests with expired JWT token', async () => {
      const response = await request(app)
        .get('/api/v1/protected')
        .set('Authorization', `Bearer ${expiredToken}`)
        .expect(401);

      expect(response.body.message).toBe('Authentication token has expired');
    });

    it('should accept requests with valid JWT token', async () => {
      const response = await request(app)
        .get('/api/v1/protected')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should enforce role-based access control', async () => {
      const response = await request(app)
        .get('/api/v1/admin')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(403);

      expect(response.body.message).toContain('Access denied');
    });
  });

  // Requirement: 2.4 Cross-Cutting Concerns/System Monitoring - Testing error handling
  describe('Error Handling', () => {
    it('should handle validation errors with 400 status', async () => {
      const response = await request(app)
        .post('/api/v1/test')
        .send({})
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should handle authentication errors with 401 status', async () => {
      const response = await request(app)
        .get('/api/v1/protected')
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.code).toBe('UNAUTHORIZED');
    });

    it('should handle authorization errors with 403 status', async () => {
      const response = await request(app)
        .get('/api/v1/admin')
        .set('Authorization', 'Bearer valid.token')
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.code).toBe('FORBIDDEN');
    });

    it('should handle 404 not found errors', async () => {
      const response = await request(app)
        .get('/api/v1/nonexistent')
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('not found');
    });

    it('should handle internal server errors with 500 status', async () => {
      // Mock an endpoint that throws an error
      nock('http://internal-service')
        .get('/error')
        .replyWithError('Internal server error');

      const response = await request(app)
        .get('/api/v1/error')
        .expect(500);

      expect(response.body.success).toBe(false);
      expect(response.body.code).toBe('INTERNAL_ERROR');
    });
  });

  // Requirement: 2.1 High-Level Architecture/Component Details - Testing API routing
  describe('API Routing', () => {
    it('should respond to health check endpoint', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body.status).toBe('healthy');
      expect(response.body.timestamp).toBeDefined();
      expect(response.body.uptime).toBeDefined();
    });

    it('should include API version in headers', async () => {
      const response = await request(app)
        .get('/api/v1/health')
        .expect(200);

      expect(response.headers['x-api-version']).toBe('1.0');
    });

    it('should handle route parameters correctly', async () => {
      const response = await request(app)
        .get('/api/v1/users/123')
        .expect(404); // Route doesn't exist but parameter should be parsed

      expect(response.body.path).toContain('123');
    });

    it('should parse query parameters correctly', async () => {
      const response = await request(app)
        .get('/api/v1/test?page=1&limit=10')
        .expect(404); // Route doesn't exist but query should be parsed

      expect(response.body.path).toContain('page=1');
    });

    it('should validate request body', async () => {
      const invalidData = { invalid: 'data' };
      const response = await request(app)
        .post('/api/v1/test')
        .send(invalidData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });
  });
});