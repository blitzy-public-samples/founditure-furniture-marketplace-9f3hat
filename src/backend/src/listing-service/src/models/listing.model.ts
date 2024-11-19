// External dependencies
import { Schema, model, Document } from 'mongoose'; // v7.5.0
import { IsString, IsNotEmpty, MinLength, MaxLength, IsArray, ArrayMinSize, 
         IsEnum, IsMongoId, ValidateNested, IsNumber, Min, Max, IsDate } from 'class-validator'; // v0.14.0
import { Type } from 'class-transformer'; // v0.5.1

// Internal dependencies
import { BaseModel, SoftDeletable } from '../../../shared/interfaces/model.interface';

/**
 * Human Tasks:
 * 1. Configure MongoDB indexes for geospatial queries
 * 2. Set up AI service integration for recognition score calculation
 * 3. Configure image storage and CDN for listing images
 * 4. Set up data archival jobs for expired listings
 * 5. Configure monitoring for listing operations
 */

// Enums for listing properties
enum FurnitureCategory {
  CHAIR = 'CHAIR',
  TABLE = 'TABLE',
  SOFA = 'SOFA',
  BED = 'BED',
  STORAGE = 'STORAGE',
  DESK = 'DESK',
  OTHER = 'OTHER'
}

enum FurnitureCondition {
  NEW = 'NEW',
  LIKE_NEW = 'LIKE_NEW',
  GOOD = 'GOOD',
  FAIR = 'FAIR',
  POOR = 'POOR'
}

enum ListingStatus {
  AVAILABLE = 'AVAILABLE',
  PENDING = 'PENDING',
  COLLECTED = 'COLLECTED',
  EXPIRED = 'EXPIRED',
  INACTIVE = 'INACTIVE'
}

// Nested schemas
class LocationSchema {
  @IsNumber()
  latitude: number;

  @IsNumber()
  longitude: number;

  @IsString()
  address: string;
}

class DimensionsSchema {
  @IsNumber()
  @Min(0)
  length: number;

  @IsNumber()
  @Min(0)
  width: number;

  @IsNumber()
  @Min(0)
  height: number;
}

// Main listing interface
export interface IListing extends BaseModel, SoftDeletable {
  title: string;
  description: string;
  images: string[];
  category: FurnitureCategory;
  condition: FurnitureCondition;
  status: ListingStatus;
  userId: string;
  location: LocationSchema;
  dimensions: DimensionsSchema;
  tags: string[];
  recognitionScore: number;
  availableUntil: Date;
}

/**
 * Listing Model Implementation
 * Requirement: Core Features - AI-powered furniture recognition and categorization
 * Requirement: Data Storage Solutions - Document storage for flexible furniture listing data
 * Requirement: Data Management Strategy - Time-based partitioning and data archival requirements
 */
@Schema({ 
  timestamps: true, 
  collection: 'listings',
  index: { 
    'location': '2dsphere',
    'availableUntil': 1,
    'status': 1,
    'isDeleted': 1
  }
})
export class ListingModel implements IListing {
  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  @MaxLength(100)
  title: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  description: string;

  @IsArray()
  @ArrayMinSize(1)
  images: string[];

  @IsEnum(FurnitureCategory)
  category: FurnitureCategory;

  @IsEnum(FurnitureCondition)
  condition: FurnitureCondition;

  @IsEnum(ListingStatus)
  status: ListingStatus;

  @IsMongoId()
  userId: string;

  @ValidateNested()
  @Type(() => LocationSchema)
  location: LocationSchema;

  @ValidateNested()
  @Type(() => DimensionsSchema)
  dimensions: DimensionsSchema;

  tags: string[];

  @IsNumber()
  @Min(0)
  @Max(1)
  recognitionScore: number;

  @IsDate()
  availableUntil: Date;

  // Base model properties
  id: string;
  createdAt: Date;
  updatedAt: Date;
  isActive: boolean;
  createdBy: string;
  updatedBy: string;

  // Soft delete properties
  isDeleted: boolean;
  deletedAt: Date;
  deletedBy: string;

  constructor(listingData: Partial<IListing>) {
    Object.assign(this, listingData);
    this.isActive = true;
    this.isDeleted = false;
    this.status = ListingStatus.AVAILABLE;
    
    // Generate tags using AI categorization from title and description
    this.tags = this.generateTags();
    
    // Set default expiration if not provided
    if (!this.availableUntil) {
      this.availableUntil = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days from now
    }
  }

  private generateTags(): string[] {
    // TODO: Implement AI-based tag generation
    const basicTags = [this.category.toLowerCase()];
    if (this.title) {
      basicTags.push(...this.title.toLowerCase().split(' '));
    }
    return [...new Set(basicTags)];
  }

  /**
   * Finds listings within specified radius of coordinates
   * Requirement: Core Features - Location-based furniture discovery
   */
  async findNearby(coordinates: { latitude: number; longitude: number }, radius: number): Promise<IListing[]> {
    const model = model<IListing>('Listing');
    return model.find({
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [coordinates.longitude, coordinates.latitude]
          },
          $maxDistance: radius * 1000 // Convert km to meters
        }
      },
      isDeleted: false,
      isActive: true,
      status: ListingStatus.AVAILABLE,
      availableUntil: { $gt: new Date() }
    }).exec();
  }

  /**
   * Updates listing status to collected
   */
  async markAsCollected(listingId: string, collectorId: string): Promise<IListing> {
    const model = model<IListing>('Listing');
    const listing = await model.findOne({
      _id: listingId,
      isDeleted: false,
      status: ListingStatus.AVAILABLE
    });

    if (!listing) {
      throw new Error('Listing not found or not available');
    }

    listing.status = ListingStatus.COLLECTED;
    listing.updatedBy = collectorId;
    return listing.save();
  }

  /**
   * Marks listing as deleted without removing from database
   * Requirement: Data Management Strategy - Time-based partitioning and data archival requirements
   */
  async softDelete(listingId: string, deletedBy: string): Promise<void> {
    const model = model<IListing>('Listing');
    await model.findByIdAndUpdate(listingId, {
      isDeleted: true,
      deletedAt: new Date(),
      deletedBy: deletedBy,
      isActive: false,
      status: ListingStatus.INACTIVE
    });
  }
}

// Create and export the Mongoose model
export default model<IListing>('Listing', ListingModel.schema);