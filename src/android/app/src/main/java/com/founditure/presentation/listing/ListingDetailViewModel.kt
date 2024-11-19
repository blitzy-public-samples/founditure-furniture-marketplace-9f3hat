/*
 * External dependencies:
 * androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.2
 * kotlinx-coroutines-core:1.7.3
 * javax.inject:1
 */

package com.founditure.presentation.listing

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import com.founditure.data.api.NetworkResult
import com.founditure.data.repository.ListingRepository
import com.founditure.data.repository.MessageRepository
import com.founditure.domain.model.Listing
import com.founditure.domain.model.Message

/**
 * Human Tasks:
 * 1. Configure proper dependency injection in the DI module
 * 2. Set up appropriate error tracking and monitoring
 * 3. Configure proper logging strategy for production environment
 * 4. Verify proper memory management for image loading
 */

/**
 * Sealed class representing the UI state for the listing detail screen
 */
sealed class ListingDetailUiState {
    object Loading : ListingDetailUiState()
    data class Success(val listing: Listing) : ListingDetailUiState()
    data class Error(val message: String) : ListingDetailUiState()
}

/**
 * ViewModel that manages the state and user interactions for the listing detail screen.
 * Implements offline-first architecture with real-time messaging support.
 *
 * Requirements addressed:
 * - Core Features - Furniture listings (1.3 Scope/Core Features):
 *   Implements detailed view of furniture listings with messaging capability
 * - Real-time messaging (1.2 System Overview/High-Level Description):
 *   Enables real-time communication between users about listings
 */
class ListingDetailViewModel @Inject constructor(
    private val listingRepository: ListingRepository,
    private val messageRepository: MessageRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow<ListingDetailUiState>(ListingDetailUiState.Loading)
    val uiState: StateFlow<ListingDetailUiState> = _uiState.asStateFlow()

    private val _messages = MutableStateFlow<List<Message>>(emptyList())
    val messages: StateFlow<List<Message>> = _messages.asStateFlow()

    private var currentListingId: String? = null

    /**
     * Loads the listing details and messages for a given listing ID with offline-first support.
     * 
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3):
     *   Implements detailed furniture listing view functionality
     *
     * @param listingId Unique identifier of the listing to load
     */
    fun loadListingDetails(listingId: String) {
        currentListingId = listingId
        _uiState.value = ListingDetailUiState.Loading

        viewModelScope.launch {
            try {
                when (val result = listingRepository.getListingById(listingId)) {
                    is NetworkResult.Success -> {
                        _uiState.value = ListingDetailUiState.Success(result.data)
                        // Start collecting messages after listing is loaded
                        collectMessages(listingId)
                    }
                    is NetworkResult.Error -> {
                        _uiState.value = ListingDetailUiState.Error(
                            result.message.ifEmpty { "Failed to load listing details" }
                        )
                    }
                }
            } catch (e: Exception) {
                _uiState.value = ListingDetailUiState.Error(
                    e.message ?: "An unexpected error occurred"
                )
            }
        }
    }

    /**
     * Sends a message to the listing owner with optimistic updates.
     * 
     * Requirements addressed:
     * - Real-time messaging (1.2):
     *   Implements real-time communication between users
     *
     * @param content Content of the message to send
     * @return NetworkResult containing sent Message or error
     */
    suspend fun sendMessage(content: String): NetworkResult<Message> {
        val currentListing = (uiState.value as? ListingDetailUiState.Success)?.listing
            ?: return NetworkResult.Error("No active listing")

        val message = Message(
            id = System.currentTimeMillis().toString(), // Temporary ID for optimistic update
            senderId = "currentUserId", // Should be injected from UserManager
            receiverId = currentListing.userId,
            listingId = currentListing.id,
            content = content,
            timestamp = System.currentTimeMillis(),
            isRead = false
        )

        return messageRepository.sendMessage(message)
    }

    /**
     * Refreshes the listing details from the repository.
     * 
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3):
     *   Implements data refresh functionality for listing details
     */
    fun refreshListing() {
        currentListingId?.let { listingId ->
            viewModelScope.launch {
                try {
                    _uiState.value = ListingDetailUiState.Loading
                    listingRepository.refreshListings()
                    loadListingDetails(listingId)
                } catch (e: Exception) {
                    _uiState.value = ListingDetailUiState.Error(
                        e.message ?: "Failed to refresh listing"
                    )
                }
            }
        }
    }

    /**
     * Collects messages for the current listing using Flow.
     *
     * @param listingId ID of the listing to collect messages for
     */
    private fun collectMessages(listingId: String) {
        viewModelScope.launch {
            try {
                messageRepository.getListingMessages(listingId)
                    .collect { messageList ->
                        _messages.value = messageList
                    }
            } catch (e: Exception) {
                // Log error but don't update UI state as messages are secondary
                println("Error collecting messages: ${e.message}")
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        // Clean up any resources if needed
    }
}