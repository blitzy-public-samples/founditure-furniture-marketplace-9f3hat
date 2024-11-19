/*
 * External dependencies:
 * androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.2
 * kotlinx.coroutines:kotlinx-coroutines-core:1.7.3
 * javax.inject:javax.inject:1
 */

package com.founditure.presentation.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.founditure.domain.usecase.listing.GetListingsUseCase
import com.founditure.domain.model.Listing
import com.founditure.domain.model.ListingStatus
import com.founditure.domain.model.FurnitureCondition
import com.founditure.util.LocationManager
import android.content.Context
import android.location.Location
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationResult
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Human Tasks:
 * 1. Configure proper dependency injection in the DI module
 * 2. Set up proper error handling strategy for production environment
 * 3. Configure monitoring for location updates and listing retrieval
 * 4. Set up proper logging for debugging and monitoring
 * 5. Verify location permission handling in the UI layer
 */

/**
 * ViewModel that manages the home screen state and user interactions with location-based furniture discovery.
 *
 * Requirements addressed:
 * - Core Features - Location-based furniture discovery (1.3):
 *   Implements location-based furniture discovery with real-time updates
 * - User Engagement (1.2):
 *   Supports user retention through engaging home feed with location-based content
 */
@HiltViewModel
class HomeViewModel @Inject constructor(
    private val getListingsUseCase: GetListingsUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow<HomeUiState>(HomeUiState.Loading)
    val uiState: StateFlow<HomeUiState> = _uiState

    private val _currentLocation = MutableStateFlow<Location?>(null)
    private val searchRadiusKm = 10.0

    private var currentStatus: ListingStatus? = null
    private var currentCondition: FurnitureCondition? = null

    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(locationResult: LocationResult) {
            locationResult.lastLocation?.let { location ->
                updateLocation(location)
            }
        }
    }

    init {
        loadListings()
    }

    /**
     * Starts location updates for furniture discovery.
     * 
     * Requirements addressed:
     * - Core Features - Location-based furniture discovery (1.3):
     *   Implements real-time location tracking for discovery
     *
     * @param context Application context for location services
     */
    fun startLocationUpdates(context: Context) {
        try {
            LocationManager.requestLocationUpdates(context, locationCallback)
        } catch (e: SecurityException) {
            _uiState.value = HomeUiState.Error("Location permission required for furniture discovery")
        }
    }

    /**
     * Updates current location and refreshes listings.
     * 
     * Requirements addressed:
     * - Core Features - Location-based furniture discovery (1.3):
     *   Updates furniture discovery based on location changes
     */
    fun updateLocation(location: Location) {
        _currentLocation.value = location
        loadListings()
    }

    /**
     * Loads furniture listings based on current location and filters.
     * 
     * Requirements addressed:
     * - Core Features - Location-based furniture discovery (1.3):
     *   Retrieves location-based furniture listings
     * - User Engagement (1.2):
     *   Provides engaging content feed with nearby furniture
     */
    fun loadListings() {
        viewModelScope.launch {
            _uiState.value = HomeUiState.Loading
            
            val location = _currentLocation.value
            
            getListingsUseCase(
                latitude = location?.latitude,
                longitude = location?.longitude,
                radiusKm = if (location != null) searchRadiusKm else null,
                status = currentStatus,
                condition = currentCondition
            )
            .catch { error ->
                _uiState.value = HomeUiState.Error(
                    error.message ?: "Failed to load furniture listings"
                )
            }
            .collect { listings ->
                _uiState.value = HomeUiState.Success(
                    listings = listings,
                    location = _currentLocation.value
                )
            }
        }
    }

    /**
     * Applies filtering criteria to listings.
     * 
     * Requirements addressed:
     * - Core Features - Location-based furniture discovery (1.3):
     *   Implements filtering for furniture discovery
     *
     * @param status Optional filter for listing status
     * @param condition Optional filter for furniture condition
     */
    fun applyFilter(status: ListingStatus? = null, condition: FurnitureCondition? = null) {
        currentStatus = status
        currentCondition = condition
        loadListings()
    }

    /**
     * Cleans up resources when ViewModel is destroyed.
     */
    override fun onCleared() {
        super.onCleared()
        LocationManager.stopLocationUpdates(locationCallback)
    }
}

/**
 * Sealed class representing possible UI states for the home screen.
 * 
 * Requirements addressed:
 * - Core Features - Location-based furniture discovery (1.3):
 *   Defines UI states for furniture discovery experience
 */
sealed class HomeUiState {
    object Loading : HomeUiState()
    data class Success(
        val listings: List<Listing>,
        val location: Location?
    ) : HomeUiState()
    data class Error(val message: String) : HomeUiState()
}