/*
 * Human Tasks:
 * 1. Verify camera permissions are properly configured in AndroidManifest.xml
 * 2. Test camera preview and capture functionality across different Android devices
 * 3. Validate AWS Rekognition integration and error handling
 * 4. Review memory usage during image capture and processing
 * 5. Test accessibility features with TalkBack enabled
 */

package com.founditure.presentation.camera

// Compose dependencies - androidx.compose:1.5.0
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView

// CameraX dependencies - androidx.camera:1.3.0
import androidx.camera.view.PreviewView
import androidx.camera.core.CameraSelector

// Navigation dependencies
import androidx.navigation.NavController

// Hilt dependencies - androidx.hilt:1.0.0
import androidx.hilt.navigation.compose.hiltViewModel

// Internal imports
import com.founditure.presentation.components.FounditureButton
import com.founditure.presentation.components.LoadingIndicator

/**
 * Main camera screen composable that implements the furniture image capture interface.
 * 
 * Requirements addressed:
 * - AI-powered furniture recognition (1.3 Scope/Core Features): 
 *   Provides camera interface for capturing furniture images for AWS Rekognition analysis
 * - Visual Hierarchy (3.1 User Interface Design): 
 *   Implements Material Design 3 principles with proper elevation and grid system
 * - Device Support (3.1 User Interface Design): 
 *   Supports Android 10+ devices with camera capabilities using CameraX API
 *
 * @param navController Navigation controller for handling screen transitions
 */
@Composable
fun CameraScreen(
    navController: NavController,
    viewModel: CameraViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    // Camera state management
    val cameraState by viewModel.cameraState.collectAsState()
    val isProcessing by viewModel.processingImage.collectAsState()

    // Camera preview setup
    val previewView = remember { PreviewView(context) }

    // Initialize camera when the screen is first displayed
    LaunchedEffect(previewView) {
        viewModel.initializeCamera(context, previewView)
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // Camera preview surface
        when (cameraState) {
            is CameraViewModel.CameraState.Ready -> {
                CameraPreview(previewView = previewView)
            }
            is CameraViewModel.CameraState.Error -> {
                // Display error state with retry option
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = (cameraState as CameraViewModel.CameraState.Error).message,
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.error
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    FounditureButton(
                        text = "Retry",
                        onClick = { viewModel.initializeCamera(context, previewView) }
                    )
                }
            }
            CameraViewModel.CameraState.Initializing -> {
                // Display loading state during initialization
                LoadingIndicator(size = 48.dp)
            }
        }

        // Camera controls overlay
        if (cameraState is CameraViewModel.CameraState.Ready) {
            CameraControls(
                isProcessing = isProcessing,
                onCaptureClick = { viewModel.captureImage(context) }
            )
        }
    }
}

/**
 * Camera preview composable that displays the real-time camera feed.
 * 
 * Requirements addressed:
 * - Device Support (3.1 User Interface Design): 
 *   Implements CameraX preview with proper lifecycle management
 *
 * @param previewView CameraX PreviewView instance for displaying camera feed
 */
@Composable
private fun CameraPreview(
    previewView: PreviewView
) {
    AndroidView(
        factory = { previewView },
        modifier = Modifier.fillMaxSize()
    ) {
        it.implementationMode = PreviewView.ImplementationMode.PERFORMANCE
        it.scaleType = PreviewView.ScaleType.FILL_CENTER
    }
}

/**
 * Camera controls composable that displays the capture button and loading state.
 * 
 * Requirements addressed:
 * - Visual Hierarchy (3.1 User Interface Design): 
 *   Implements Material Design 3 principles for button placement and loading states
 *
 * @param isProcessing Boolean indicating if image processing is in progress
 * @param onCaptureClick Callback invoked when capture button is clicked
 */
@Composable
private fun CameraControls(
    isProcessing: Boolean,
    onCaptureClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(bottom = 32.dp),
        contentAlignment = Alignment.BottomCenter
    ) {
        FounditureButton(
            text = "Capture",
            onClick = onCaptureClick,
            enabled = !isProcessing,
            loading = isProcessing
        )
    }
}