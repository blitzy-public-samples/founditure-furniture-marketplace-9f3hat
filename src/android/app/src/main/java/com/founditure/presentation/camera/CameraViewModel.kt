/*
 * Human Tasks:
 * 1. Verify camera permissions are properly configured in AndroidManifest.xml
 * 2. Ensure AWS Rekognition service is properly configured and accessible
 * 3. Test camera functionality on various Android device models
 * 4. Monitor memory usage during image capture and processing
 * 5. Configure proper error tracking for camera operations
 */

package com.founditure.presentation.camera

// AndroidX dependencies
import androidx.lifecycle.ViewModel // androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
import androidx.camera.core.ImageCapture // androidx.camera:camera-core:1.3.0
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import android.content.Context

// Kotlin coroutines
import kotlinx.coroutines.flow.MutableStateFlow // kotlinx-coroutines-core:1.7.1
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

// Dependency injection
import dagger.hilt.android.lifecycle.HiltViewModel // dagger.hilt:2.47
import javax.inject.Inject // javax.inject:1

// Internal imports
import com.founditure.domain.usecase.listing.CreateListingUseCase
import com.founditure.util.ImageUtils

/**
 * ViewModel that manages camera operations and image processing for furniture recognition.
 * 
 * Requirements addressed:
 * - AI-powered furniture recognition (1.3 Scope/Core Features): Manages camera state and 
 *   image processing for AI-powered furniture recognition
 * - Device Support (3.1 User Interface Design): Handles camera operations for Android 10+ 
 *   devices using CameraX API
 */
@HiltViewModel
class CameraViewModel @Inject constructor(
    private val createListingUseCase: CreateListingUseCase
) : ViewModel() {

    // Camera states
    sealed class CameraState {
        object Initializing : CameraState()
        object Ready : CameraState()
        data class Error(val message: String) : CameraState()
    }

    private val _cameraState = MutableStateFlow<CameraState>(CameraState.Initializing)
    val cameraState: StateFlow<CameraState> = _cameraState.asStateFlow()

    private val _processingImage = MutableStateFlow(false)
    val processingImage: StateFlow<Boolean> = _processingImage.asStateFlow()

    private lateinit var cameraProvider: ProcessCameraProvider
    private var imageCapture: ImageCapture? = null

    /**
     * Initializes and binds camera use cases using CameraX.
     * 
     * Requirements addressed:
     * - Device Support (3.1 User Interface Design): Implements CameraX setup for modern Android devices
     *
     * @param context Application context for camera provider
     * @param previewView Surface for camera preview
     */
    suspend fun initializeCamera(context: Context, previewView: PreviewView) {
        try {
            _cameraState.value = CameraState.Initializing

            // Initialize camera provider
            cameraProvider = ProcessCameraProvider.getInstance(context).get()

            // Configure preview use case
            val preview = Preview.Builder()
                .build()
                .also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }

            // Configure image capture use case
            imageCapture = ImageCapture.Builder()
                .setCaptureMode(ImageCapture.CAPTURE_MODE_MAXIMIZE_QUALITY)
                .build()

            // Bind use cases to lifecycle
            cameraProvider.unbindAll()
            cameraProvider.bindToLifecycle(
                context as androidx.lifecycle.LifecycleOwner,
                androidx.camera.core.CameraSelector.DEFAULT_BACK_CAMERA,
                preview,
                imageCapture
            )

            _cameraState.value = CameraState.Ready
        } catch (e: Exception) {
            _cameraState.value = CameraState.Error("Failed to initialize camera: ${e.message}")
        }
    }

    /**
     * Captures and processes an image for furniture recognition.
     * 
     * Requirements addressed:
     * - AI-powered furniture recognition (1.3 Scope/Core Features): Implements image capture
     *   and processing for AWS Rekognition
     *
     * @param context Application context for file operations
     */
    suspend fun captureImage(context: Context) {
        val imageCaptureUseCase = imageCapture ?: return
        _processingImage.value = true

        try {
            // Capture image
            imageCaptureUseCase.takePicture(
                androidx.camera.core.ImageCapture.OutputFileOptions.Builder(
                    java.io.File(context.cacheDir, "furniture_${System.currentTimeMillis()}.jpg")
                ).build(),
                context.mainExecutor,
                object : ImageCapture.OnImageSavedCallback {
                    override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                        outputFileResults.savedUri?.let { uri ->
                            // Process captured image
                            val bitmap = android.provider.MediaStore.Images.Media.getBitmap(
                                context.contentResolver,
                                uri
                            )

                            // Compress and prepare image for AI processing
                            val compressedBitmap = ImageUtils.compressImage(bitmap)
                            val preparedBitmap = ImageUtils.prepareForAI(compressedBitmap)

                            // Save processed image
                            val processedUri = ImageUtils.saveImageToFile(
                                context,
                                preparedBitmap,
                                "processed_furniture_${System.currentTimeMillis()}"
                            )

                            // Clean up resources
                            bitmap.recycle()
                            compressedBitmap.recycle()
                            preparedBitmap.recycle()

                            _processingImage.value = false
                        }
                    }

                    override fun onError(exception: ImageCaptureException) {
                        _processingImage.value = false
                        _cameraState.value = CameraState.Error("Failed to capture image: ${exception.message}")
                    }
                }
            )
        } catch (e: Exception) {
            _processingImage.value = false
            _cameraState.value = CameraState.Error("Failed to process image: ${e.message}")
        }
    }

    /**
     * Cleans up camera resources when ViewModel is cleared.
     */
    override fun onCleared() {
        super.onCleared()
        if (::cameraProvider.isInitialized) {
            cameraProvider.unbindAll()
        }
        imageCapture = null
        _cameraState.value = CameraState.Initializing
        _processingImage.value = false
    }
}