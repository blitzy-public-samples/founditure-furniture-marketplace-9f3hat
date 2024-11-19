/**
 * Human Tasks:
 * 1. Set up Firebase Admin SDK credentials in deployment environments
 * 2. Configure secure storage for JWT secrets in production
 * 3. Review and adjust CORS settings for production domains
 * 4. Set up database connection strings in environment variables
 * 5. Configure rate limiting parameters in production
 */

// External dependencies
import * as dotenv from 'dotenv'; // v16.0.0
import * as admin from 'firebase-admin'; // v11.0.0

// Internal dependencies
import { AUTH_CONSTANTS, SERVICE_ENDPOINTS } from '../../../shared/constants';

// Load environment variables
dotenv.config();

/**
 * Interface defining the structure of the auth service configuration
 * Requirement: 5.1.1 Authentication Methods - Primary authentication using Firebase Auth
 */
export interface Config {
  nodeEnv: string;
  port: number;
  database: {
    url: string;
    options: {
      useNewUrlParser: boolean;
      useUnifiedTopology: boolean;
      retryWrites: boolean;
      maxPoolSize: number;
    };
  };
  jwt: {
    secret: string;
    expiry: number;
    refreshTokenExpiry: number;
  };
  firebase: {
    projectId: string;
    clientEmail: string;
    privateKey: string;
    databaseURL: string;
  };
  cors: {
    origin: string[];
    methods: string[];
    allowedHeaders: string[];
    exposedHeaders: string[];
    credentials: boolean;
    maxAge: number;
  };
}

/**
 * Validates that all required environment variables are present and correctly formatted
 * Requirement: 5.3.2 Security Controls - Input validation and security implementation
 */
const validateConfig = (): void => {
  const requiredVars = [
    'NODE_ENV',
    'PORT',
    'DB_URL',
    'JWT_SECRET',
    'FIREBASE_PROJECT_ID',
    'FIREBASE_CLIENT_EMAIL',
    'FIREBASE_PRIVATE_KEY',
    'FIREBASE_DATABASE_URL',
    'ALLOWED_ORIGINS'
  ];

  const missingVars = requiredVars.filter(
    (varName) => !process.env[varName]
  );

  if (missingVars.length > 0) {
    throw new Error(
      `Missing required environment variables: ${missingVars.join(', ')}`
    );
  }

  // Validate environment-specific variables
  if (!['development', 'staging', 'production'].includes(process.env.NODE_ENV!)) {
    throw new Error('Invalid NODE_ENV value');
  }

  // Validate port number
  const port = parseInt(process.env.PORT!, 10);
  if (isNaN(port) || port <= 0) {
    throw new Error('Invalid PORT value');
  }

  // Validate database URL format
  const dbUrlPattern = /^mongodb(\+srv)?:\/\/.+/;
  if (!dbUrlPattern.test(process.env.DB_URL!)) {
    throw new Error('Invalid DB_URL format');
  }

  // Validate Firebase credentials
  try {
    JSON.parse(process.env.FIREBASE_PRIVATE_KEY!);
  } catch (error) {
    throw new Error('Invalid FIREBASE_PRIVATE_KEY format');
  }
};

/**
 * Loads and returns the configuration object based on current environment
 * Requirement: 3.3.1 API Architecture - REST/HTTP/2 with JWT authentication
 */
const loadConfig = (): Config => {
  // Validate configuration
  validateConfig();

  // Initialize Firebase Admin SDK
  const firebaseConfig = {
    projectId: process.env.FIREBASE_PROJECT_ID!,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL!,
    privateKey: process.env.FIREBASE_PRIVATE_KEY!.replace(/\\n/g, '\n'),
    databaseURL: process.env.FIREBASE_DATABASE_URL!
  };

  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: firebaseConfig.projectId,
      clientEmail: firebaseConfig.clientEmail,
      privateKey: firebaseConfig.privateKey
    }),
    databaseURL: firebaseConfig.databaseURL
  });

  // Parse allowed origins
  const allowedOrigins = process.env.ALLOWED_ORIGINS!.split(',').map(
    origin => origin.trim()
  );

  // Construct configuration object
  const config: Config = {
    nodeEnv: process.env.NODE_ENV!,
    port: parseInt(process.env.PORT!, 10),
    database: {
      url: process.env.DB_URL!,
      options: {
        useNewUrlParser: true,
        useUnifiedTopology: true,
        retryWrites: true,
        maxPoolSize: 10
      }
    },
    jwt: {
      secret: process.env.JWT_SECRET!,
      expiry: AUTH_CONSTANTS.JWT_EXPIRY,
      refreshTokenExpiry: AUTH_CONSTANTS.REFRESH_TOKEN_EXPIRY
    },
    firebase: firebaseConfig,
    cors: {
      origin: allowedOrigins,
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: [
        'Content-Type',
        'Authorization',
        'X-Requested-With',
        'Accept',
        'Origin'
      ],
      exposedHeaders: ['X-Total-Count', 'X-Rate-Limit'],
      credentials: true,
      maxAge: 86400 // 24 hours
    }
  };

  return config;
};

// Export the configuration object
export const config = loadConfig();