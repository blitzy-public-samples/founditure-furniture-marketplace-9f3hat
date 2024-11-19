/**
 * Human Tasks:
 * 1. Ensure MongoDB is configured with proper geospatial indexes
 * 2. Set up Google Maps API key in environment variables
 * 3. Configure error monitoring for geocoding operations
 * 4. Verify MongoDB version supports $geoNear aggregation
 * 5. Set up proper logging for location operations
 */

// External dependencies
import { injectable } from 'inversify'; // v5.1.1
import { Model } from 'mongoose'; // v7.5.0
import { Point } from '@types/geojson'; // v7946.0.10

// Internal dependencies
import { Service, ValidationResult } from '../../../shared/interfaces/service.interface';
import { ILocation, ICoordinates } from '../models/location.model';
import { 
  geocodeAddress, 
  reverseGeocode, 
  validateAddress, 
  calculateDistance 
} from '../utils/geocoding.util';

/**
 * Service implementation for managing location data and geospatial operations
 * Requirement: Location-based Discovery - Implements precise geographic tracking
 * Requirement: Geographic Support - Validates locations in North America
 * Requirement: Data Storage Solutions - Implements geospatial capabilities
 */
@injectable()
export class LocationService implements Service<ILocation> {
  constructor(private locationModel: Model<ILocation>) {
    // Ensure geospatial index exists
    this.locationModel.collection.createIndex({ geoLocation: '2dsphere' });
  }

  /**
   * Creates a new location entry with validated address and coordinates
   * @param data Partial location data
   * @param userId User creating the location
   * @returns Created location document
   */
  async create(data: Partial<ILocation>, userId: string): Promise<ILocation> {
    // Validate location data
    const validationResult = await this.validateLocationData(data);
    if (!validationResult.isValid) {
      throw new Error(`Invalid location data: ${validationResult.errors.map(e => e.message).join(', ')}`);
    }

    try {
      // Geocode address if coordinates not provided
      if (!data.coordinates && data.address) {
        data.coordinates = await geocodeAddress(data.address);
      }

      // Create GeoJSON point
      const geoLocation: Point = {
        type: 'Point',
        coordinates: [data.coordinates!.longitude, data.coordinates!.latitude]
      };

      // Create location document
      const location = new this.locationModel({
        ...data,
        geoLocation,
        createdBy: userId,
        updatedBy: userId,
        isActive: true
      });

      return await location.save();
    } catch (error) {
      throw new Error(`Failed to create location: ${(error as Error).message}`);
    }
  }

  /**
   * Finds locations within specified radius of coordinates
   * Requirement: Location-based Discovery - Implements precise geographic tracking
   * @param coordinates Center point coordinates
   * @param radiusKm Search radius in kilometers
   * @returns Array of nearby locations
   */
  async findNearby(coordinates: ICoordinates, radiusKm: number): Promise<ILocation[]> {
    if (!coordinates || !radiusKm) {
      throw new Error('Coordinates and radius are required');
    }

    try {
      // Convert radius to meters for MongoDB
      const radiusMeters = radiusKm * 1000;

      // Execute geospatial query
      const locations = await this.locationModel.aggregate([
        {
          $geoNear: {
            near: {
              type: 'Point',
              coordinates: [coordinates.longitude, coordinates.latitude]
            },
            distanceField: 'distance',
            maxDistance: radiusMeters,
            spherical: true,
            query: { isActive: true }
          }
        }
      ]);

      return locations;
    } catch (error) {
      throw new Error(`Failed to find nearby locations: ${(error as Error).message}`);
    }
  }

  /**
   * Updates location data with new address or coordinates
   * @param id Location identifier
   * @param data Updated location data
   * @param userId User updating the location
   * @returns Updated location document
   */
  async updateLocation(id: string, data: Partial<ILocation>, userId: string): Promise<ILocation> {
    const location = await this.locationModel.findById(id);
    if (!location) {
      throw new Error('Location not found');
    }

    try {
      // Validate update data
      const validationResult = await this.validateLocationData(data);
      if (!validationResult.isValid) {
        throw new Error(`Invalid update data: ${validationResult.errors.map(e => e.message).join(', ')}`);
      }

      // Update coordinates if address changed
      if (data.address && data.address !== location.address) {
        data.coordinates = await geocodeAddress(data.address);
      }

      // Update GeoJSON point if coordinates changed
      if (data.coordinates) {
        data.geoLocation = {
          type: 'Point',
          coordinates: [data.coordinates.longitude, data.coordinates.latitude]
        };
      }

      // Update document
      Object.assign(location, {
        ...data,
        updatedBy: userId,
        updatedAt: new Date()
      });

      return await location.save();
    } catch (error) {
      throw new Error(`Failed to update location: ${(error as Error).message}`);
    }
  }

  /**
   * Validates location data including address and coordinates
   * Requirement: Geographic Support - Validates locations in North America
   * @param data Location data to validate
   * @returns Validation result with any errors
   */
  async validateLocationData(data: Partial<ILocation>): Promise<ValidationResult> {
    const errors = [];

    // Check required fields
    if (!data.address && !data.coordinates) {
      errors.push({
        field: 'address/coordinates',
        message: 'Either address or coordinates must be provided',
        code: 'REQUIRED_FIELD'
      });
    }

    // Validate address if provided
    if (data.address) {
      const isValidAddress = await validateAddress(data.address);
      if (!isValidAddress) {
        errors.push({
          field: 'address',
          message: 'Invalid address or outside supported region',
          code: 'INVALID_ADDRESS'
        });
      }
    }

    // Validate coordinates if provided
    if (data.coordinates) {
      const { latitude, longitude } = data.coordinates;
      if (
        typeof latitude !== 'number' || 
        typeof longitude !== 'number' ||
        latitude < -90 || 
        latitude > 90 || 
        longitude < -180 || 
        longitude > 180
      ) {
        errors.push({
          field: 'coordinates',
          message: 'Invalid coordinates',
          code: 'INVALID_COORDINATES'
        });
      }
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * Finds all locations with filtering
   * @param options Filter options
   * @returns Array of matching locations
   */
  async findAll(options: any): Promise<ILocation[]> {
    const query = { isActive: true, ...options.filters };
    return this.locationModel
      .find(query)
      .sort({ [options.sortBy]: options.sortOrder })
      .skip((options.page - 1) * options.limit)
      .limit(options.limit)
      .exec();
  }

  /**
   * Finds a single location by ID
   * @param id Location identifier
   * @returns Location document or null
   */
  async findById(id: string): Promise<ILocation | null> {
    return this.locationModel.findOne({ _id: id, isActive: true });
  }

  /**
   * Updates a location document
   * @param id Location identifier
   * @param data Updated data
   * @param userId User updating the location
   * @returns Updated location
   */
  async update(id: string, data: Partial<ILocation>, userId: string): Promise<ILocation> {
    return this.updateLocation(id, data, userId);
  }

  /**
   * Soft deletes a location
   * @param id Location identifier
   * @param userId User deleting the location
   * @returns Operation success
   */
  async delete(id: string, userId: string): Promise<boolean> {
    const result = await this.locationModel.updateOne(
      { _id: id },
      { 
        isActive: false,
        updatedBy: userId,
        updatedAt: new Date()
      }
    );
    return result.modifiedCount > 0;
  }

  /**
   * Validates location data
   * @param data Location data to validate
   * @returns Validation result
   */
  async validate(data: Partial<ILocation>): Promise<ValidationResult> {
    return this.validateLocationData(data);
  }
}