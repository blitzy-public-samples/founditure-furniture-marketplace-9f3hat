/*
 * Human Tasks:
 * 1. Test camera functionality across different Android devices and OS versions
 * 2. Verify location permission handling on Android 10+ devices
 * 3. Test image compression and upload with different network conditions
 * 4. Validate accessibility features with TalkBack enabled
 * 5. Test AI recognition feedback with various furniture types
 */

package com.founditure.presentation.listing

// External dependencies
// androidx.compose.runtime:runtime:1.5.0
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember

// androidx.compose.foundation:foundation:1.5.0
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable

// androidx.compose.material3:material3:1.1.0
import androidx.compose.material3.*
import androidx.compose.material3.MaterialTheme

// androidx.activity:activity-compose:1.7.2
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts

// androidx.hilt:hilt-navigation-compose:1.0.0
import androidx.hilt.navigation.compose.hiltViewModel

// androidx.navigation:navigation-compose:2.7.0
import androidx.navigation.NavController

// Internal imports
import com.founditure.presentation.components.FounditureButton
import com.founditure.presentation.components.FounditureTextField
import com.founditure.domain.model.Listing.FurnitureCondition
import android.net.Uri

/**
 * Main composable screen for creating new furniture listings.
 * 
 * Requirements addressed:
 * - Core Features - Furniture listings (1.3): Implements user interface for documenting furniture items
 * - AI-powered furniture recognition (1.3): Integrates camera functionality with AI recognition
 * - Location-based discovery (1.3): Captures location information for furniture items
 *
 * @param navController Navigation controller for screen navigation
 */
@Composable
fun CreateListingScreen(
    navController: NavController,
    viewModel: CreateListingViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicture()
    ) { success ->
        if (success) {
            uiState.imageUri?.let { uri ->
                viewModel.updateImage(uri)
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Image capture section
        ImageSection(
            imageUri = uiState.imageUri,
            onImageSelected = { uri -> viewModel.updateImage(uri) }
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Condition selector
        ConditionSelector(
            selectedCondition = uiState.condition,
            onConditionSelected = { condition -> viewModel.updateCondition(condition) }
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Location section
        LocationSection(
            location = uiState.location,
            address = uiState.address,
            onLocationUpdate = { viewModel.updateLocation() }
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Description input
        FounditureTextField(
            value = uiState.description ?: "",
            onValueChange = { /* Update description in ViewModel */ },
            label = "Description",
            maxLines = 3
        )

        Spacer(modifier = Modifier.weight(1f))

        // Submit button
        FounditureButton(
            text = "Create Listing",
            onClick = { viewModel.createListing() },
            enabled = uiState.isValid,
            loading = uiState.isLoading
        )
    }
}

/**
 * Composable for image capture and preview section.
 * 
 * Requirements addressed:
 * - AI-powered furniture recognition (1.3): Handles image capture and preview
 */
@Composable
private fun ImageSection(
    imageUri: Uri?,
    onImageSelected: (Uri) -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(200.dp)
    ) {
        if (imageUri != null) {
            Image(
                painter = rememberImagePainter(imageUri),
                contentDescription = "Furniture image preview",
                modifier = Modifier.fillMaxSize()
            )
        } else {
            FounditureButton(
                text = "Take Photo",
                onClick = { /* Launch camera */ }
            )
        }
    }
}

/**
 * Composable for selecting furniture condition.
 * 
 * Requirements addressed:
 * - Core Features - Furniture listings (1.3): Implements condition selection UI
 */
@Composable
private fun ConditionSelector(
    selectedCondition: FurnitureCondition?,
    onConditionSelected: (FurnitureCondition) -> Unit
) {
    Column {
        Text(
            text = "Condition",
            style = MaterialTheme.typography.titleMedium
        )
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            FurnitureCondition.values().forEach { condition ->
                FounditureButton(
                    text = condition.name,
                    onClick = { onConditionSelected(condition) },
                    enabled = true,
                    loading = false
                )
            }
        }
    }
}

/**
 * Composable for location information display and capture.
 * 
 * Requirements addressed:
 * - Location-based discovery (1.3): Implements location capture UI
 */
@Composable
private fun LocationSection(
    location: android.location.Location?,
    address: String?,
    onLocationUpdate: () -> Unit
) {
    Column {
        Text(
            text = "Location",
            style = MaterialTheme.typography.titleMedium
        )
        
        if (location != null && address != null) {
            Text(
                text = address,
                style = MaterialTheme.typography.bodyMedium
            )
        } else {
            FounditureButton(
                text = "Get Location",
                onClick = onLocationUpdate
            )
        }
    }
}