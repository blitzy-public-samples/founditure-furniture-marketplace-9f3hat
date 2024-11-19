// External dependencies
import { MongoMemoryServer } from 'mongodb-memory-server'; // v8.12.0
import mongoose from 'mongoose'; // v7.5.0
import { validate } from 'class-validator'; // v0.14.0

// Internal dependencies
import { AuthService, LoginCredentials, RegisterData } from '../src/services/auth.service';
import { User, AuthProvider, UserRole } from '../src/models/user.model';

/**
 * Human Tasks:
 * 1. Ensure test environment variables are properly configured
 * 2. Set up test data seeding scripts if needed
 * 3. Configure test coverage reporting thresholds
 * 4. Set up continuous integration test pipeline
 * 5. Configure test logging and error reporting
 */

describe('AuthService', () => {
  let mongod: MongoMemoryServer;
  let authService: AuthService;
  let testUser: User;

  // Requirement: 5.1.1 Authentication Methods - Test environment setup
  beforeAll(async () => {
    // Start in-memory MongoDB server
    mongod = await MongoMemoryServer.create();
    const uri = mongod.getUri();

    // Connect to in-memory database
    await mongoose.connect(uri);

    // Initialize test user model
    const UserModel = mongoose.model('User', mongoose.Schema.from(User));
    
    // Initialize auth service with test dependencies
    authService = new AuthService(UserModel);

    // Create test user
    testUser = new User({
      email: 'test@example.com',
      provider: AuthProvider.EMAIL,
      role: UserRole.BASIC_USER,
      isActive: true,
      profile: {
        displayName: 'Test User',
        avatarUrl: '',
        bio: '',
        phoneNumber: '',
        dateOfBirth: new Date(),
        interests: []
      }
    });
    testUser.passwordHash = await testUser.hashPassword('Test123!@#');
    await UserModel.create(testUser);
  });

  afterAll(async () => {
    // Cleanup test environment
    await mongoose.disconnect();
    await mongod.stop();
  });

  // Requirement: 5.1.1 Authentication Methods - Login functionality tests
  describe('login', () => {
    it('should successfully login with valid email/password', async () => {
      const credentials: LoginCredentials = {
        email: 'test@example.com',
        password: 'Test123!@#'
      };

      const result = await authService.login(credentials);

      expect(result.user).toBeDefined();
      expect(result.accessToken).toBeDefined();
      expect(result.refreshToken).toBeDefined();
      expect(result.user.email).toBe(credentials.email);
    });

    it('should fail login with invalid password', async () => {
      const credentials: LoginCredentials = {
        email: 'test@example.com',
        password: 'wrongpassword'
      };

      await expect(authService.login(credentials)).rejects.toThrow('Invalid password');
    });

    it('should fail login with non-existent user', async () => {
      const credentials: LoginCredentials = {
        email: 'nonexistent@example.com',
        password: 'Test123!@#'
      };

      await expect(authService.login(credentials)).rejects.toThrow('User not found');
    });

    it('should fail login with inactive user', async () => {
      // Set test user to inactive
      testUser.isActive = false;
      await testUser.save();

      const credentials: LoginCredentials = {
        email: 'test@example.com',
        password: 'Test123!@#'
      };

      await expect(authService.login(credentials)).rejects.toThrow('User not found');

      // Reset user to active
      testUser.isActive = true;
      await testUser.save();
    });
  });

  // Requirement: 5.1.1 Authentication Methods - Registration functionality tests
  describe('register', () => {
    it('should successfully register new user with email provider', async () => {
      const registerData: RegisterData = {
        email: 'newuser@example.com',
        password: 'NewUser123!@#',
        displayName: 'New User',
        provider: AuthProvider.EMAIL
      };

      const result = await authService.register(registerData);

      expect(result.user).toBeDefined();
      expect(result.accessToken).toBeDefined();
      expect(result.refreshToken).toBeDefined();
      expect(result.user.email).toBe(registerData.email);
      expect(result.user.provider).toBe(AuthProvider.EMAIL);
    });

    it('should fail registration with existing email', async () => {
      const registerData: RegisterData = {
        email: 'test@example.com',
        password: 'Test123!@#',
        displayName: 'Duplicate User',
        provider: AuthProvider.EMAIL
      };

      await expect(authService.register(registerData)).rejects.toThrow('Email already registered');
    });

    it('should successfully register with social provider', async () => {
      const registerData: RegisterData = {
        email: 'social@example.com',
        password: '',
        displayName: 'Social User',
        provider: AuthProvider.GOOGLE,
        providerId: 'google123'
      };

      const result = await authService.register(registerData);

      expect(result.user).toBeDefined();
      expect(result.user.provider).toBe(AuthProvider.GOOGLE);
      expect(result.user.providerId).toBe('google123');
    });
  });

  // Requirement: 5.1.1 Authentication Methods - Token refresh functionality tests
  describe('refreshToken', () => {
    let validRefreshToken: string;

    beforeAll(async () => {
      const loginResult = await authService.login({
        email: 'test@example.com',
        password: 'Test123!@#'
      });
      validRefreshToken = loginResult.refreshToken;
    });

    it('should successfully refresh access token', async () => {
      const newAccessToken = await authService.refreshToken(validRefreshToken);
      expect(newAccessToken).toBeDefined();
      expect(typeof newAccessToken).toBe('string');
    });

    it('should fail refresh with invalid token', async () => {
      await expect(authService.refreshToken('invalid-token')).rejects.toThrow();
    });
  });

  // Requirement: 5.1.2 Authorization Model - User validation tests
  describe('validateUser', () => {
    it('should successfully validate existing active user', async () => {
      const user = await authService.validateUser(testUser.id);
      expect(user).toBeDefined();
      expect(user.id).toBe(testUser.id);
    });

    it('should fail validation for non-existent user', async () => {
      const nonExistentId = new mongoose.Types.ObjectId().toString();
      await expect(authService.validateUser(nonExistentId)).rejects.toThrow('User not found or inactive');
    });

    it('should fail validation for inactive user', async () => {
      testUser.isActive = false;
      await testUser.save();

      await expect(authService.validateUser(testUser.id)).rejects.toThrow('User not found or inactive');

      testUser.isActive = true;
      await testUser.save();
    });

    it('should fail validation for deleted user', async () => {
      testUser.isDeleted = true;
      await testUser.save();

      await expect(authService.validateUser(testUser.id)).rejects.toThrow('User not found or inactive');

      testUser.isDeleted = false;
      await testUser.save();
    });
  });
});