/**
 * Human Tasks:
 * 1. Set up Google Maps API credentials in environment configuration
 * 2. Configure API usage limits and monitoring
 * 3. Set up error tracking for geocoding API failures
 * 4. Verify regional coverage matches supported areas in North America
 * 5. Implement caching strategy for frequently geocoded addresses
 */

// External dependencies
import { Client, GeocodeResult } from '@googlemaps/google-maps-services-js'; // v3.3.41
import { Point } from '@types/geojson'; // v7946.0.10

// Internal dependencies
import { ILocation, ICoordinates } from '../models/location.model';

// Initialize Google Maps client
const googleMapsClient = new Client({});

/**
 * Converts a text address into geographic coordinates
 * Requirement: Location-based Discovery - Implements precise geographic tracking
 * @param address - The address string to geocode
 * @returns Promise resolving to coordinates
 * @throws Error if geocoding fails or address is invalid
 */
export async function geocodeAddress(address: string): Promise<ICoordinates> {
  if (!address?.trim()) {
    throw new Error('Address cannot be empty');
  }

  try {
    const response = await googleMapsClient.geocode({
      params: {
        address,
        key: process.env.GOOGLE_MAPS_API_KEY!,
        region: 'na', // North America region bias
      },
    });

    if (!response.data.results?.length) {
      throw new Error('No results found for the provided address');
    }

    const location = response.data.results[0].geometry.location;
    return {
      latitude: location.lat,
      longitude: location.lng,
    };
  } catch (error) {
    throw new Error(`Geocoding failed: ${(error as Error).message}`);
  }
}

/**
 * Converts geographic coordinates into a formatted address
 * Requirement: Location-based Discovery - Implements precise geographic tracking
 * Requirement: Geographic Support - Validates locations in North America
 * @param coordinates - The coordinates to reverse geocode
 * @returns Promise resolving to complete location data
 * @throws Error if reverse geocoding fails or coordinates are invalid
 */
export async function reverseGeocode(coordinates: ICoordinates): Promise<ILocation> {
  if (!isValidCoordinates(coordinates)) {
    throw new Error('Invalid coordinates provided');
  }

  try {
    const response = await googleMapsClient.reverseGeocode({
      params: {
        latlng: { lat: coordinates.latitude, lng: coordinates.longitude },
        key: process.env.GOOGLE_MAPS_API_KEY!,
        result_type: ['street_address'],
      },
    });

    if (!response.data.results?.length) {
      throw new Error('No address found for the provided coordinates');
    }

    const result = response.data.results[0];
    const addressComponents = result.address_components;

    const location: Partial<ILocation> = {
      coordinates,
      address: result.formatted_address,
      city: getAddressComponent(addressComponents, 'locality'),
      state: getAddressComponent(addressComponents, 'administrative_area_level_1'),
      country: getAddressComponent(addressComponents, 'country'),
      postalCode: getAddressComponent(addressComponents, 'postal_code'),
    };

    return location as ILocation;
  } catch (error) {
    throw new Error(`Reverse geocoding failed: ${(error as Error).message}`);
  }
}

/**
 * Validates and normalizes an address
 * Requirement: Geographic Support - Validates locations in North America
 * @param address - The address string to validate
 * @returns Promise resolving to address validity status
 */
export async function validateAddress(address: string): Promise<boolean> {
  if (!address?.trim()) {
    return false;
  }

  try {
    const response = await googleMapsClient.geocode({
      params: {
        address,
        key: process.env.GOOGLE_MAPS_API_KEY!,
        region: 'na',
      },
    });

    if (!response.data.results?.length) {
      return false;
    }

    const result = response.data.results[0];
    const country = result.address_components.find(
      component => component.types.includes('country')
    )?.short_name;

    // Verify address is in North America
    return ['US', 'CA'].includes(country || '');
  } catch (error) {
    return false;
  }
}

/**
 * Calculates the great-circle distance between two points using Haversine formula
 * Requirement: Location-based Discovery - Implements precise geographic tracking
 * @param point1 - First coordinate point
 * @param point2 - Second coordinate point
 * @returns Distance in kilometers
 * @throws Error if coordinates are invalid
 */
export function calculateDistance(point1: ICoordinates, point2: ICoordinates): number {
  if (!isValidCoordinates(point1) || !isValidCoordinates(point2)) {
    throw new Error('Invalid coordinates provided');
  }

  const R = 6371; // Earth's radius in kilometers
  const dLat = toRadians(point2.latitude - point1.latitude);
  const dLon = toRadians(point2.longitude - point1.longitude);

  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(point1.latitude)) * 
    Math.cos(toRadians(point2.latitude)) * 
    Math.sin(dLon / 2) * Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Helper function to validate coordinate bounds
 * @param coordinates - The coordinates to validate
 * @returns Boolean indicating if coordinates are valid
 */
function isValidCoordinates(coordinates: ICoordinates): boolean {
  return (
    coordinates &&
    typeof coordinates.latitude === 'number' &&
    typeof coordinates.longitude === 'number' &&
    coordinates.latitude >= -90 &&
    coordinates.latitude <= 90 &&
    coordinates.longitude >= -180 &&
    coordinates.longitude <= 180
  );
}

/**
 * Helper function to convert degrees to radians
 * @param degrees - Angle in degrees
 * @returns Angle in radians
 */
function toRadians(degrees: number): number {
  return degrees * (Math.PI / 180);
}

/**
 * Helper function to extract address components from Google Maps API response
 * @param components - Array of address components
 * @param type - Type of address component to extract
 * @returns Extracted address component or empty string
 */
function getAddressComponent(
  components: GeocodeResult['address_components'],
  type: string
): string {
  return (
    components.find(component => component.types.includes(type))?.long_name || ''
  );
}