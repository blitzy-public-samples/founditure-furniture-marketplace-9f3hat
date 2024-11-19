// External dependencies
import * as admin from 'firebase-admin'; // v11.x
import * as dotenv from 'dotenv'; // v16.x

// Internal dependencies
import { SERVICE_ENDPOINTS } from '../../../shared/constants';
import { NotificationType } from '../../../shared/types';

/**
 * Human Tasks:
 * 1. Set up Firebase project and obtain service account credentials
 * 2. Configure environment variables:
 *    - FIREBASE_PROJECT_ID
 *    - FIREBASE_CLIENT_EMAIL
 *    - FIREBASE_PRIVATE_KEY
 *    - FIREBASE_DATABASE_URL (optional)
 *    - FIREBASE_STORAGE_BUCKET (optional)
 * 3. Review and adjust notification delivery settings (TTL, batch size, retry attempts)
 * 4. Ensure Firebase Admin SDK initialization in deployment environments
 */

// Initialize dotenv to load environment variables
dotenv.config();

/**
 * Loads and validates Firebase configuration from environment variables
 * Requirement: 2.1 High-Level Architecture - Firebase Integration
 */
const loadFirebaseConfig = (): admin.ServiceAccount & { options: admin.AppOptions } => {
  // Validate required environment variables
  const requiredEnvVars = [
    'FIREBASE_PROJECT_ID',
    'FIREBASE_CLIENT_EMAIL',
    'FIREBASE_PRIVATE_KEY'
  ];

  for (const envVar of requiredEnvVars) {
    if (!process.env[envVar]) {
      throw new Error(`Missing required environment variable: ${envVar}`);
    }
  }

  // Parse and format Firebase private key (handles escaped newlines)
  const privateKey = process.env.FIREBASE_PRIVATE_KEY!.replace(/\\n/g, '\n');

  // Construct Firebase configuration
  return {
    projectId: process.env.FIREBASE_PROJECT_ID!,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL!,
    privateKey: privateKey,
    options: {
      databaseURL: process.env.FIREBASE_DATABASE_URL,
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET
    }
  };
};

// Initialize Firebase Admin SDK
const firebaseConfig = loadFirebaseConfig();
const firebase = admin.initializeApp({
  credential: admin.credential.cert({
    projectId: firebaseConfig.projectId,
    clientEmail: firebaseConfig.clientEmail,
    privateKey: firebaseConfig.privateKey
  }),
  ...firebaseConfig.options
});

/**
 * Notification service configuration
 * Requirements addressed:
 * - 1.3 Scope/Core Features - Push Notification System
 * - 2.2.1 Core Components/Messaging Service - Real-time Messaging
 */
const config = {
  firebase,
  notifications: {
    // Default time-to-live for notifications in seconds (24 hours)
    defaultTTL: 86400,
    
    // Maximum number of notifications to process in a single batch
    batchSize: 500,
    
    // Number of retry attempts for failed notification deliveries
    retryAttempts: 3,
    
    // Supported notification types
    types: [
      NotificationType.LISTING,
      NotificationType.MESSAGE,
      NotificationType.ACHIEVEMENT,
      NotificationType.SYSTEM
    ],

    // Messaging service endpoint for internal communication
    messagingServiceUrl: SERVICE_ENDPOINTS.MESSAGING_SERVICE
  }
};

export default config;