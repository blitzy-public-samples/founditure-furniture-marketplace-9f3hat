/**
 * Human Tasks:
 * 1. Configure authentication middleware for protected endpoints
 * 2. Set up request validation middleware for coordinate bounds
 * 3. Configure rate limiting for location-based queries
 * 4. Set up monitoring for geospatial query performance
 * 5. Verify error handling middleware is properly configured
 */

// External dependencies
import { Request, Response } from 'express'; // v4.18.0
import { injectable, inject } from 'inversify'; // v6.0.0

// Internal dependencies
import { Controller } from '../../../shared/interfaces/controller.interface';
import { LocationService } from '../services/location.service';
import { ILocation } from '../models/location.model';

/**
 * REST controller for location-based operations
 * Requirement: Location-based Discovery - Implements precise geographic tracking
 * Requirement: Geographic Support - Major urban centers in North America
 * Requirement: API Architecture - REST endpoints with standardized handling
 */
@injectable()
export class LocationController implements Controller<ILocation> {
  constructor(
    @inject(LocationService) private locationService: LocationService
  ) {}

  /**
   * Creates a new location entry with validation
   * Requirement: API Architecture - Standardized request/response handling
   * @param req Express request containing location data
   * @param res Express response
   */
  async create(req: Request, res: Response): Promise<Response> {
    try {
      const locationData = req.body;
      const userId = req.user?.id;

      // Validate location data
      const validationResult = await this.locationService.validateLocationData(locationData);
      if (!validationResult.isValid) {
        return res.status(400).json({
          success: false,
          status: 400,
          message: 'Invalid location data',
          errors: validationResult.errors
        });
      }

      // Create location
      const location = await this.locationService.create(locationData, userId);

      return res.status(201).json({
        success: true,
        status: 201,
        message: 'Location created successfully',
        data: location
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        status: 500,
        message: `Failed to create location: ${(error as Error).message}`
      });
    }
  }

  /**
   * Finds locations within specified radius of coordinates
   * Requirement: Location-based Discovery - Location-based furniture discovery
   * @param req Express request with coordinates and radius
   * @param res Express response
   */
  async findNearby(req: Request, res: Response): Promise<Response> {
    try {
      const { latitude, longitude, radius } = req.query;

      // Validate required parameters
      if (!latitude || !longitude || !radius) {
        return res.status(400).json({
          success: false,
          status: 400,
          message: 'Latitude, longitude and radius are required'
        });
      }

      // Parse and validate coordinates
      const coordinates = {
        latitude: parseFloat(latitude as string),
        longitude: parseFloat(longitude as string)
      };

      const radiusKm = parseFloat(radius as string);

      // Find nearby locations
      const locations = await this.locationService.findNearby(coordinates, radiusKm);

      return res.status(200).json({
        success: true,
        status: 200,
        message: 'Nearby locations retrieved successfully',
        data: locations
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        status: 500,
        message: `Failed to find nearby locations: ${(error as Error).message}`
      });
    }
  }

  /**
   * Updates an existing location
   * Requirement: API Architecture - Standardized request/response handling
   * @param req Express request with location ID and update data
   * @param res Express response
   */
  async update(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const updateData = req.body;
      const userId = req.user?.id;

      // Validate update data
      const validationResult = await this.locationService.validateLocationData(updateData);
      if (!validationResult.isValid) {
        return res.status(400).json({
          success: false,
          status: 400,
          message: 'Invalid update data',
          errors: validationResult.errors
        });
      }

      // Update location
      const updatedLocation = await this.locationService.updateLocation(id, updateData, userId);

      return res.status(200).json({
        success: true,
        status: 200,
        message: 'Location updated successfully',
        data: updatedLocation
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        status: 500,
        message: `Failed to update location: ${(error as Error).message}`
      });
    }
  }

  /**
   * Retrieves location by ID
   * Requirement: API Architecture - Standardized request/response handling
   * @param req Express request with location ID
   * @param res Express response
   */
  async findById(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const location = await this.locationService.findById(id);

      if (!location) {
        return res.status(404).json({
          success: false,
          status: 404,
          message: 'Location not found'
        });
      }

      return res.status(200).json({
        success: true,
        status: 200,
        message: 'Location retrieved successfully',
        data: location
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        status: 500,
        message: `Failed to retrieve location: ${(error as Error).message}`
      });
    }
  }

  /**
   * Retrieves all locations with filtering
   * Requirement: API Architecture - Standardized request/response handling
   * @param req Express request with filter options
   * @param res Express response
   */
  async findAll(req: Request, res: Response): Promise<Response> {
    try {
      const { page = 1, limit = 10, sortBy = 'createdAt', sortOrder = 'desc', ...filters } = req.query;

      const options = {
        page: parseInt(page as string),
        limit: parseInt(limit as string),
        sortBy,
        sortOrder,
        filters
      };

      const locations = await this.locationService.findAll(options);

      return res.status(200).json({
        success: true,
        status: 200,
        message: 'Locations retrieved successfully',
        data: locations
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        status: 500,
        message: `Failed to retrieve locations: ${(error as Error).message}`
      });
    }
  }

  /**
   * Soft deletes a location
   * Requirement: API Architecture - Standardized request/response handling
   * @param req Express request with location ID
   * @param res Express response
   */
  async delete(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const userId = req.user?.id;

      const isDeleted = await this.locationService.delete(id, userId);

      if (!isDeleted) {
        return res.status(404).json({
          success: false,
          status: 404,
          message: 'Location not found'
        });
      }

      return res.status(200).json({
        success: true,
        status: 200,
        message: 'Location deleted successfully',
        data: true
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        status: 500,
        message: `Failed to delete location: ${(error as Error).message}`
      });
    }
  }
}