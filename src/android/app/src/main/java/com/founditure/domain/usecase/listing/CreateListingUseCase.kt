/*
 * External dependencies:
 * javax.inject:1
 * okhttp3:4.11.0
 */

package com.founditure.domain.usecase.listing

import javax.inject.Inject
import okhttp3.MultipartBody
import okhttp3.RequestBody

import com.founditure.data.repository.ListingRepository
import com.founditure.domain.model.Listing
import com.founditure.domain.model.Listing.FurnitureCondition
import com.founditure.data.api.NetworkResult

/**
 * Human Tasks:
 * 1. Configure proper error handling strategy for production environment
 * 2. Set up monitoring for listing creation metrics
 * 3. Configure image compression and validation rules
 * 4. Set up proper logging for debugging and monitoring
 * 5. Configure rate limiting for listing creation if needed
 */

/**
 * Use case that encapsulates the business logic for creating new furniture listings
 * with validation and error handling.
 *
 * Requirements addressed:
 * - Core Features - Furniture listings (1.3): Implements creation of furniture listings
 *   with images and metadata, ensuring data validation and proper persistence
 * - AI-powered furniture recognition (1.3): Integrates with AI services for furniture
 *   recognition during listing creation process
 */
class CreateListingUseCase @Inject constructor(
    private val listingRepository: ListingRepository
) {

    /**
     * Creates a new furniture listing with provided image and metadata.
     *
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3): Implements listing creation with validation
     * - AI-powered furniture recognition (1.3): Processes images for furniture recognition
     *
     * @param image Image file for the listing
     * @param title Title of the furniture item
     * @param description Detailed description of the furniture
     * @param condition Physical condition of the furniture
     * @param latitude Geographical latitude of the furniture location
     * @param longitude Geographical longitude of the furniture location
     * @param address Human-readable address of the furniture location
     * @return NetworkResult containing created Listing or error
     */
    suspend fun execute(
        image: MultipartBody.Part,
        title: String,
        description: String,
        condition: FurnitureCondition,
        latitude: Double,
        longitude: Double,
        address: String
    ): NetworkResult<Listing> {
        // Validate input parameters
        if (!validateInput(title, description, latitude, longitude)) {
            return NetworkResult.Error("Invalid input parameters")
        }

        // Create listing data map
        val listingData = mutableMapOf<String, RequestBody>().apply {
            put("title", RequestBody.create(null, title))
            put("description", RequestBody.create(null, description))
            put("condition", RequestBody.create(null, condition.name))
            put("latitude", RequestBody.create(null, latitude.toString()))
            put("longitude", RequestBody.create(null, longitude.toString()))
            put("address", RequestBody.create(null, address))
            put("status", RequestBody.create(null, ListingStatus.AVAILABLE.name))
        }

        // Create listing through repository
        return listingRepository.createListing(image, listingData)
    }

    /**
     * Validates the listing creation input parameters.
     *
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3): Implements data validation
     *
     * @param title Title of the furniture item
     * @param description Detailed description of the furniture
     * @param latitude Geographical latitude
     * @param longitude Geographical longitude
     * @return true if input is valid, false otherwise
     */
    private fun validateInput(
        title: String,
        description: String,
        latitude: Double,
        longitude: Double
    ): Boolean {
        // Title validation: 3-100 characters
        if (title.length !in 3..100) {
            return false
        }

        // Description validation: 10-1000 characters
        if (description.length !in 10..1000) {
            return false
        }

        // Latitude validation: -90 to 90 degrees
        if (latitude !in -90.0..90.0) {
            return false
        }

        // Longitude validation: -180 to 180 degrees
        if (longitude !in -180.0..180.0) {
            return false
        }

        return true
    }
}