/*
 * Human Tasks:
 * 1. Verify Google Maps API key is properly configured in local.properties
 * 2. Test map performance and memory usage on low-end Android devices
 * 3. Validate map accessibility features with TalkBack enabled
 * 4. Review map marker touch targets meet WCAG 2.1 AA standards (44dp)
 */

package com.founditure.presentation.map

// androidx.compose.material3:material3:1.1.0
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text

// androidx.compose.runtime:runtime:1.5.0
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember

// androidx.compose.foundation:foundation:1.5.0
import androidx.compose.foundation.layout.*

// androidx.compose.ui:ui:1.5.0
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp

// com.google.maps.android.compose:maps-compose:2.11.4
import com.google.maps.android.compose.GoogleMap
import com.google.maps.android.compose.Marker
import com.google.maps.android.compose.Circle
import com.google.maps.android.compose.rememberCameraPositionState
import com.google.maps.android.compose.rememberMarkerState
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng

// androidx.hilt.navigation.compose:hilt-navigation-compose:1.0.0
import androidx.hilt.navigation.compose.hiltViewModel

// Internal imports
import com.founditure.presentation.components.ListingCard
import com.founditure.presentation.components.LoadingIndicator
import com.founditure.presentation.theme.FounditureTheme

/**
 * Main composable function that renders the map-based furniture discovery interface.
 * 
 * Requirements addressed:
 * - Location-based furniture discovery (1.3 Scope/Core Features)
 * - Geographic Coverage (1.3 Scope/Implementation Boundaries)
 * - Device Support (1.3 Scope/Implementation Boundaries)
 *
 * @param onNavigateToListing Callback for navigating to listing details
 */
@Composable
fun MapScreen(
    onNavigateToListing: (String) -> Unit
) {
    // Initialize ViewModel with Hilt
    val viewModel: MapViewModel = hiltViewModel()

    // Collect state flows
    val currentLocation by viewModel.currentLocation.collectAsState(initial = null)
    val nearbyListings by viewModel.nearbyListings.collectAsState(initial = emptyList())
    val searchRadius by viewModel.searchRadius.collectAsState(initial = 5.0)
    val isLoading by viewModel.isLoading.collectAsState(initial = false)

    // Set up camera position state
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(
            currentLocation?.let { LatLng(it.latitude, it.longitude) } 
                ?: LatLng(43.6532, -79.3832), // Default to Toronto
            12f
        )
    }

    Scaffold(
        modifier = Modifier.fillMaxSize()
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Google Map with markers and search radius
            GoogleMap(
                modifier = Modifier.fillMaxSize(),
                cameraPositionState = cameraPositionState,
                contentDescription = "Map showing nearby furniture listings"
            ) {
                // Draw search radius circle
                currentLocation?.let { location ->
                    Circle(
                        center = LatLng(location.latitude, location.longitude),
                        radius = searchRadius * 1000, // Convert km to meters
                        fillColor = FounditureTheme.colors.primaryContainer.copy(alpha = 0.2f),
                        strokeColor = FounditureTheme.colors.primary,
                        strokeWidth = 2f
                    )
                }

                // Add markers for nearby listings
                nearbyListings.forEach { listing ->
                    MapMarker(
                        listing = listing,
                        onClick = { onNavigateToListing(listing.id) }
                    )
                }
            }

            // Radius control slider
            RadiusControl(
                currentRadius = searchRadius,
                onRadiusChange = { viewModel.updateSearchRadius(it) },
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(16.dp)
            )

            // Loading indicator
            if (isLoading) {
                LoadingIndicator()
            }
        }
    }
}

/**
 * Composable function that renders a custom marker for a furniture listing.
 *
 * @param listing The listing to display as a marker
 * @param onClick Callback when marker is clicked
 */
@Composable
private fun MapMarker(
    listing: Listing,
    onClick: (Listing) -> Unit
) {
    val markerState = rememberMarkerState(
        position = LatLng(listing.latitude, listing.longitude)
    )

    Marker(
        state = markerState,
        title = listing.title,
        snippet = listing.description,
        onClick = { 
            onClick(listing)
            true
        },
        tag = listing.id,
        visible = listing.isAvailable()
    )
}

/**
 * Composable function that renders the search radius control slider.
 *
 * @param currentRadius Current search radius in kilometers
 * @param onRadiusChange Callback when radius is changed
 * @param modifier Modifier for the component
 */
@Composable
private fun RadiusControl(
    currentRadius: Double,
    onRadiusChange: (Double) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .background(
                color = FounditureTheme.colors.surface,
                shape = FounditureTheme.shapes.medium
            )
            .padding(16.dp)
            .semantics {
                contentDescription = "Search radius control"
            },
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Search Radius: ${String.format("%.1f", currentRadius)} km",
            style = FounditureTheme.typography.bodyMedium,
            color = FounditureTheme.colors.onSurface
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Slider(
            value = currentRadius.toFloat(),
            onValueChange = { onRadiusChange(it.toDouble()) },
            valueRange = 1f..50f,
            steps = 49,
            colors = SliderDefaults.colors(
                thumbColor = FounditureTheme.colors.primary,
                activeTrackColor = FounditureTheme.colors.primary,
                inactiveTrackColor = FounditureTheme.colors.surfaceVariant
            ),
            modifier = Modifier.width(280.dp)
        )
    }
}