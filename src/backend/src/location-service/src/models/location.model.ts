/**
 * Human Tasks:
 * 1. Ensure MongoDB is configured with geospatial indexing enabled
 * 2. Verify GeoJSON compatibility in MongoDB version
 * 3. Set up proper validation for coordinate bounds in production environment
 * 4. Configure proper index optimization for geospatial queries
 */

// External dependencies
import { Schema, model, Model } from 'mongoose'; // v7.5.0
import { Point } from '@types/geojson'; // v7946.0.10

// Internal dependencies
import { BaseModel } from '../../../shared/interfaces/model.interface';

/**
 * Interface defining geographic coordinates
 * Requirement: Location-based Discovery - Implements precise geographic tracking
 */
export interface ICoordinates {
  latitude: number;
  longitude: number;
}

/**
 * Interface for location data with full address and geospatial information
 * Requirement: Location-based Discovery - Implements precise geographic tracking
 * Requirement: Data Storage Solutions - Structured data storage with geospatial capabilities
 */
export interface ILocation extends BaseModel {
  coordinates: ICoordinates;
  address: string;
  city: string;
  state: string;
  country: string;
  postalCode: string;
  geoLocation: Point;
  listingId: string;
  isActive: boolean;
  createdBy: string;
  updatedBy: string;
}

/**
 * Mongoose schema for location data with geospatial indexing
 * Requirement: Data Storage Solutions - Implements geospatial capabilities
 */
@Schema({ timestamps: true })
class LocationSchema {
  coordinates: {
    latitude: {
      type: Number,
      required: true,
      min: -90,
      max: 90,
    },
    longitude: {
      type: Number,
      required: true,
      min: -180,
      max: 180,
    },
  };

  @Schema({ required: true })
  address: string;

  @Schema({ required: true })
  city: string;

  @Schema({ required: true })
  state: string;

  @Schema({ required: true })
  country: string;

  @Schema({ required: true })
  postalCode: string;

  geoLocation: {
    type: {
      type: String,
      enum: ['Point'],
      required: true,
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      required: true,
      index: '2dsphere', // Enables geospatial queries
    },
  };

  @Schema({ required: true })
  listingId: Schema.Types.ObjectId;

  @Schema({ default: true })
  isActive: boolean;

  @Schema({ required: true })
  createdBy: string;

  @Schema({ required: true })
  updatedBy: string;

  @Schema({ type: Date })
  createdAt: Date;

  @Schema({ type: Date })
  updatedAt: Date;

  /**
   * Creates a GeoJSON Point object from coordinates
   * Requirement: Location-based Discovery - Enables precise geographic tracking
   * @param coordinates - The latitude and longitude coordinates
   * @returns GeoJSON Point object
   */
  static createGeoLocation(coordinates: ICoordinates): Point {
    // Validate coordinate bounds
    if (
      coordinates.latitude < -90 || 
      coordinates.latitude > 90 ||
      coordinates.longitude < -180 || 
      coordinates.longitude > 180
    ) {
      throw new Error('Invalid coordinates: Latitude must be between -90 and 90, Longitude must be between -180 and 180');
    }

    // Create GeoJSON Point object
    return {
      type: 'Point',
      coordinates: [coordinates.longitude, coordinates.latitude], // GeoJSON format: [longitude, latitude]
    };
  }
}

// Create indexes for optimized querying
LocationSchema.index({ geoLocation: '2dsphere' });
LocationSchema.index({ listingId: 1 });
LocationSchema.index({ city: 1, state: 1, country: 1 });

// Create and export the Mongoose model
const LocationModel: Model<ILocation> = model<ILocation>('Location', new Schema(LocationSchema));

export default LocationModel;