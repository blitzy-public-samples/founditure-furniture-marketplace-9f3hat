/*
 * External dependencies:
 * retrofit2:2.9.0
 * kotlinx-coroutines-core:1.7.0
 * okhttp3:4.11.0
 */

package com.founditure.data.api

import com.founditure.data.api.NetworkResult
import com.founditure.domain.model.User
import com.founditure.domain.model.Listing
import com.founditure.domain.model.Message
import okhttp3.MultipartBody
import okhttp3.RequestBody
import retrofit2.http.*

/**
 * Human Tasks:
 * 1. Configure Retrofit instance with proper base URL in DI module
 * 2. Set up OkHttpClient with appropriate timeouts and interceptors
 * 3. Implement proper token refresh mechanism in the auth interceptor
 * 4. Configure ProGuard rules for Retrofit and OkHttp if using R8/ProGuard
 * 5. Set up proper SSL certificate pinning for production environment
 */

/**
 * Interface defining the REST API endpoints for the Founditure Android application.
 * 
 * Requirements addressed:
 * - API Architecture (3.3.1): Implements REST/HTTP/2 protocol with JWT + OAuth2 authentication
 * - Core Features (1.3): API endpoints for user authentication, furniture listings, messaging
 * - System Monitoring (2.4.1): Error tracking through NetworkResult wrapper
 */
interface ApiService {

    /**
     * Authenticates user with email and password.
     * 
     * Requirements addressed:
     * - API Architecture (3.3.1): Implements standardized authentication endpoint
     * - System Monitoring (2.4.1): Comprehensive error tracking for auth failures
     *
     * @param credentials Map containing email and password
     * @return NetworkResult containing User data on success or error message
     */
    @POST("auth/login")
    suspend fun login(
        @Body credentials: Map<String, String>
    ): NetworkResult<User>

    /**
     * Registers a new user account.
     * 
     * Requirements addressed:
     * - API Architecture (3.3.1): Implements user registration with validation
     * - Core Features (1.3): User account creation functionality
     *
     * @param userData Map containing user registration details
     * @return NetworkResult containing created User data or error
     */
    @POST("auth/register")
    suspend fun register(
        @Body userData: Map<String, String>
    ): NetworkResult<User>

    /**
     * Retrieves user profile data.
     * 
     * Requirements addressed:
     * - Core Features (1.3): User profile management
     * - System Monitoring (2.4.1): Profile data retrieval tracking
     *
     * @param userId Unique identifier of the user
     * @return NetworkResult containing User profile data or error
     */
    @GET("users/{userId}")
    suspend fun getProfile(
        @Path("userId") userId: String
    ): NetworkResult<User>

    /**
     * Creates a new furniture listing with image upload.
     * 
     * Requirements addressed:
     * - Core Features (1.3): Furniture listing creation
     * - API Architecture (3.3.1): Multipart file upload handling
     *
     * @param image Image file for the listing
     * @param listingData Map containing listing details
     * @return NetworkResult containing created Listing or error
     */
    @Multipart
    @POST("listings")
    suspend fun createListing(
        @Part image: MultipartBody.Part,
        @PartMap listingData: Map<String, RequestBody>
    ): NetworkResult<Listing>

    /**
     * Retrieves furniture listings with optional filters.
     * 
     * Requirements addressed:
     * - Core Features (1.3): Furniture discovery functionality
     * - System Monitoring (2.4.1): Listing retrieval tracking
     *
     * @param filters Optional map of filter parameters
     * @return NetworkResult containing List of filtered listings or error
     */
    @GET("listings")
    suspend fun getListings(
        @QueryMap filters: Map<String, String>
    ): NetworkResult<List<Listing>>

    /**
     * Retrieves a specific listing by ID.
     * 
     * Requirements addressed:
     * - Core Features (1.3): Detailed furniture item view
     * - System Monitoring (2.4.1): Individual listing access tracking
     *
     * @param listingId Unique identifier of the listing
     * @return NetworkResult containing Listing data or error
     */
    @GET("listings/{listingId}")
    suspend fun getListingById(
        @Path("listingId") listingId: String
    ): NetworkResult<Listing>

    /**
     * Sends a message to another user.
     * 
     * Requirements addressed:
     * - Core Features (1.3): Real-time messaging functionality
     * - System Monitoring (2.4.1): Message delivery tracking
     *
     * @param messageData Map containing message content and metadata
     * @return NetworkResult containing sent Message data or error
     */
    @POST("messages")
    suspend fun sendMessage(
        @Body messageData: Map<String, String>
    ): NetworkResult<Message>

    /**
     * Retrieves messages for a conversation.
     * 
     * Requirements addressed:
     * - Core Features (1.3): Message history retrieval
     * - System Monitoring (2.4.1): Conversation access tracking
     *
     * @param listingId ID of the listing being discussed
     * @param otherUserId ID of the other user in conversation
     * @return NetworkResult containing List of messages or error
     */
    @GET("messages")
    suspend fun getMessages(
        @Query("listingId") listingId: String,
        @Query("otherUserId") otherUserId: String
    ): NetworkResult<List<Message>>
}