// External dependencies
import dotenv from 'dotenv'; // v16.0.0
import { ConnectOptions } from 'mongoose'; // v7.0.0

// Internal dependencies
import { POINTS_CONFIG } from '../../../shared/constants';
import { BaseModel } from '../../../shared/interfaces/model.interface';

/**
 * Human Tasks:
 * 1. Configure MongoDB connection string in environment variables
 * 2. Review and adjust point values for optimal user engagement
 * 3. Set up monitoring for achievement unlocks and level progression
 * 4. Configure backup strategy for gamification data
 * 5. Implement rate limiting for point-earning actions
 */

// Load environment variables
dotenv.config();

// MongoDB configuration interface
interface MongoConfig {
  uri: string;
  options: ConnectOptions;
}

// Points configuration interface
interface PointsConfig {
  LISTING_CREATED: number;
  ITEM_COLLECTED: number;
  QUICK_COLLECTION: number;
  ACCURATE_DESCRIPTION: number;
  POSITIVE_FEEDBACK: number;
  MONTHLY_ACTIVE: number;
}

// Achievement interface extending BaseModel
interface Achievement extends BaseModel {
  id: string;
  name: string;
  description: string;
  points: number;
  requirement: number;
}

// Level interface for user progression
interface Level {
  name: string;
  minPoints: number;
  maxPoints: number | null;
}

// Server port configuration
// Requirement: 2.2.1 Core Components - Core Services with microservices architecture
export const PORT = process.env.PORT || 3005;

// MongoDB connection configuration
// Requirement: 3.2.2 Data Management Strategy - Consistent data operations
export const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/founditure-gamification';

// Points system configuration
// Requirement: 1.2 System Overview/Success Criteria - 70% monthly active user retention through gamification
export const POINTS_SYSTEM: PointsConfig = {
  LISTING_CREATED: POINTS_CONFIG.LISTING_CREATED,
  ITEM_COLLECTED: POINTS_CONFIG.ITEM_COLLECTED,
  QUICK_COLLECTION: POINTS_CONFIG.QUICK_COLLECTION,
  ACCURATE_DESCRIPTION: 10,
  POSITIVE_FEEDBACK: 15,
  MONTHLY_ACTIVE: 25
};

// Achievement configuration
// Requirement: 1.3 Scope/Core Features - Gamification system with points and achievements
export const ACHIEVEMENTS: Record<string, Achievement> = {
  FIRST_FIND: {
    id: 'FIRST_FIND',
    name: 'First Find',
    description: 'Post your first furniture item',
    points: 50,
    requirement: 1,
    createdAt: new Date(),
    updatedAt: new Date(),
    isActive: true
  },
  QUICK_COLLECTOR: {
    id: 'QUICK_COLLECTOR',
    name: 'Quick Collector',
    description: 'Collect 5 items within 30 days',
    points: 100,
    requirement: 5,
    createdAt: new Date(),
    updatedAt: new Date(),
    isActive: true
  },
  SUPER_SAVER: {
    id: 'SUPER_SAVER',
    name: 'Super Saver',
    description: 'Save 500kg of furniture from landfill',
    points: 200,
    requirement: 500,
    createdAt: new Date(),
    updatedAt: new Date(),
    isActive: true
  }
};

// Level progression configuration
// Requirement: 1.2 System Overview/Success Criteria - User Engagement through gamification
export const LEVELS: Record<string, Level> = {
  NOVICE: {
    name: 'Novice',
    minPoints: 0,
    maxPoints: 99
  },
  COLLECTOR: {
    name: 'Collector',
    minPoints: 100,
    maxPoints: 499
  },
  EXPERT: {
    name: 'Expert',
    minPoints: 500,
    maxPoints: 999
  },
  MASTER: {
    name: 'Master',
    minPoints: 1000,
    maxPoints: null
  }
};

// MongoDB connection options
const mongooseOptions: ConnectOptions = {
  autoIndex: true,
  serverSelectionTimeoutMS: 5000,
  socketTimeoutMS: 45000,
  family: 4,
  maxPoolSize: 50
};

// Export complete configuration object
// Requirement: 2.2.1 Core Components - Core Services with microservices architecture
export const config = {
  port: PORT,
  mongodb: {
    uri: MONGODB_URI,
    options: mongooseOptions
  },
  pointsConfig: POINTS_SYSTEM,
  achievementsConfig: ACHIEVEMENTS,
  levelsConfig: LEVELS
};