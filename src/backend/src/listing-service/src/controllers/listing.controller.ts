// External dependencies
import { Request, Response } from 'express'; // v4.18.0
import { validate } from 'class-validator'; // v0.14.0

// Internal dependencies
import { Controller } from '../../../shared/interfaces/controller.interface';
import { ListingService } from '../services/listing.service';
import { ValidationError } from '../../../shared/utils/error';
import { IListing } from '../models/listing.model';

/**
 * Human Tasks:
 * 1. Configure rate limiting middleware for listing endpoints
 * 2. Set up request logging and monitoring for listing operations
 * 3. Configure caching strategy for frequently accessed listings
 * 4. Set up image upload middleware for listing images
 * 5. Configure geolocation validation middleware
 */

/**
 * Controller handling HTTP requests for furniture listing operations
 * Requirement: Core Features - Location-based furniture discovery
 * Requirement: API Architecture - REST/HTTP/2 API implementation with JWT authentication
 */
@Controller('/listings')
export class ListingController implements Controller<IListing> {
  private listingService: ListingService;

  constructor(listingService: ListingService) {
    this.listingService = listingService;

    // Bind methods to maintain this context
    this.create = this.create.bind(this);
    this.findAll = this.findAll.bind(this);
    this.findById = this.findById.bind(this);
    this.update = this.update.bind(this);
    this.delete = this.delete.bind(this);
    this.findNearby = this.findNearby.bind(this);
    this.markCollected = this.markCollected.bind(this);
    this.search = this.search.bind(this);
  }

  /**
   * Creates a new furniture listing
   * Requirement: Core Features - AI-powered furniture recognition and categorization
   */
  @Post('/')
  async create(req: Request, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        throw new ValidationError('User authentication required');
      }

      const listingData = req.body;
      const createdListing = await this.listingService.create(listingData, userId);

      return res.status(201).json({
        success: true,
        status: 201,
        message: 'Listing created successfully',
        data: createdListing
      });
    } catch (error) {
      if (error instanceof ValidationError) {
        return res.status(400).json({
          success: false,
          status: 400,
          message: error.message,
          errors: error.context.errors
        });
      }
      throw error;
    }
  }

  /**
   * Retrieves all listings with filtering and pagination
   * Requirement: Data Management Strategy - Time-based partitioning
   */
  @Get('/')
  async findAll(req: Request, res: Response): Promise<Response> {
    const { page, limit, sortBy, sortOrder, ...filters } = req.query;

    const options = {
      page: Number(page) || 1,
      limit: Number(limit) || 10,
      sortBy: String(sortBy) || 'createdAt',
      sortOrder: String(sortOrder) || 'desc',
      filters
    };

    const listings = await this.listingService.findAll(options);

    return res.status(200).json({
      success: true,
      status: 200,
      message: 'Listings retrieved successfully',
      data: listings
    });
  }

  /**
   * Retrieves a single listing by ID
   */
  @Get('/:id')
  async findById(req: Request, res: Response): Promise<Response> {
    const { id } = req.params;
    const listing = await this.listingService.findById(id);

    if (!listing) {
      return res.status(404).json({
        success: false,
        status: 404,
        message: 'Listing not found'
      });
    }

    return res.status(200).json({
      success: true,
      status: 200,
      message: 'Listing retrieved successfully',
      data: listing
    });
  }

  /**
   * Updates an existing listing
   */
  @Put('/:id')
  async update(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const userId = req.user?.id;
      if (!userId) {
        throw new ValidationError('User authentication required');
      }

      const updateData = req.body;
      const updatedListing = await this.listingService.update(id, updateData, userId);

      return res.status(200).json({
        success: true,
        status: 200,
        message: 'Listing updated successfully',
        data: updatedListing
      });
    } catch (error) {
      if (error instanceof ValidationError) {
        return res.status(400).json({
          success: false,
          status: 400,
          message: error.message,
          errors: error.context.errors
        });
      }
      throw error;
    }
  }

  /**
   * Soft deletes a listing
   * Requirement: Data Management Strategy - Time-based partitioning and data archival
   */
  @Delete('/:id')
  async delete(req: Request, res: Response): Promise<Response> {
    const { id } = req.params;
    const userId = req.user?.id;
    if (!userId) {
      throw new ValidationError('User authentication required');
    }

    await this.listingService.delete(id, userId);

    return res.status(200).json({
      success: true,
      status: 200,
      message: 'Listing deleted successfully',
      data: true
    });
  }

  /**
   * Finds listings near specified coordinates
   * Requirement: Core Features - Location-based furniture discovery
   */
  @Get('/nearby')
  async findNearby(req: Request, res: Response): Promise<Response> {
    try {
      const { latitude, longitude, radius, page, limit, sortBy, sortOrder } = req.query;

      if (!latitude || !longitude) {
        throw new ValidationError('Latitude and longitude are required');
      }

      const coordinates = {
        latitude: Number(latitude),
        longitude: Number(longitude)
      };

      const options = {
        page: Number(page) || 1,
        limit: Number(limit) || 10,
        sortBy: String(sortBy) || 'createdAt',
        sortOrder: String(sortOrder) || 'desc'
      };

      const listings = await this.listingService.findNearby(
        coordinates,
        Number(radius),
        options
      );

      return res.status(200).json({
        success: true,
        status: 200,
        message: 'Nearby listings retrieved successfully',
        data: listings
      });
    } catch (error) {
      if (error instanceof ValidationError) {
        return res.status(400).json({
          success: false,
          status: 400,
          message: error.message,
          errors: error.context.errors
        });
      }
      throw error;
    }
  }

  /**
   * Updates listing status to collected
   */
  @Put('/:id/collect')
  async markCollected(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const collectorId = req.user?.id;
      if (!collectorId) {
        throw new ValidationError('User authentication required');
      }

      const updatedListing = await this.listingService.markAsCollected(id, collectorId);

      return res.status(200).json({
        success: true,
        status: 200,
        message: 'Listing marked as collected successfully',
        data: updatedListing
      });
    } catch (error) {
      if (error instanceof ValidationError) {
        return res.status(400).json({
          success: false,
          status: 400,
          message: error.message,
          errors: error.context.errors
        });
      }
      throw error;
    }
  }

  /**
   * Searches listings by keywords and filters
   * Requirement: Core Features - AI-powered furniture recognition and categorization
   */
  @Get('/search')
  async search(req: Request, res: Response): Promise<Response> {
    const { q, page, limit, sortBy, sortOrder, ...filters } = req.query;

    if (!q) {
      throw new ValidationError('Search query is required');
    }

    const options = {
      page: Number(page) || 1,
      limit: Number(limit) || 10,
      sortBy: String(sortBy) || 'createdAt',
      sortOrder: String(sortOrder) || 'desc',
      filters
    };

    const listings = await this.listingService.searchListings(String(q), options);

    return res.status(200).json({
      success: true,
      status: 200,
      message: 'Search results retrieved successfully',
      data: listings
    });
  }
}