// External dependencies
import * as express from 'express'; // v4.18.0
import { Router } from 'express'; // v4.18.0

// Internal dependencies
import { authenticate } from '../middleware/auth.middleware';
import { AuthenticatedRequest } from '../middleware/auth.middleware';

/**
 * Human Tasks:
 * 1. Configure rate limiting for user profile endpoints
 * 2. Set up monitoring for user profile operations
 * 3. Configure caching strategy for frequently accessed profile data
 * 4. Set up proper error tracking for user service failures
 * 5. Configure proper CORS settings for user endpoints
 */

// Initialize router
const router = Router();

// Requirement: User Profile Management - Get user profile with points and achievements
const getUserProfile = async (req: AuthenticatedRequest, res: express.Response): Promise<express.Response> => {
  try {
    // Extract user ID from authenticated request
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated',
        status: 401
      });
    }

    try {
      // Fetch user profile from user service
      const userProfile = await fetch(`${process.env.USER_SERVICE_URL}/users/${userId}`);
      const profileData = await userProfile.json();

      if (!userProfile.ok) {
        throw new Error('Failed to fetch user profile');
      }

      // Fetch user points from gamification service
      const userPoints = await fetch(`${process.env.GAMIFICATION_SERVICE_URL}/points/${userId}`);
      const pointsData = await userPoints.json();

      if (!userPoints.ok) {
        throw new Error('Failed to fetch user points');
      }

      // Fetch user achievements from gamification service
      const userAchievements = await fetch(`${process.env.GAMIFICATION_SERVICE_URL}/achievements/${userId}`);
      const achievementsData = await userAchievements.json();

      if (!userAchievements.ok) {
        throw new Error('Failed to fetch user achievements');
      }

      // Combine all user data
      const userData = {
        ...profileData,
        points: pointsData.points,
        level: pointsData.level,
        achievements: achievementsData.achievements
      };

      return res.status(200).json({
        success: true,
        message: 'User profile retrieved successfully',
        status: 200,
        data: userData
      });

    } catch (error) {
      if (error instanceof Error && error.message.includes('not found')) {
        return res.status(404).json({
          success: false,
          message: 'User not found',
          status: 404
        });
      }
      throw error;
    }
  } catch (error) {
    console.error('Error in getUserProfile:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      status: 500
    });
  }
};

// Requirement: User Profile Management - Update user profile information
const updateUserProfile = async (req: AuthenticatedRequest, res: express.Response): Promise<express.Response> => {
  try {
    // Extract user ID from authenticated request
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated',
        status: 401
      });
    }

    // Validate update profile request body
    const { name, email, avatar } = req.body;
    if (!name || !email) {
      return res.status(400).json({
        success: false,
        message: 'Name and email are required',
        status: 400
      });
    }

    try {
      // Update user profile in user service
      const updateResponse = await fetch(`${process.env.USER_SERVICE_URL}/users/${userId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ name, email, avatar })
      });

      if (!updateResponse.ok) {
        if (updateResponse.status === 404) {
          return res.status(404).json({
            success: false,
            message: 'User not found',
            status: 404
          });
        }
        throw new Error('Failed to update user profile');
      }

      const updatedProfile = await updateResponse.json();

      return res.status(200).json({
        success: true,
        message: 'Profile updated successfully',
        status: 200,
        data: updatedProfile
      });

    } catch (error) {
      if (error instanceof Error && error.message.includes('not found')) {
        return res.status(404).json({
          success: false,
          message: 'User not found',
          status: 404
        });
      }
      throw error;
    }
  } catch (error) {
    console.error('Error in updateUserProfile:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      status: 500
    });
  }
};

// Requirement: Gamification System - Get user achievements
const getUserAchievements = async (req: AuthenticatedRequest, res: express.Response): Promise<express.Response> => {
  try {
    // Extract user ID from authenticated request
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated',
        status: 401
      });
    }

    try {
      // Fetch achievements from gamification service
      const achievementsResponse = await fetch(`${process.env.GAMIFICATION_SERVICE_URL}/achievements/${userId}`);
      
      if (!achievementsResponse.ok) {
        if (achievementsResponse.status === 404) {
          return res.status(404).json({
            success: false,
            message: 'User achievements not found',
            status: 404
          });
        }
        throw new Error('Failed to fetch user achievements');
      }

      const achievementsData = await achievementsResponse.json();

      return res.status(200).json({
        success: true,
        message: 'User achievements retrieved successfully',
        status: 200,
        data: achievementsData
      });

    } catch (error) {
      if (error instanceof Error && error.message.includes('not found')) {
        return res.status(404).json({
          success: false,
          message: 'User achievements not found',
          status: 404
        });
      }
      throw error;
    }
  } catch (error) {
    console.error('Error in getUserAchievements:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      status: 500
    });
  }
};

// Requirement: Gamification System - Get user points and level
const getUserPoints = async (req: AuthenticatedRequest, res: express.Response): Promise<express.Response> => {
  try {
    // Extract user ID from authenticated request
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated',
        status: 401
      });
    }

    try {
      // Fetch points data from gamification service
      const pointsResponse = await fetch(`${process.env.GAMIFICATION_SERVICE_URL}/points/${userId}`);
      
      if (!pointsResponse.ok) {
        if (pointsResponse.status === 404) {
          return res.status(404).json({
            success: false,
            message: 'User points not found',
            status: 404
          });
        }
        throw new Error('Failed to fetch user points');
      }

      const pointsData = await pointsResponse.json();

      return res.status(200).json({
        success: true,
        message: 'User points retrieved successfully',
        status: 200,
        data: pointsData
      });

    } catch (error) {
      if (error instanceof Error && error.message.includes('not found')) {
        return res.status(404).json({
          success: false,
          message: 'User points not found',
          status: 404
        });
      }
      throw error;
    }
  } catch (error) {
    console.error('Error in getUserPoints:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      status: 500
    });
  }
};

// Configure routes with authentication middleware
router.get('/profile', authenticate, getUserProfile);
router.put('/profile', authenticate, updateUserProfile);
router.get('/achievements', authenticate, getUserAchievements);
router.get('/points', authenticate, getUserPoints);

export default router;