/**
 * Jest Configuration for Founditure Backend Services
 * 
 * Human Tasks:
 * 1. Ensure test/setup.ts exists at <rootDir>/src/test/setup.ts for test environment setup
 * 2. Verify that all microservices follow the specified directory structure for path aliases
 * 3. Configure CI/CD pipeline to use the coverage reports generated in the 'coverage' directory
 */

// @ts-check
import type { Config } from 'jest'; // jest@29.0.0
import { compilerOptions } from './tsconfig.json';

/**
 * Jest configuration object that implements:
 * - Requirement A.2: Testing Strategy/Unit Testing
 *   Configures Jest for TypeScript-based unit testing with proper module resolution
 * - Requirement 6.5: CI/CD Pipeline/Pipeline Stages
 *   Implements strict test coverage thresholds (80% across all metrics)
 */
const jestConfig: Config = {
  // Use ts-jest preset for TypeScript support
  preset: 'ts-jest',

  // Set Node.js as the test environment
  testEnvironment: 'node',

  // Define root directory for tests
  roots: ['<rootDir>/src'],

  // Pattern matching for test files
  testMatch: [
    '**/*.test.ts',
    '**/*.spec.ts'
  ],

  // Path aliases that mirror TypeScript configuration
  moduleNameMapper: {
    '@shared/(.*)': '<rootDir>/src/shared/$1',
    '@config/(.*)': '<rootDir>/src/*/config/$1',
    '@models/(.*)': '<rootDir>/src/*/models/$1',
    '@controllers/(.*)': '<rootDir>/src/*/controllers/$1',
    '@services/(.*)': '<rootDir>/src/*/services/$1',
    '@utils/(.*)': '<rootDir>/src/*/utils/$1',
    '@middleware/(.*)': '<rootDir>/src/*/middleware/$1'
  },

  // Coverage configuration
  coverageDirectory: 'coverage',
  
  // Files to include in coverage analysis
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.test.ts',
    '!src/**/*.spec.ts',
    '!src/**/index.ts',
    '!src/**/*.d.ts'
  ],

  // Coverage thresholds as per CI/CD pipeline requirements (6.5)
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },

  // Test setup file for global configurations
  setupFilesAfterEnv: ['<rootDir>/src/test/setup.ts'],

  // Supported file extensions
  moduleFileExtensions: [
    'ts',
    'js',
    'json'
  ],

  // TypeScript transformation configuration using ts-jest
  transform: {
    '^.+\\.ts$': 'ts-jest'
  }
};

export default jestConfig;