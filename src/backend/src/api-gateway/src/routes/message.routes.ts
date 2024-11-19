// External dependencies
import { Router } from 'express'; // v4.18.0
import { StatusCodes } from 'http-status-codes'; // v2.2.0
import * as Joi from 'joi'; // v17.9.0

// Internal dependencies
import { authenticate } from '../middleware/auth.middleware';
import { validateBody, validateQuery } from '../middleware/validation.middleware';
import { MessageType } from '../../../../shared/types';

/**
 * Human Tasks:
 * 1. Configure rate limiting for message endpoints
 * 2. Set up WebSocket/Socket.IO for real-time message delivery
 * 3. Configure message queue for asynchronous message processing
 * 4. Set up monitoring for message delivery latency
 * 5. Configure message content filtering and moderation rules
 */

// Initialize router
const messageRouter = Router();

// Validation schemas
const createMessageSchema = Joi.object({
  conversationId: Joi.string().required(),
  content: Joi.string().required().max(2000),
  type: Joi.string().valid(...Object.values(MessageType)).required(),
  metadata: Joi.object().optional()
});

const paginationSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20)
});

// Requirement: Real-time Messaging - Message creation endpoint
messageRouter.post(
  '/messages',
  authenticate,
  validateBody(createMessageSchema),
  async (req, res, next) => {
    try {
      const { conversationId, content, type, metadata } = req.validatedBody;
      const userId = req.user?.userId;

      // Forward request to messaging service
      const response = await fetch(`${process.env.MESSAGING_SERVICE_URL}/messages`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-User-ID': userId
        },
        body: JSON.stringify({
          conversationId,
          senderId: userId,
          content,
          type,
          metadata
        })
      });

      if (!response.ok) {
        throw new Error('Failed to create message');
      }

      const message = await response.json();
      res.status(StatusCodes.CREATED).json({
        success: true,
        message: 'Message created successfully',
        data: message
      });
    } catch (error) {
      next(error);
    }
  }
);

// Requirement: Messaging Interface - Conversation retrieval endpoint
messageRouter.get(
  '/messages/:conversationId',
  authenticate,
  validateQuery(paginationSchema),
  async (req, res, next) => {
    try {
      const { conversationId } = req.params;
      const { page, limit } = req.validatedQuery;
      const userId = req.user?.userId;

      // Forward request to messaging service
      const response = await fetch(
        `${process.env.MESSAGING_SERVICE_URL}/messages/${conversationId}?` +
        `page=${page}&limit=${limit}&userId=${userId}`,
        {
          headers: {
            'X-User-ID': userId
          }
        }
      );

      if (!response.ok) {
        throw new Error('Failed to retrieve conversation messages');
      }

      const messages = await response.json();
      res.status(StatusCodes.OK).json({
        success: true,
        message: 'Messages retrieved successfully',
        data: messages
      });
    } catch (error) {
      next(error);
    }
  }
);

// Requirement: Messaging Interface - User conversations listing endpoint
messageRouter.get(
  '/messages/conversations',
  authenticate,
  validateQuery(paginationSchema),
  async (req, res, next) => {
    try {
      const { page, limit } = req.validatedQuery;
      const userId = req.user?.userId;

      // Forward request to messaging service
      const response = await fetch(
        `${process.env.MESSAGING_SERVICE_URL}/conversations?` +
        `page=${page}&limit=${limit}&userId=${userId}`,
        {
          headers: {
            'X-User-ID': userId
          }
        }
      );

      if (!response.ok) {
        throw new Error('Failed to retrieve user conversations');
      }

      const conversations = await response.json();
      res.status(StatusCodes.OK).json({
        success: true,
        message: 'Conversations retrieved successfully',
        data: conversations
      });
    } catch (error) {
      next(error);
    }
  }
);

// Requirement: Messaging Interface - Message read status update endpoint
messageRouter.post(
  '/messages/:messageId/read',
  authenticate,
  async (req, res, next) => {
    try {
      const { messageId } = req.params;
      const userId = req.user?.userId;

      // Forward request to messaging service
      const response = await fetch(
        `${process.env.MESSAGING_SERVICE_URL}/messages/${messageId}/read`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-User-ID': userId
          },
          body: JSON.stringify({ userId })
        }
      );

      if (!response.ok) {
        throw new Error('Failed to mark message as read');
      }

      res.status(StatusCodes.OK).json({
        success: true,
        message: 'Message marked as read successfully'
      });
    } catch (error) {
      next(error);
    }
  }
);

export default messageRouter;