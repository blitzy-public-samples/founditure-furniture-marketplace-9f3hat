/*
 * External dependencies:
 * javax.inject:1
 * kotlinx-coroutines-core:1.7.3
 * okhttp3:4.11.0
 */

package com.founditure.data.repository

import javax.inject.Inject
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.emitAll
import kotlinx.coroutines.flow.flow
import okhttp3.MultipartBody
import okhttp3.RequestBody

import com.founditure.data.api.ApiService
import com.founditure.data.api.NetworkResult
import com.founditure.data.database.dao.ListingDao
import com.founditure.data.database.entity.ListingEntity
import com.founditure.domain.model.Listing

/**
 * Human Tasks:
 * 1. Configure proper error handling strategy in production environment
 * 2. Set up monitoring for background sync operations
 * 3. Configure proper cache invalidation policy
 * 4. Implement retry mechanism for failed network requests
 * 5. Set up proper logging for debugging and monitoring
 */

/**
 * Repository implementation that coordinates furniture listing data operations between remote API 
 * and local database cache, following the repository pattern for clean architecture.
 *
 * Requirements addressed:
 * - Core Features - Furniture listings (1.3): Implements furniture listing management
 * - Data Storage Solutions (2.3.2): Implements offline-first caching strategy
 * - Location-based discovery (1.3): Handles location-based furniture discovery
 */
class ListingRepository @Inject constructor(
    private val apiService: ApiService,
    private val listingDao: ListingDao
) {

    /**
     * Creates a new furniture listing with image and data.
     * 
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3): Implements listing creation
     * - Data Storage Solutions (2.3.2): Persists data in local cache
     *
     * @param image Image file for the listing
     * @param listingData Map containing listing details
     * @return NetworkResult containing created Listing or error
     */
    suspend fun createListing(
        image: MultipartBody.Part,
        listingData: Map<String, RequestBody>
    ): NetworkResult<Listing> {
        return when (val response = apiService.createListing(image, listingData)) {
            is NetworkResult.Success -> {
                val listing = response.data
                listingDao.insertListing(listing.toListingEntity())
                NetworkResult.Success(listing)
            }
            is NetworkResult.Error -> response
        }
    }

    /**
     * Retrieves all listings with offline-first support.
     * 
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3): Implements listing retrieval
     * - Data Storage Solutions (2.3.2): Implements offline-first strategy
     *
     * @return Flow of listings from cache with background sync
     */
    fun getListings(): Flow<List<Listing>> = flow {
        // Emit cached data first
        emitAll(listingDao.getAllListings().map { entities ->
            entities.map { it.toListing() }
        })

        // Fetch fresh data in background
        try {
            when (val response = apiService.getListings(emptyMap())) {
                is NetworkResult.Success -> {
                    response.data.forEach { listing ->
                        listingDao.insertListing(listing.toListingEntity())
                    }
                }
                is NetworkResult.Error -> {
                    // Log error but don't interrupt flow
                }
            }
        } catch (e: Exception) {
            // Log error but don't interrupt flow
        }
    }.catch { e ->
        // Log error but continue with cached data
        emitAll(listingDao.getAllListings().map { entities ->
            entities.map { it.toListing() }
        })
    }

    /**
     * Retrieves a specific listing by ID with offline-first support.
     * 
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3): Implements single listing retrieval
     * - Data Storage Solutions (2.3.2): Implements offline-first strategy
     *
     * @param listingId Unique identifier of the listing
     * @return NetworkResult containing Listing or error
     */
    suspend fun getListingById(listingId: String): NetworkResult<Listing> {
        // Check cache first
        listingDao.getListingById(listingId)?.let {
            return NetworkResult.Success(it.toListing())
        }

        // If not in cache, fetch from API
        return when (val response = apiService.getListingById(listingId)) {
            is NetworkResult.Success -> {
                val listing = response.data
                listingDao.insertListing(listing.toListingEntity())
                NetworkResult.Success(listing)
            }
            is NetworkResult.Error -> response
        }
    }

    /**
     * Retrieves listings near specified location with offline-first support.
     * 
     * Requirements addressed:
     * - Location-based discovery (1.3): Implements location-based listing discovery
     * - Data Storage Solutions (2.3.2): Implements offline-first strategy
     *
     * @param latitude Geographical latitude
     * @param longitude Geographical longitude
     * @param radiusKm Search radius in kilometers
     * @return Flow of nearby listings
     */
    fun getNearbyListings(
        latitude: Double,
        longitude: Double,
        radiusKm: Double
    ): Flow<List<Listing>> = flow {
        // Emit cached nearby listings first
        emitAll(listingDao.getNearbyListings(latitude, longitude, radiusKm)
            .map { entities -> entities.map { it.toListing() } })

        // Fetch fresh nearby data in background
        try {
            val filters = mapOf(
                "latitude" to latitude.toString(),
                "longitude" to longitude.toString(),
                "radius" to radiusKm.toString()
            )
            when (val response = apiService.getListings(filters)) {
                is NetworkResult.Success -> {
                    response.data.forEach { listing ->
                        listingDao.insertListing(listing.toListingEntity())
                    }
                }
                is NetworkResult.Error -> {
                    // Log error but don't interrupt flow
                }
            }
        } catch (e: Exception) {
            // Log error but don't interrupt flow
        }
    }.catch { e ->
        // Log error but continue with cached data
        emitAll(listingDao.getNearbyListings(latitude, longitude, radiusKm)
            .map { entities -> entities.map { it.toListing() } })
    }

    /**
     * Forces a refresh of cached listings from the API.
     * 
     * Requirements addressed:
     * - Data Storage Solutions (2.3.2): Implements cache refresh mechanism
     * - Core Features - Furniture listings (1.3): Ensures data freshness
     */
    suspend fun refreshListings() {
        when (val response = apiService.getListings(emptyMap())) {
            is NetworkResult.Success -> {
                response.data.forEach { listing ->
                    listingDao.insertListing(listing.toListingEntity())
                }
            }
            is NetworkResult.Error -> {
                // Propagate error to caller
                throw Exception("Failed to refresh listings: ${response.message}")
            }
        }
    }
}