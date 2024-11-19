// External dependencies
import { Request, Response } from 'express'; // v4.18.0
import { validate } from 'class-validator'; // v0.14.0
import { plainToClass } from 'class-transformer'; // v0.5.1

// Internal dependencies
import { Controller } from '../../../shared/interfaces/controller.interface';
import { MessageService } from '../services/message.service';
import { Message, MessageType, MessageStatus } from '../models/message.model';

/**
 * Human Tasks:
 * 1. Configure authentication middleware for user context
 * 2. Set up request validation middleware
 * 3. Configure rate limiting for message endpoints
 * 4. Set up proper monitoring for message delivery tracking
 * 5. Configure logging for message events
 */

/**
 * Controller implementing messaging endpoints for real-time communication
 * Requirement: 1.2 System Overview/Core Features - Real-time messaging between users
 * Requirement: 2.3.1 Architecture Patterns/API Gateway - REST endpoints with standardized handling
 */
@Controller('messages')
@UseGuards(AuthGuard)
export class MessageController implements Controller<Message> {
    constructor(private readonly messageService: MessageService) {}

    /**
     * Creates a new message with real-time delivery
     * Requirement: 1.2 System Overview - Real-time messaging between users
     */
    @Post()
    @UseValidation(CreateMessageDto)
    async create(req: Request, res: Response): Promise<Response> {
        try {
            // Extract user ID from authenticated request
            const userId = req.user.id;

            // Validate message creation DTO
            const messageData = plainToClass(CreateMessageDto, req.body);
            const errors = await validate(messageData);
            if (errors.length > 0) {
                return res.status(400).json({
                    success: false,
                    status: 400,
                    message: 'Validation failed',
                    errors: errors.map(error => ({
                        field: error.property,
                        message: Object.values(error.constraints || {}).join(', '),
                        code: 'VALIDATION_ERROR'
                    }))
                });
            }

            // Create message with real-time delivery
            const message = await this.messageService.createMessage(messageData, userId);

            return res.status(201).json({
                success: true,
                status: 201,
                message: 'Message created successfully',
                data: message
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                status: 500,
                message: 'Failed to create message',
                errors: [{ message: error.message }]
            });
        }
    }

    /**
     * Retrieves paginated message thread for a listing
     * Requirement: 1.2 System Overview - Real-time messaging between users
     */
    @Get('thread/:listingId')
    async getThread(req: Request, res: Response): Promise<Response> {
        try {
            const userId = req.user.id;
            const { listingId } = req.params;
            const { page = 1, limit = 50, sortOrder = 'desc' } = req.query;

            const messages = await this.messageService.getMessageThread(
                listingId,
                userId,
                {
                    page: Number(page),
                    limit: Number(limit),
                    sortOrder: sortOrder as 'asc' | 'desc'
                }
            );

            return res.status(200).json({
                success: true,
                status: 200,
                message: 'Message thread retrieved successfully',
                data: messages
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                status: 500,
                message: 'Failed to retrieve message thread',
                errors: [{ message: error.message }]
            });
        }
    }

    /**
     * Marks a message as read with real-time status update
     * Requirement: 1.2 System Overview - Real-time messaging between users
     */
    @Put(':messageId/read')
    async markAsRead(req: Request, res: Response): Promise<Response> {
        try {
            const userId = req.user.id;
            const { messageId } = req.params;

            await this.messageService.markMessageAsRead(messageId, userId);

            return res.status(200).json({
                success: true,
                status: 200,
                message: 'Message marked as read successfully'
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                status: 500,
                message: 'Failed to mark message as read',
                errors: [{ message: error.message }]
            });
        }
    }

    /**
     * Soft deletes a message with participant notification
     * Requirement: 1.2 System Overview - Real-time messaging between users
     */
    @Delete(':messageId')
    async delete(req: Request, res: Response): Promise<Response> {
        try {
            const userId = req.user.id;
            const { messageId } = req.params;

            await this.messageService.deleteMessage(messageId, userId);

            return res.status(200).json({
                success: true,
                status: 200,
                message: 'Message deleted successfully'
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                status: 500,
                message: 'Failed to delete message',
                errors: [{ message: error.message }]
            });
        }
    }

    /**
     * Controller interface implementation
     */
    async findAll(req: Request, res: Response): Promise<Response> {
        try {
            const { page = 1, limit = 50, sortOrder = 'desc' } = req.query;
            const messages = await this.messageService.findAll({
                page: Number(page),
                limit: Number(limit),
                sortOrder: sortOrder as 'asc' | 'desc',
                filters: {}
            });

            return res.status(200).json({
                success: true,
                status: 200,
                message: 'Messages retrieved successfully',
                data: messages
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                status: 500,
                message: 'Failed to retrieve messages',
                errors: [{ message: error.message }]
            });
        }
    }

    async findById(req: Request, res: Response): Promise<Response> {
        try {
            const { id } = req.params;
            const message = await this.messageService.findById(id);

            if (!message) {
                return res.status(404).json({
                    success: false,
                    status: 404,
                    message: 'Message not found'
                });
            }

            return res.status(200).json({
                success: true,
                status: 200,
                message: 'Message retrieved successfully',
                data: message
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                status: 500,
                message: 'Failed to retrieve message',
                errors: [{ message: error.message }]
            });
        }
    }

    async update(req: Request, res: Response): Promise<Response> {
        try {
            const userId = req.user.id;
            const { id } = req.params;
            const updateData = req.body;

            const message = await this.messageService.update(id, updateData, userId);

            return res.status(200).json({
                success: true,
                status: 200,
                message: 'Message updated successfully',
                data: message
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                status: 500,
                message: 'Failed to update message',
                errors: [{ message: error.message }]
            });
        }
    }
}