package com.founditure.di

// Dagger Hilt v2.48
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import dagger.hilt.android.qualifiers.ApplicationContext

// javax.inject v1
import javax.inject.Singleton
import javax.inject.Provides

import android.content.Context

// Internal imports
import com.founditure.data.database.AppDatabase
import com.founditure.data.database.dao.ListingDao
import com.founditure.data.database.dao.MessageDao
import com.founditure.data.database.dao.UserDao

/**
 * Human Tasks:
 * 1. Verify Dagger Hilt dependencies are properly configured in build.gradle
 * 2. Ensure Room database migrations are set up for schema changes
 * 3. Configure database encryption if storing sensitive data
 * 4. Set up database backup strategy
 * 5. Monitor database performance metrics in production
 */

/**
 * Dagger Hilt module providing database and storage-related dependencies
 * with proper scoping and lifecycle management.
 *
 * Requirements addressed:
 * - Data Storage Solutions (2.3.2): Implements structured data storage using Room
 *   persistence library with proper dependency injection
 * - Core Features (1.3): Provides local database support for user profiles,
 *   furniture listings, and messaging through dependency injection
 * - User Engagement (1.2): Supports offline data access and caching through
 *   singleton scoped database instances
 */
@Module
@InstallIn(SingletonComponent::class)
object StorageModule {

    /**
     * Provides singleton instance of Room database with proper configuration
     * and lifecycle management.
     *
     * Requirements addressed:
     * - Data Storage Solutions (2.3.2): Implements structured data storage
     *   using Room persistence library
     * - User Engagement (1.2): Supports offline data access through singleton
     *   database instance
     *
     * @param context Application context for database initialization
     * @return Singleton AppDatabase instance
     */
    @Provides
    @Singleton
    fun provideAppDatabase(
        @ApplicationContext context: Context
    ): AppDatabase {
        return AppDatabase.getDatabase(context)
    }

    /**
     * Provides UserDao instance for user data access operations.
     *
     * Requirements addressed:
     * - Core Features (1.3): Provides local database support for user profiles
     * - Data Storage Solutions (2.3.2): Implements structured data access patterns
     *
     * @param database Singleton AppDatabase instance
     * @return UserDao instance for dependency injection
     */
    @Provides
    @Singleton
    fun provideUserDao(database: AppDatabase): UserDao {
        return database.userDao()
    }

    /**
     * Provides ListingDao instance for furniture listing data access operations.
     *
     * Requirements addressed:
     * - Core Features (1.3): Provides local database support for furniture listings
     * - Data Storage Solutions (2.3.2): Implements structured data access patterns
     *
     * @param database Singleton AppDatabase instance
     * @return ListingDao instance for dependency injection
     */
    @Provides
    @Singleton
    fun provideListingDao(database: AppDatabase): ListingDao {
        return database.listingDao()
    }

    /**
     * Provides MessageDao instance for message data access operations.
     *
     * Requirements addressed:
     * - Core Features (1.3): Provides local database support for messaging
     * - Data Storage Solutions (2.3.2): Implements structured data access patterns
     *
     * @param database Singleton AppDatabase instance
     * @return MessageDao instance for dependency injection
     */
    @Provides
    @Singleton
    fun provideMessageDao(database: AppDatabase): MessageDao {
        return database.messageDao()
    }
}