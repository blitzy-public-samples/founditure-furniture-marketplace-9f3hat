/*
 * External dependencies:
 * androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.2
 * javax.inject:1
 * kotlinx.coroutines:1.7.3
 * okhttp3:4.11.0
 */

package com.founditure.presentation.listing

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import android.net.Uri
import android.location.Location
import okhttp3.MultipartBody

import com.founditure.domain.usecase.listing.CreateListingUseCase
import com.founditure.domain.model.Listing.FurnitureCondition
import com.founditure.util.LocationManager
import com.founditure.data.api.NetworkResult

/**
 * Human Tasks:
 * 1. Configure proper error handling strategy for production environment
 * 2. Set up analytics tracking for listing creation events
 * 3. Configure image compression settings based on target device capabilities
 * 4. Set up proper logging for debugging and monitoring
 * 5. Verify location permission handling in the UI layer
 */

/**
 * Data class representing the UI state for listing creation
 */
data class CreateListingUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val success: Boolean = false,
    val imageUri: Uri? = null,
    val condition: FurnitureCondition? = null,
    val location: Location? = null,
    val address: String? = null
)

/**
 * ViewModel responsible for managing the UI state and business logic for furniture listing creation.
 *
 * Requirements addressed:
 * - Core Features - Furniture listings (1.3): Implements user interface logic for creating listings
 * - AI-powered furniture recognition (1.3): Handles image capture workflow
 * - Location-based discovery (1.3): Integrates location services for geotagging
 */
@HiltViewModel
class CreateListingViewModel @Inject constructor(
    private val createListingUseCase: CreateListingUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(CreateListingUiState())
    val uiState: StateFlow<CreateListingUiState> = _uiState.asStateFlow()

    private var selectedImageUri: Uri? = null
    private var selectedCondition: FurnitureCondition? = null
    private var currentLocation: Location? = null

    /**
     * Creates a new furniture listing with the current state data.
     * 
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3): Implements listing creation with validation
     */
    fun createListing(title: String, description: String) {
        viewModelScope.launch {
            try {
                // Validate required data
                if (selectedImageUri == null || selectedCondition == null || currentLocation == null) {
                    _uiState.value = _uiState.value.copy(
                        error = "Please provide all required information: image, condition, and location"
                    )
                    return@launch
                }

                _uiState.value = _uiState.value.copy(isLoading = true, error = null)

                // Create multipart image
                val imageFile = selectedImageUri?.let { uri ->
                    // Note: Actual file conversion implementation would be handled by a FileUtils class
                    MultipartBody.Part.createFormData("image", "listing_image.jpg", TODO())
                } ?: throw IllegalStateException("Image URI is null")

                // Execute listing creation
                val result = createListingUseCase.execute(
                    image = imageFile,
                    title = title,
                    description = description,
                    condition = selectedCondition!!,
                    latitude = currentLocation!!.latitude,
                    longitude = currentLocation!!.longitude,
                    address = _uiState.value.address ?: ""
                )

                when (result) {
                    is NetworkResult.Success -> {
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            success = true,
                            error = null
                        )
                    }
                    is NetworkResult.Error -> {
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            error = result.message
                        )
                    }
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = "Failed to create listing: ${e.message}"
                )
            }
        }
    }

    /**
     * Updates the selected image for the listing.
     * 
     * Requirements addressed:
     * - AI-powered furniture recognition (1.3): Handles image selection for furniture
     */
    fun updateImage(imageUri: Uri) {
        selectedImageUri = imageUri
        _uiState.value = _uiState.value.copy(
            imageUri = imageUri,
            error = null
        )
    }

    /**
     * Updates the selected furniture condition.
     * 
     * Requirements addressed:
     * - Core Features - Furniture listings (1.3): Implements furniture condition selection
     */
    fun updateCondition(condition: FurnitureCondition) {
        selectedCondition = condition
        _uiState.value = _uiState.value.copy(
            condition = condition,
            error = null
        )
    }

    /**
     * Updates the current location using LocationManager services.
     * 
     * Requirements addressed:
     * - Location-based discovery (1.3): Integrates location services for geotagging
     */
    fun updateLocation() {
        viewModelScope.launch {
            try {
                LocationManager.getLastKnownLocation(TODO())
                    .addOnSuccessListener { location ->
                        currentLocation = location
                        viewModelScope.launch {
                            val address = LocationManager.getAddressFromLocation(
                                TODO(),
                                location.latitude,
                                location.longitude
                            )
                            _uiState.value = _uiState.value.copy(
                                location = location,
                                address = address,
                                error = null
                            )
                        }
                    }
                    .addOnFailureListener { e ->
                        _uiState.value = _uiState.value.copy(
                            error = "Failed to get location: ${e.message}"
                        )
                    }
            } catch (e: SecurityException) {
                _uiState.value = _uiState.value.copy(
                    error = "Location permission not granted"
                )
            }
        }
    }
}