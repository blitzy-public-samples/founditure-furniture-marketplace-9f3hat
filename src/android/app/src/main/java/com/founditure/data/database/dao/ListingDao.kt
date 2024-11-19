package com.founditure.data.database.dao

// Room persistence library v2.6.0
import androidx.room.Dao
import androidx.room.Query
import androidx.room.Insert
import androidx.room.Update
import androidx.room.Delete

// Kotlin coroutines Flow v1.7.3
import kotlinx.coroutines.flow.Flow

// Internal imports
import com.founditure.data.database.entity.ListingEntity

/**
 * Human Tasks:
 * 1. Ensure Room dependencies are properly configured in build.gradle
 * 2. Set up database inspector in Android Studio for query debugging
 * 3. Configure database migration strategy if schema changes
 * 4. Verify index creation on frequently queried columns for performance
 */

/**
 * Data Access Object interface for furniture listing database operations.
 * Provides CRUD operations and complex queries with reactive data streams.
 *
 * Requirements addressed:
 * - Data Storage Solutions (2.3.2): Implements structured data access patterns using Room
 * - Core Features - Furniture listings (1.3): Database access layer for listing information
 * - Location-based discovery (1.3): Geolocation-based queries using Haversine formula
 */
@Dao
interface ListingDao {

    /**
     * Inserts a new listing into the database.
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3): Create operation for new listings
     */
    @Insert
    suspend fun insertListing(listing: ListingEntity): Long

    /**
     * Updates an existing listing in the database.
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3): Update operation for existing listings
     */
    @Update
    suspend fun updateListing(listing: ListingEntity): Int

    /**
     * Deletes a listing from the database.
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3): Delete operation for listings
     */
    @Delete
    suspend fun deleteListing(listing: ListingEntity): Int

    /**
     * Retrieves a listing by its ID.
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3): Read operation for single listing
     */
    @Query("SELECT * FROM listings WHERE id = :id")
    suspend fun getListingById(id: String): ListingEntity?

    /**
     * Retrieves all listings ordered by posting date.
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3): Read operation for all listings
     * - Data Storage Solutions (2.3.2): Reactive data streams using Flow
     */
    @Query("SELECT * FROM listings ORDER BY posted_at DESC")
    fun getAllListings(): Flow<List<ListingEntity>>

    /**
     * Retrieves listings with specific status.
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3): Filtered read operation by status
     * - Data Storage Solutions (2.3.2): Reactive data streams using Flow
     */
    @Query("SELECT * FROM listings WHERE status = :status ORDER BY posted_at DESC")
    fun getListingsByStatus(status: String): Flow<List<ListingEntity>>

    /**
     * Retrieves listings within specified radius of coordinates using Haversine formula.
     * Requirements addressed:
     * - Location-based discovery (1.3): Geolocation-based radius search
     * - Data Storage Solutions (2.3.2): Complex SQL query with distance calculation
     */
    @Query("""
        SELECT *, 
        (6371 * acos(
            cos(radians(:latitude)) * 
            cos(radians(latitude)) * 
            cos(radians(longitude) - radians(:longitude)) + 
            sin(radians(:latitude)) * 
            sin(radians(latitude))
        )) AS distance 
        FROM listings 
        HAVING distance <= :radiusKm 
        ORDER BY distance
    """)
    fun getNearbyListings(
        latitude: Double,
        longitude: Double,
        radiusKm: Double
    ): Flow<List<ListingEntity>>

    /**
     * Retrieves all listings for a specific user.
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3): User-specific listing retrieval
     * - Data Storage Solutions (2.3.2): Reactive data streams using Flow
     */
    @Query("SELECT * FROM listings WHERE user_id = :userId ORDER BY posted_at DESC")
    fun getUserListings(userId: String): Flow<List<ListingEntity>>
}