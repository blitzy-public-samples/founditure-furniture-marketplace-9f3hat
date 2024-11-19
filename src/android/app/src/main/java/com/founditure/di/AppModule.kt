/*
 * External dependencies:
 * dagger.hilt.android:2.48
 * dagger:2.48
 * javax.inject:1
 */

package com.founditure.di

import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

import com.founditure.data.repository.AuthRepository
import com.founditure.data.repository.ListingRepository
import com.founditure.data.repository.MessageRepository
import com.founditure.data.repository.UserRepository
import com.founditure.data.api.ApiService
import com.founditure.data.database.dao.UserDao
import com.founditure.data.database.dao.ListingDao
import com.founditure.data.database.dao.MessageDao

/**
 * Human Tasks:
 * 1. Configure proper network security for API service in production
 * 2. Set up database encryption for sensitive user data
 * 3. Implement proper token refresh mechanism in API service
 * 4. Configure appropriate database backup strategies
 * 5. Set up proper logging and monitoring for production environment
 */

/**
 * Primary Dagger Hilt module providing application-level dependencies and repository instances.
 * 
 * Requirements addressed:
 * - Core Features (1.3 Scope/Core Features): Provides dependency injection setup for core application 
 *   features including authentication, listings, and messaging with offline-first support
 * - System Architecture (2.1 High-Level Architecture/Mobile Applications): Implements dependency 
 *   injection pattern for Android application components ensuring proper scoping and lifecycle management
 */
@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    /**
     * Provides singleton instance of AuthRepository for user authentication.
     * 
     * Requirements addressed:
     * - Core Features (1.3): Provides authentication repository with offline support
     * - System Architecture (2.1): Ensures proper scoping of authentication dependencies
     */
    @Provides
    @Singleton
    fun provideAuthRepository(
        apiService: ApiService,
        userDao: UserDao
    ): AuthRepository {
        return AuthRepository(apiService, userDao)
    }

    /**
     * Provides singleton instance of ListingRepository for furniture listings.
     * 
     * Requirements addressed:
     * - Core Features (1.3): Provides listing repository with offline-first support
     * - System Architecture (2.1): Ensures proper scoping of listing dependencies
     */
    @Provides
    @Singleton
    fun provideListingRepository(
        apiService: ApiService,
        listingDao: ListingDao
    ): ListingRepository {
        return ListingRepository(apiService, listingDao)
    }

    /**
     * Provides singleton instance of MessageRepository for real-time messaging.
     * 
     * Requirements addressed:
     * - Core Features (1.3): Provides messaging repository with real-time updates
     * - System Architecture (2.1): Ensures proper scoping of messaging dependencies
     */
    @Provides
    @Singleton
    fun provideMessageRepository(
        apiService: ApiService,
        messageDao: MessageDao
    ): MessageRepository {
        return MessageRepository(messageDao, apiService)
    }

    /**
     * Provides singleton instance of UserRepository for user profiles.
     * 
     * Requirements addressed:
     * - Core Features (1.3): Provides user repository with offline caching
     * - System Architecture (2.1): Ensures proper scoping of user profile dependencies
     */
    @Provides
    @Singleton
    fun provideUserRepository(
        apiService: ApiService,
        userDao: UserDao
    ): UserRepository {
        return UserRepository(userDao, apiService)
    }
}