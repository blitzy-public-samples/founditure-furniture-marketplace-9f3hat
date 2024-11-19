/*
 * Human Tasks:
 * 1. Ensure Hilt dependencies are properly configured in build.gradle
 * 2. Verify location permissions are properly requested in the UI layer
 * 3. Configure proper location update intervals in LocationManager for production
 * 4. Set up proper error tracking and analytics for location failures
 */

package com.founditure.presentation.map

// AndroidX and Lifecycle - 2.6.1
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope

// Kotlin Coroutines - 1.7.3
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.catch

// Location Services
import android.location.Location
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationResult

// Dependency Injection
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

// Internal imports
import com.founditure.util.LocationManager
import com.founditure.data.repository.ListingRepository
import com.founditure.domain.model.Listing

/**
 * ViewModel that manages the state and business logic for the map-based furniture discovery screen.
 * 
 * Requirements addressed:
 * - Location-based furniture discovery (1.3 Scope/Core Features)
 * - Geographic Coverage (1.3 Scope/Implementation Boundaries)
 * - Data Storage Solutions (2.3.2)
 */
@HiltViewModel
class MapViewModel @Inject constructor(
    private val listingRepository: ListingRepository
) : ViewModel() {

    // Location state
    private val _currentLocation = MutableStateFlow<Location?>(null)
    val currentLocation: StateFlow<Location?> = _currentLocation.asStateFlow()

    // Listings state
    private val _nearbyListings = MutableStateFlow<List<Listing>>(emptyList())
    val nearbyListings: StateFlow<List<Listing>> = _nearbyListings.asStateFlow()

    // Search radius state (in kilometers)
    private val _searchRadius = MutableStateFlow(5.0) // Default 5km radius
    val searchRadius: StateFlow<Double> = _searchRadius.asStateFlow()

    // Loading state
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    // Location callback for continuous updates
    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(locationResult: LocationResult) {
            locationResult.lastLocation?.let { location ->
                _currentLocation.value = location
                refreshNearbyListings()
            }
        }
    }

    init {
        // Start location updates when ViewModel is created
        startLocationUpdates()
        
        // Get initial location
        viewModelScope.launch {
            try {
                LocationManager.getLastKnownLocation(context)
                    .addOnSuccessListener { location ->
                        _currentLocation.value = location
                        refreshNearbyListings()
                    }
            } catch (e: SecurityException) {
                // Handle permission not granted
            }
        }
    }

    /**
     * Starts receiving location updates from LocationManager.
     * Implements location-based discovery requirement.
     */
    private fun startLocationUpdates() {
        try {
            LocationManager.requestLocationUpdates(context, locationCallback)
        } catch (e: SecurityException) {
            // Handle permission not granted
        }
    }

    /**
     * Stops location updates when ViewModel is cleared.
     * Implements proper resource cleanup.
     */
    override fun onCleared() {
        super.onCleared()
        LocationManager.stopLocationUpdates(locationCallback)
    }

    /**
     * Updates the search radius for nearby listings discovery.
     * Implements geographic coverage requirement.
     *
     * @param radius New search radius in kilometers
     */
    fun updateSearchRadius(radius: Double) {
        _searchRadius.value = radius
        refreshNearbyListings()
    }

    /**
     * Refreshes the list of nearby furniture listings using repository.
     * Implements offline-first data access strategy.
     */
    private fun refreshNearbyListings() {
        viewModelScope.launch {
            _isLoading.value = true
            
            try {
                _currentLocation.value?.let { location ->
                    listingRepository.getNearbyListings(
                        latitude = location.latitude,
                        longitude = location.longitude,
                        radiusKm = _searchRadius.value
                    )
                        .catch { throwable ->
                            // Handle error but continue with cached data
                            _isLoading.value = false
                        }
                        .collect { listings ->
                            _nearbyListings.value = listings.filter { it.isAvailable() }
                            _isLoading.value = false
                        }
                }
            } catch (e: Exception) {
                // Handle repository errors
                _isLoading.value = false
            }
        }
    }
}