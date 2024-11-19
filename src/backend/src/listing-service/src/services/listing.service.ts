// External dependencies
import mongoose from 'mongoose'; // v7.5.0
import { validate } from 'class-validator'; // v0.14.0

// Internal dependencies
import { ListingModel, findNearby, markAsCollected, softDelete } from '../models/listing.model';
import { Service, FilterOptions, ValidationResult } from '../../../shared/interfaces/service.interface';
import { ValidationError } from '../../../shared/utils/error';
import { validateModel } from '../../../shared/utils/validation';

/**
 * Human Tasks:
 * 1. Configure MongoDB geospatial indexes for location-based queries
 * 2. Set up monitoring for listing operations performance
 * 3. Configure data archival jobs for expired listings
 * 4. Set up AI service integration for furniture recognition
 * 5. Configure image storage and CDN settings
 */

/**
 * Service class implementing furniture listing business logic
 * Requirement: Core Features - Location-based furniture discovery
 * Requirement: Data Management Strategy - Time-based partitioning and data archival
 * Requirement: API Architecture - REST/HTTP/2 API implementation with validation
 */
export class ListingService implements Service<ListingModel> {
  private listingModel: typeof ListingModel;
  private readonly defaultRadius: number = 5000; // Default search radius in meters

  constructor(listingModel: typeof ListingModel) {
    this.listingModel = listingModel;
    this.defaultRadius = 5000;

    // Bind methods to maintain this context
    this.create = this.create.bind(this);
    this.findAll = this.findAll.bind(this);
    this.findById = this.findById.bind(this);
    this.update = this.update.bind(this);
    this.delete = this.delete.bind(this);
    this.validate = this.validate.bind(this);
    this.findNearby = this.findNearby.bind(this);
    this.markAsCollected = this.markAsCollected.bind(this);
    this.searchListings = this.searchListings.bind(this);
  }

  /**
   * Creates a new furniture listing
   * Requirement: Core Features - AI-powered furniture recognition and categorization
   */
  async create(listingData: Partial<ListingModel>, userId: string): Promise<ListingModel> {
    try {
      // Validate listing data
      const validationResult = await this.validate(listingData);
      if (!validationResult.isValid) {
        throw new ValidationError('Invalid listing data', { errors: validationResult.errors });
      }

      // Create new listing instance
      const listing = new this.listingModel({
        ...listingData,
        createdBy: userId,
        updatedBy: userId,
        isActive: true,
        isDeleted: false
      });

      // Save to database
      const savedListing = await listing.save();
      return savedListing;
    } catch (error) {
      if (error instanceof ValidationError) {
        throw error;
      }
      throw new Error(`Failed to create listing: ${error.message}`);
    }
  }

  /**
   * Retrieves all active listings with filtering and pagination
   * Requirement: Data Management Strategy - Time-based partitioning
   */
  async findAll(options: FilterOptions): Promise<ListingModel[]> {
    const { page = 1, limit = 10, filters = {}, sortBy = 'createdAt', sortOrder = 'desc' } = options;
    
    const query = {
      isDeleted: false,
      isActive: true,
      ...filters
    };

    const sort = { [sortBy]: sortOrder };
    const skip = (page - 1) * limit;

    try {
      const listings = await this.listingModel
        .find(query)
        .sort(sort)
        .skip(skip)
        .limit(limit)
        .exec();

      return listings;
    } catch (error) {
      throw new Error(`Failed to fetch listings: ${error.message}`);
    }
  }

  /**
   * Retrieves a single listing by ID
   */
  async findById(id: string): Promise<ListingModel | null> {
    try {
      const listing = await this.listingModel
        .findOne({
          _id: id,
          isDeleted: false,
          isActive: true
        })
        .exec();

      return listing;
    } catch (error) {
      throw new Error(`Failed to fetch listing: ${error.message}`);
    }
  }

  /**
   * Updates an existing listing
   */
  async update(id: string, data: Partial<ListingModel>, userId: string): Promise<ListingModel> {
    try {
      // Validate update data
      const validationResult = await this.validate(data);
      if (!validationResult.isValid) {
        throw new ValidationError('Invalid update data', { errors: validationResult.errors });
      }

      const listing = await this.listingModel.findOneAndUpdate(
        {
          _id: id,
          isDeleted: false,
          isActive: true
        },
        {
          ...data,
          updatedBy: userId,
          updatedAt: new Date()
        },
        { new: true }
      ).exec();

      if (!listing) {
        throw new Error('Listing not found or not available');
      }

      return listing;
    } catch (error) {
      if (error instanceof ValidationError) {
        throw error;
      }
      throw new Error(`Failed to update listing: ${error.message}`);
    }
  }

  /**
   * Soft deletes a listing
   * Requirement: Data Management Strategy - Time-based partitioning and data archival
   */
  async delete(id: string, userId: string): Promise<boolean> {
    try {
      const result = await softDelete(id, userId);
      return true;
    } catch (error) {
      throw new Error(`Failed to delete listing: ${error.message}`);
    }
  }

  /**
   * Validates listing data against business rules
   */
  async validate(data: Partial<ListingModel>): Promise<ValidationResult> {
    try {
      const listing = new this.listingModel(data);
      const validationResult = await validateModel(listing);
      return validationResult;
    } catch (error) {
      throw new ValidationError('Validation failed', { error });
    }
  }

  /**
   * Finds listings near specified coordinates
   * Requirement: Core Features - Location-based furniture discovery
   */
  async findNearby(
    coordinates: { latitude: number; longitude: number },
    radius: number = this.defaultRadius,
    options: FilterOptions
  ): Promise<ListingModel[]> {
    try {
      // Validate coordinates
      if (!coordinates.latitude || !coordinates.longitude) {
        throw new ValidationError('Invalid coordinates');
      }

      // Apply filters and execute geospatial query
      const listings = await findNearby(coordinates, radius);
      
      // Apply additional filters and pagination
      const { page = 1, limit = 10, sortBy = 'createdAt', sortOrder = 'desc' } = options;
      const skip = (page - 1) * limit;

      return listings
        .sort((a, b) => {
          if (sortOrder === 'desc') {
            return b[sortBy] - a[sortBy];
          }
          return a[sortBy] - b[sortBy];
        })
        .slice(skip, skip + limit);
    } catch (error) {
      throw new Error(`Failed to find nearby listings: ${error.message}`);
    }
  }

  /**
   * Updates listing status to collected
   */
  async markAsCollected(listingId: string, collectorId: string): Promise<ListingModel> {
    try {
      const listing = await markAsCollected(listingId, collectorId);
      return listing;
    } catch (error) {
      throw new Error(`Failed to mark listing as collected: ${error.message}`);
    }
  }

  /**
   * Searches listings by keywords and filters
   * Requirement: Core Features - AI-powered furniture recognition and categorization
   */
  async searchListings(query: string, options: FilterOptions): Promise<ListingModel[]> {
    try {
      const { page = 1, limit = 10, filters = {}, sortBy = 'createdAt', sortOrder = 'desc' } = options;
      
      // Build search criteria
      const searchCriteria = {
        $text: { $search: query },
        isDeleted: false,
        isActive: true,
        ...filters
      };

      const sort = { [sortBy]: sortOrder };
      const skip = (page - 1) * limit;

      const listings = await this.listingModel
        .find(searchCriteria)
        .sort(sort)
        .skip(skip)
        .limit(limit)
        .exec();

      return listings;
    } catch (error) {
      throw new Error(`Failed to search listings: ${error.message}`);
    }
  }
}