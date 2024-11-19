// External dependencies
import dotenv from 'dotenv'; // v16.0.0

// Internal dependencies
import { SERVICE_ENDPOINTS } from '../../../shared/constants';

/**
 * Human Tasks:
 * 1. Set up environment variables in deployment environments:
 *    - PORT: Service port number
 *    - HOST: Service host address
 *    - BASE_URL: Service base URL
 *    - NODE_ENV: Environment (development/production)
 *    - GOOGLE_MAPS_API_KEY: Valid Google Maps API key
 *    - MAPS_REGION: Maps region code
 * 2. Review and adjust geolocation boundaries for North American coverage
 * 3. Configure monitoring settings based on infrastructure requirements
 * 4. Validate Google Maps API key has required permissions enabled
 */

// Initialize environment variables
dotenv.config();

/**
 * Location Service Configuration
 * Centralizes all configuration settings for the location-based furniture discovery service
 */
export const config = {
  /**
   * Service configuration settings
   * Requirement: Location-based discovery - Core service configuration
   */
  service: {
    name: 'location-service',
    port: process.env.PORT || 3004,
    host: process.env.HOST || '0.0.0.0',
    baseUrl: process.env.BASE_URL || 'http://localhost:3004',
    environment: process.env.NODE_ENV || 'development'
  },

  /**
   * Google Maps integration configuration
   * Requirement: Maps Integration - Integration with Google Maps for location services
   */
  maps: {
    provider: 'google',
    apiKey: process.env.GOOGLE_MAPS_API_KEY,
    region: process.env.MAPS_REGION || 'NA',
    defaultZoom: 13,
    maxZoom: 18,
    minZoom: 10,
    geocodingApiEndpoint: 'https://maps.googleapis.com/maps/api/geocode/json'
  },

  /**
   * Geolocation settings and boundaries
   * Requirements:
   * - Location-based discovery - Location-based discovery services for finding furniture items
   * - Geographic Boundaries - Major urban centers in North America
   */
  geolocation: {
    defaultRadius: 5000, // Default search radius in meters
    maxRadius: 50000, // Maximum allowed search radius
    minRadius: 1000, // Minimum allowed search radius
    defaultUnit: 'meters',
    maxResults: 100, // Maximum results per query
    coordinatePrecision: 6, // Decimal places for coordinate precision
    // North American continental boundaries
    boundaryRestrictions: {
      minLat: 24.396308, // Southern boundary (Mexico border)
      maxLat: 49.384358, // Northern boundary (Canadian border)
      minLng: -125.0, // Western boundary (Pacific coast)
      maxLng: -66.93457 // Eastern boundary (Atlantic coast)
    },
    searchDefaults: {
      radius: 5000, // Default search radius in meters
      limit: 20, // Default results per page
      sortBy: 'distance' // Default sort criteria
    },
    caching: {
      enabled: true,
      ttl: 3600, // Cache TTL in seconds
      maxEntries: 10000 // Maximum cache entries
    }
  },

  /**
   * Service monitoring configuration
   * Requirement: Location-based discovery - Service health and performance monitoring
   */
  monitoring: {
    enabled: true,
    metricsInterval: 60000, // Metrics collection interval in milliseconds
    healthCheckPath: '/health'
  }
} as const;

// Export individual config sections for granular access
export const { service, maps, geolocation, monitoring } = config;