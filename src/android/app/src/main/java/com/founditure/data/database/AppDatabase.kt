package com.founditure.data.database

// Room persistence library v2.6.0
import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import android.content.Context

// Internal imports
import com.founditure.data.database.dao.ListingDao
import com.founditure.data.database.dao.MessageDao
import com.founditure.data.database.dao.UserDao
import com.founditure.data.database.entity.ListingEntity
import com.founditure.data.database.entity.MessageEntity
import com.founditure.data.database.entity.UserEntity
import com.founditure.data.database.entity.ListingConverters

/**
 * Human Tasks:
 * 1. Verify Room dependencies are properly configured in build.gradle
 * 2. Ensure database migrations are set up when schema changes
 * 3. Configure database encryption if storing sensitive data
 * 4. Set up database backup strategy
 * 5. Monitor database performance and query execution
 */

/**
 * Room database abstract class that serves as the main database configuration and access point
 * for the Founditure application.
 *
 * Requirements addressed:
 * - Data Storage Solutions (2.3.2): Implements structured data storage using Room persistence library
 * - Core Features (1.3): Provides local database support for user profiles, furniture listings, and messaging
 * - User Engagement (1.2): Supports offline data access and caching for improved user engagement
 */
@Database(
    entities = [
        UserEntity::class,
        ListingEntity::class,
        MessageEntity::class
    ],
    version = 1,
    exportSchema = true
)
@TypeConverters(ListingConverters::class)
abstract class AppDatabase : RoomDatabase() {

    /**
     * Data access object for user-related database operations
     */
    abstract fun userDao(): UserDao

    /**
     * Data access object for furniture listing database operations
     */
    abstract fun listingDao(): ListingDao

    /**
     * Data access object for message database operations
     */
    abstract fun messageDao(): MessageDao

    companion object {
        // Volatile ensures the INSTANCE is always up to date across all threads
        @Volatile
        private var INSTANCE: AppDatabase? = null

        /**
         * Gets the singleton database instance, creating it if necessary.
         * Uses double-checked locking pattern for thread safety.
         *
         * Requirements addressed:
         * - Data Storage Solutions (2.3.2): Implements singleton pattern for database access
         * - User Engagement (1.2): Ensures consistent database access across the application
         *
         * @param context Application context used to create the database
         * @return The singleton AppDatabase instance
         */
        fun getDatabase(context: Context): AppDatabase {
            // Return existing instance if available
            INSTANCE?.let { return it }

            // Synchronize database creation to prevent multiple instances
            return synchronized(this) {
                // Double-check pattern to ensure thread safety
                INSTANCE?.let { return it }

                // Create database instance
                Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "founditure_db"
                )
                .apply {
                    // Enable database export for debugging
                    enableMultiInstanceInvalidation()
                    
                    // Add fallback to destructive migration for development
                    // TODO: Replace with proper migration strategy before production
                    fallbackToDestructiveMigration()
                    
                    // Add callback for database creation/open events
                    addCallback(object : RoomDatabase.Callback() {
                        override fun onCreate(db: SupportSQLiteDatabase) {
                            super.onCreate(db)
                            // Initialize database with required data if needed
                        }

                        override fun onOpen(db: SupportSQLiteDatabase) {
                            super.onOpen(db)
                            // Perform any necessary operations when database is opened
                        }
                    })
                }
                .build()
                .also { INSTANCE = it }
            }
        }
    }
}