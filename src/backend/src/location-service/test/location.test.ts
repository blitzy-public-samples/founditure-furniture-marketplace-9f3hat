/**
 * Human Tasks:
 * 1. Ensure MongoDB test instance is properly configured with geospatial indexes
 * 2. Set up test environment variables including Google Maps API key
 * 3. Configure test data cleanup between test runs
 * 4. Verify test coverage requirements are met
 * 5. Set up CI pipeline to run tests in isolated environment
 */

// External dependencies
import { jest } from '@jest/globals'; // v29.0.0
import mongoose from 'mongoose'; // v7.5.0

// Internal dependencies
import { LocationService } from '../src/services/location.service';
import { ILocation, ICoordinates } from '../src/models/location.model';
import { geocodeAddress } from '../src/utils/geocoding.util';

// Mock MongoDB model
const mockLocationModel = {
  collection: {
    createIndex: jest.fn(),
  },
  find: jest.fn(),
  findById: jest.fn(),
  findOne: jest.fn(),
  aggregate: jest.fn(),
  save: jest.fn(),
  updateOne: jest.fn(),
};

// Mock geocoding function
jest.mock('../src/utils/geocoding.util', () => ({
  geocodeAddress: jest.fn(),
}));

describe('LocationService', () => {
  let locationService: LocationService;
  let testLocation: Partial<ILocation>;
  let testCoordinates: ICoordinates;

  beforeAll(async () => {
    // Requirement: Location-based Discovery - Set up test environment for geographic tracking
    await mongoose.connect(process.env.MONGODB_TEST_URI || 'mongodb://localhost:27017/test');
    
    // Create geospatial indexes
    await mongoose.connection.collection('locations').createIndex({ geoLocation: '2dsphere' });
  });

  afterAll(async () => {
    // Clean up test database
    await mongoose.connection.dropDatabase();
    await mongoose.connection.close();
  });

  beforeEach(() => {
    // Initialize service with mock model
    locationService = new LocationService(mockLocationModel as any);

    // Reset all mocks
    jest.clearAllMocks();

    // Initialize test data
    testCoordinates = {
      latitude: 40.7128,
      longitude: -74.0060
    };

    testLocation = {
      address: '123 Test St',
      city: 'New York',
      state: 'NY',
      country: 'US',
      postalCode: '10001',
      coordinates: testCoordinates,
      isActive: true,
      createdBy: 'test-user',
      updatedBy: 'test-user'
    };
  });

  it('should create a new location', async () => {
    // Requirement: Location-based Discovery - Test precise geographic tracking
    const mockGeocodedCoords = {
      latitude: 40.7128,
      longitude: -74.0060
    };

    (geocodeAddress as jest.Mock).mockResolvedValue(mockGeocodedCoords);

    const mockSavedLocation = {
      ...testLocation,
      id: 'test-id',
      geoLocation: {
        type: 'Point',
        coordinates: [mockGeocodedCoords.longitude, mockGeocodedCoords.latitude]
      }
    };

    mockLocationModel.save.mockResolvedValue(mockSavedLocation);

    const result = await locationService.create(testLocation, 'test-user');

    expect(geocodeAddress).toHaveBeenCalledWith(testLocation.address);
    expect(result).toEqual(mockSavedLocation);
    expect(result.geoLocation.type).toBe('Point');
    expect(result.geoLocation.coordinates).toEqual([
      mockGeocodedCoords.longitude,
      mockGeocodedCoords.latitude
    ]);
  });

  it('should find nearby locations', async () => {
    // Requirement: Location-based Discovery - Test location-based search functionality
    const searchRadius = 5; // kilometers
    const mockNearbyLocations = [
      {
        ...testLocation,
        distance: 1.5,
        geoLocation: {
          type: 'Point',
          coordinates: [-74.0060, 40.7128]
        }
      }
    ];

    mockLocationModel.aggregate.mockResolvedValue(mockNearbyLocations);

    const result = await locationService.findNearby(testCoordinates, searchRadius);

    expect(mockLocationModel.aggregate).toHaveBeenCalledWith([
      {
        $geoNear: {
          near: {
            type: 'Point',
            coordinates: [testCoordinates.longitude, testCoordinates.latitude]
          },
          distanceField: 'distance',
          maxDistance: searchRadius * 1000,
          spherical: true,
          query: { isActive: true }
        }
      }
    ]);

    expect(result).toEqual(mockNearbyLocations);
  });

  it('should update location data', async () => {
    // Requirement: Location-based Discovery - Test location data updates
    const updateData = {
      address: '456 Update St',
      city: 'Brooklyn',
      state: 'NY'
    };

    const mockUpdatedCoords = {
      latitude: 40.6782,
      longitude: -73.9442
    };

    const mockExistingLocation = {
      ...testLocation,
      id: 'test-id',
      save: jest.fn()
    };

    (geocodeAddress as jest.Mock).mockResolvedValue(mockUpdatedCoords);
    mockLocationModel.findById.mockResolvedValue(mockExistingLocation);
    mockExistingLocation.save.mockResolvedValue({
      ...mockExistingLocation,
      ...updateData,
      coordinates: mockUpdatedCoords,
      geoLocation: {
        type: 'Point',
        coordinates: [mockUpdatedCoords.longitude, mockUpdatedCoords.latitude]
      }
    });

    const result = await locationService.updateLocation('test-id', updateData, 'test-user');

    expect(geocodeAddress).toHaveBeenCalledWith(updateData.address);
    expect(result.coordinates).toEqual(mockUpdatedCoords);
    expect(result.geoLocation.coordinates).toEqual([
      mockUpdatedCoords.longitude,
      mockUpdatedCoords.latitude
    ]);
  });

  it('should validate location data', async () => {
    // Requirement: Geographic Support - Test location validation for North America
    const validationResults = await locationService.validateLocationData(testLocation);

    expect(validationResults.isValid).toBe(true);
    expect(validationResults.errors).toHaveLength(0);

    // Test invalid coordinates
    const invalidLocation = {
      ...testLocation,
      coordinates: {
        latitude: 91, // Invalid latitude
        longitude: -74.0060
      }
    };

    const invalidResults = await locationService.validateLocationData(invalidLocation);

    expect(invalidResults.isValid).toBe(false);
    expect(invalidResults.errors).toContainEqual({
      field: 'coordinates',
      message: 'Invalid coordinates',
      code: 'INVALID_COORDINATES'
    });
  });

  it('should reject locations without required data', async () => {
    const incompleteLocation = {
      city: 'New York',
      state: 'NY'
    };

    const validationResults = await locationService.validateLocationData(incompleteLocation);

    expect(validationResults.isValid).toBe(false);
    expect(validationResults.errors).toContainEqual({
      field: 'address/coordinates',
      message: 'Either address or coordinates must be provided',
      code: 'REQUIRED_FIELD'
    });
  });

  it('should handle geocoding failures gracefully', async () => {
    (geocodeAddress as jest.Mock).mockRejectedValue(new Error('Geocoding failed'));

    await expect(locationService.create(testLocation, 'test-user'))
      .rejects
      .toThrow('Failed to create location: Geocoding failed');
  });

  it('should reject invalid search parameters', async () => {
    await expect(locationService.findNearby(null as any, 5))
      .rejects
      .toThrow('Coordinates and radius are required');

    await expect(locationService.findNearby(testCoordinates, 0))
      .rejects
      .toThrow('Coordinates and radius are required');
  });

  it('should handle non-existent locations for updates', async () => {
    mockLocationModel.findById.mockResolvedValue(null);

    await expect(locationService.updateLocation('non-existent-id', testLocation, 'test-user'))
      .rejects
      .toThrow('Location not found');
  });
});