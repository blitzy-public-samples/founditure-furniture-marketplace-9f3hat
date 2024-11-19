// External dependencies
import * as admin from 'firebase-admin'; // v11.0.0
import { IsNotEmpty, IsUrl, validateOrReject } from 'class-validator'; // v0.14.0

// Internal dependencies
import { INotification } from '../models/notification.model';
import { Logger } from '../../../shared/utils/logger';

/**
 * Human Tasks:
 * 1. Configure Firebase Admin SDK credentials in environment variables
 * 2. Set up Firebase Cloud Messaging project and obtain configuration
 * 3. Configure monitoring for push notification delivery metrics
 * 4. Set up error alerting for failed notification batches
 * 5. Implement retry mechanism for failed notifications if needed
 */

// Initialize logger
const logger = new Logger('PushNotificationService');

// Constants
const MAX_TOKENS_PER_REQUEST = 500; // Firebase limit for batch notifications

// Class for validating push notification payload
class PushNotificationPayload {
  @IsNotEmpty()
  title: string;

  @IsNotEmpty()
  message: string;

  @IsUrl()
  @IsNotEmpty()
  imageUrl?: string;

  @IsUrl()
  @IsNotEmpty()
  actionUrl?: string;
}

/**
 * Initializes Firebase Admin SDK for push notification delivery
 * Requirement: Push Notification System - Firebase Cloud Messaging integration
 */
export const initializePushService = async (): Promise<void> => {
  try {
    // Parse Firebase configuration from environment variables
    const firebaseConfig = JSON.parse(process.env.FIREBASE_CONFIG || '');

    if (!firebaseConfig) {
      throw new Error('Firebase configuration not found in environment variables');
    }

    // Initialize Firebase Admin SDK
    admin.initializeApp({
      credential: admin.credential.cert(firebaseConfig),
      projectId: firebaseConfig.project_id
    });

    logger.info('Firebase Admin SDK initialized successfully for push notifications');
  } catch (error) {
    logger.error('Failed to initialize Firebase Admin SDK', error);
    throw error;
  }
};

/**
 * Validates push notification payload before sending
 * Requirement: Push Notification System - Payload validation
 */
const validatePushPayload = async (notification: INotification): Promise<boolean> => {
  try {
    const payload = new PushNotificationPayload();
    payload.title = notification.title;
    payload.message = notification.message;
    if (notification.imageUrl) payload.imageUrl = notification.imageUrl;
    if (notification.actionUrl) payload.actionUrl = notification.actionUrl;

    await validateOrReject(payload);

    // Additional validation for notification type
    if (!Object.values(notification.type).includes(notification.type)) {
      throw new Error(`Invalid notification type: ${notification.type}`);
    }

    return true;
  } catch (error) {
    logger.error('Push notification payload validation failed', error);
    return false;
  }
};

/**
 * Constructs FCM-compatible push notification payload
 * Requirement: Push Notification System - FCM payload formatting
 */
const constructPushPayload = (notification: INotification): admin.messaging.Message => {
  const payload: admin.messaging.Message = {
    notification: {
      title: notification.title,
      body: notification.message,
    },
    data: {
      type: notification.type,
      click_action: 'FLUTTER_NOTIFICATION_CLICK', // For Flutter apps
      ...notification.metadata
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'default',
        priority: 'high',
        defaultSound: true,
        defaultVibrateTimings: true
      }
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1
        }
      }
    }
  };

  // Add image if present
  if (notification.imageUrl) {
    payload.notification!.imageUrl = notification.imageUrl;
  }

  // Add action URL if present
  if (notification.actionUrl) {
    payload.data!.action_url = notification.actionUrl;
  }

  return payload;
};

/**
 * Sends push notification to specified device tokens with batching support
 * Requirement: Push Notification System - Real-time user alerts
 * Requirement: Real-time Messaging - Message notification delivery
 * Requirement: Gamification System - Achievement notifications
 */
export const sendPushNotification = async (
  notification: INotification,
  deviceTokens: string[]
): Promise<boolean> => {
  try {
    // Validate notification payload
    const isValid = await validatePushPayload(notification);
    if (!isValid) {
      throw new Error('Invalid push notification payload');
    }

    // Skip if no device tokens
    if (!deviceTokens.length) {
      logger.info('No device tokens provided for push notification');
      return false;
    }

    // Construct FCM message payload
    const messagePayload = constructPushPayload(notification);

    // Split device tokens into chunks for batch processing
    const tokenChunks = [];
    for (let i = 0; i < deviceTokens.length; i += MAX_TOKENS_PER_REQUEST) {
      tokenChunks.push(deviceTokens.slice(i, i + MAX_TOKENS_PER_REQUEST));
    }

    // Send notifications in batches
    const results = await Promise.all(
      tokenChunks.map(async (tokens) => {
        try {
          const batchResponse = await admin.messaging().sendMulticast({
            ...messagePayload,
            tokens
          });

          // Log failed deliveries
          if (batchResponse.failureCount > 0) {
            const failedTokens = batchResponse.responses
              .map((resp, idx) => resp.success ? null : tokens[idx])
              .filter(token => token !== null);

            logger.error('Failed to deliver push notifications', {
              failureCount: batchResponse.failureCount,
              failedTokens
            });
          }

          return batchResponse.successCount > 0;
        } catch (error) {
          logger.error('Batch push notification delivery failed', error);
          return false;
        }
      })
    );

    // Return true if any batch was successful
    return results.some(result => result);
  } catch (error) {
    logger.error('Push notification delivery failed', error);
    return false;
  }
};