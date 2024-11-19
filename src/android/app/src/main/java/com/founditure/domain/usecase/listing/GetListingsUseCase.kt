/*
 * External dependencies:
 * javax.inject:1
 * kotlinx-coroutines-flow:1.7.3
 */

package com.founditure.domain.usecase.listing

import javax.inject.Inject
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

import com.founditure.data.repository.ListingRepository
import com.founditure.domain.model.Listing
import com.founditure.domain.model.ListingStatus
import com.founditure.domain.model.FurnitureCondition

/**
 * Human Tasks:
 * 1. Configure proper dependency injection in the DI module
 * 2. Set up proper error handling strategy for production environment
 * 3. Configure monitoring for listing retrieval operations
 * 4. Set up proper logging for debugging and monitoring
 */

/**
 * Use case that encapsulates the business logic for retrieving furniture listings with support for 
 * filtering, sorting, and location-based discovery following clean architecture principles.
 *
 * Requirements addressed:
 * - Core Features - Location-based furniture discovery (1.3): 
 *   Enables users to discover furniture items based on location and filtering criteria
 * - Data Storage Solutions (2.3.2):
 *   Implements caching strategy with offline-first approach through repository pattern
 */
class GetListingsUseCase @Inject constructor(
    private val listingRepository: ListingRepository
) {
    /**
     * Retrieves listings based on provided filtering parameters with location-based discovery support.
     * 
     * Requirements addressed:
     * - Core Features - Location-based furniture discovery (1.3):
     *   Implements location-based filtering with radius search
     * - Data Storage Solutions (2.3.2):
     *   Leverages repository pattern for offline-first data access
     *
     * @param latitude Optional latitude for location-based search
     * @param longitude Optional longitude for location-based search
     * @param radiusKm Optional radius in kilometers for location-based search
     * @param status Optional status filter for listings
     * @param condition Optional condition filter for listings
     * @return Flow of filtered listings from repository with offline-first support
     */
    operator fun invoke(
        latitude: Double? = null,
        longitude: Double? = null,
        radiusKm: Double? = null,
        status: ListingStatus? = null,
        condition: FurnitureCondition? = null
    ): Flow<List<Listing>> {
        // Validate location parameters are either all provided or all null
        val hasLocation = latitude != null && longitude != null && radiusKm != null
        val hasPartialLocation = latitude != null || longitude != null || radiusKm != null

        require(!hasPartialLocation || hasLocation) {
            "All location parameters (latitude, longitude, radiusKm) must be provided together"
        }

        // Get base flow of listings based on location parameters
        val baseFlow = if (hasLocation) {
            listingRepository.getNearbyListings(
                latitude = latitude!!,
                longitude = longitude!!,
                radiusKm = radiusKm!!
            )
        } else {
            listingRepository.getListings()
        }

        // Apply filters to the base flow
        return baseFlow.map { listings ->
            listings.filter { listing ->
                val matchesStatus = status?.let { listing.status == it } ?: true
                val matchesCondition = condition?.let { listing.condition == it } ?: true
                matchesStatus && matchesCondition
            }
        }
    }
}