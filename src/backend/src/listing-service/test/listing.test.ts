// External dependencies
import mongoose from 'mongoose'; // v7.5.0
import { MongoMemoryServer } from 'mongodb-memory-server'; // v8.12.2
import { jest } from '@jest/globals'; // v29.0.0

// Internal dependencies
import { ListingService } from '../src/services/listing.service';
import { ListingModel } from '../src/models/listing.model';
import { ValidationError } from '../../../shared/utils/error';

/**
 * Human Tasks:
 * 1. Configure test environment variables for MongoDB connection
 * 2. Set up test data seeding scripts
 * 3. Configure test coverage reporting
 * 4. Set up CI/CD pipeline integration for automated testing
 */

let mongoServer: MongoMemoryServer;
let listingService: ListingService;

// Test data fixtures
const mockUserId = '507f1f77bcf86cd799439011';
const mockListingData = {
  title: 'Modern Sofa',
  description: 'Comfortable 3-seater sofa in excellent condition',
  images: ['https://example.com/sofa.jpg'],
  category: 'SOFA',
  condition: 'GOOD',
  location: {
    latitude: 1.3521,
    longitude: 103.8198,
    address: '123 Test Street'
  },
  dimensions: {
    length: 200,
    width: 85,
    height: 90
  },
  tags: ['modern', 'sofa', 'furniture']
};

const mockCoordinates = {
  latitude: 1.3521,
  longitude: 103.8198
};

// Setup test environment
beforeAll(async () => {
  // Requirement: Data Management Strategy - Testing data persistence
  mongoServer = await MongoMemoryServer.create();
  const mongoUri = mongoServer.getUri();
  
  await mongoose.connect(mongoUri);
  listingService = new ListingService(ListingModel);
});

// Cleanup test environment
afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

// Reset database state before each test
beforeEach(async () => {
  await mongoose.connection.dropDatabase();
});

describe('ListingService - Create Listing', () => {
  // Requirement: Core Features - AI-powered furniture recognition
  it('should create a new listing with valid data', async () => {
    const listing = await listingService.create(mockListingData, mockUserId);
    
    expect(listing).toBeDefined();
    expect(listing.title).toBe(mockListingData.title);
    expect(listing.createdBy).toBe(mockUserId);
    expect(listing.isActive).toBe(true);
    expect(listing.isDeleted).toBe(false);
  });

  // Requirement: API Architecture - Validation error handling
  it('should throw ValidationError for invalid listing data', async () => {
    const invalidData = {
      ...mockListingData,
      title: '', // Invalid: empty title
    };

    await expect(listingService.create(invalidData, mockUserId))
      .rejects
      .toThrow(ValidationError);
  });

  it('should validate required fields', async () => {
    const incompleteData = {
      title: 'Test Sofa'
    };

    await expect(listingService.create(incompleteData, mockUserId))
      .rejects
      .toThrow(ValidationError);
  });

  it('should validate location coordinates', async () => {
    const invalidLocation = {
      ...mockListingData,
      location: {
        latitude: 200, // Invalid latitude
        longitude: 103.8198,
        address: '123 Test Street'
      }
    };

    await expect(listingService.create(invalidLocation, mockUserId))
      .rejects
      .toThrow(ValidationError);
  });
});

describe('ListingService - Find Nearby', () => {
  // Requirement: Core Features - Location-based furniture discovery
  it('should find listings within specified radius', async () => {
    // Create test listings
    await listingService.create(mockListingData, mockUserId);
    await listingService.create({
      ...mockListingData,
      location: {
        latitude: 1.3522, // Nearby location
        longitude: 103.8199,
        address: '124 Test Street'
      }
    }, mockUserId);

    const nearbyListings = await listingService.findNearby(
      mockCoordinates,
      5000, // 5km radius
      { page: 1, limit: 10, filters: {}, sortBy: 'createdAt', sortOrder: 'desc' }
    );

    expect(nearbyListings).toHaveLength(2);
    expect(nearbyListings[0].location).toBeDefined();
  });

  it('should validate coordinates for nearby search', async () => {
    await expect(listingService.findNearby(
      { latitude: undefined, longitude: 103.8198 },
      5000,
      { page: 1, limit: 10, filters: {}, sortBy: 'createdAt', sortOrder: 'desc' }
    )).rejects.toThrow(ValidationError);
  });

  it('should handle empty results', async () => {
    const nearbyListings = await listingService.findNearby(
      mockCoordinates,
      5000,
      { page: 1, limit: 10, filters: {}, sortBy: 'createdAt', sortOrder: 'desc' }
    );

    expect(nearbyListings).toHaveLength(0);
  });
});

describe('ListingService - Mark As Collected', () => {
  let testListingId: string;

  beforeEach(async () => {
    const listing = await listingService.create(mockListingData, mockUserId);
    testListingId = listing.id;
  });

  it('should mark listing as collected', async () => {
    const collectorId = '507f1f77bcf86cd799439012';
    const updatedListing = await listingService.markAsCollected(testListingId, collectorId);

    expect(updatedListing.status).toBe('COLLECTED');
    expect(updatedListing.updatedBy).toBe(collectorId);
  });

  it('should throw error for non-existent listing', async () => {
    const nonExistentId = '507f1f77bcf86cd799439013';
    await expect(listingService.markAsCollected(nonExistentId, mockUserId))
      .rejects
      .toThrow('Failed to mark listing as collected');
  });
});

describe('ListingService - Search Listings', () => {
  beforeEach(async () => {
    // Create test listings
    await listingService.create(mockListingData, mockUserId);
    await listingService.create({
      ...mockListingData,
      title: 'Vintage Chair',
      category: 'CHAIR'
    }, mockUserId);
  });

  // Requirement: Core Features - AI-powered furniture categorization
  it('should search listings by keyword', async () => {
    const results = await listingService.searchListings(
      'sofa',
      { page: 1, limit: 10, filters: {}, sortBy: 'createdAt', sortOrder: 'desc' }
    );

    expect(results.length).toBeGreaterThan(0);
    expect(results[0].title).toContain('Sofa');
  });

  it('should filter search results by category', async () => {
    const results = await listingService.searchListings(
      'furniture',
      { 
        page: 1, 
        limit: 10, 
        filters: { category: 'CHAIR' }, 
        sortBy: 'createdAt', 
        sortOrder: 'desc' 
      }
    );

    expect(results.length).toBeGreaterThan(0);
    expect(results[0].category).toBe('CHAIR');
  });

  it('should handle pagination in search results', async () => {
    const results = await listingService.searchListings(
      'furniture',
      { page: 1, limit: 1, filters: {}, sortBy: 'createdAt', sortOrder: 'desc' }
    );

    expect(results).toHaveLength(1);
  });
});