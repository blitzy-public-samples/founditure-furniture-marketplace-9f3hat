// SwiftUI framework - Latest
import SwiftUI
// AVFoundation framework - Latest
import AVFoundation
// Combine framework - Latest
import Combine

/// Human Tasks:
/// 1. Configure proper camera session cleanup on app backgrounding
/// 2. Review and adjust image quality settings for optimal performance
/// 3. Verify proper memory management for captured images
/// 4. Set up proper error logging for camera failures
/// 5. Configure appropriate timeout values for image processing

// MARK: - Camera State
/// Requirements addressed:
/// - Core Features (1.3): Define camera states for UI feedback
public enum CameraState {
    case ready
    case capturing
    case processing
    case error
}

// MARK: - Camera Error
/// Requirements addressed:
/// - Core Features (1.3): Handle camera-related errors
public enum CameraError: Error {
    case setupFailed
    case captureFailed
    case permissionDenied
    case processingFailed
}

// MARK: - Camera View Model
/// Requirements addressed:
/// - AI-powered furniture recognition (1.2): Manages camera capture and AI processing
/// - Core Features (1.3): Implements real-time camera feed processing
@MainActor
public final class CameraViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var state: CameraState = .ready
    @Published private(set) var hasPermission: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastProcessedImage: ProcessedImage?
    
    // MARK: - Private Properties
    
    private let captureSession: AVCaptureSession
    private let imageProcessor: ImageProcessor
    private let photoOutput: AVCapturePhotoOutput
    private var cancellables: Set<AnyCancellable>
    
    // MARK: - Constants
    
    private enum Constants {
        static let sessionPreset = AVCaptureSession.Preset.photo
        static let photoQuality = AVCapturePhotoSettings.Quality.high
        static let processingTimeout: TimeInterval = 30.0
    }
    
    // MARK: - Initialization
    
    /// Initialize the camera view model with required dependencies
    public init(imageProcessor: ImageProcessor) {
        self.imageProcessor = imageProcessor
        self.captureSession = AVCaptureSession()
        self.photoOutput = AVCapturePhotoOutput()
        self.cancellables = Set<AnyCancellable>()
        
        // Configure initial state
        self.state = .ready
        
        // Check camera permissions on initialization
        Task {
            await checkPermissions()
        }
    }
    
    // MARK: - Public Methods
    
    /// Set up camera capture session with proper configuration
    /// Requirements addressed:
    /// - Core Features (1.3): Configure camera for furniture capture
    public func setupCamera() async throws {
        guard case .authorized = try await PermissionManager.shared.requestCameraPermission() else {
            throw CameraError.permissionDenied
        }
        
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        // Set quality preset
        captureSession.sessionPreset = Constants.sessionPreset
        
        // Configure camera input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            throw CameraError.setupFailed
        }
        
        guard captureSession.canAddInput(videoInput) else {
            throw CameraError.setupFailed
        }
        captureSession.addInput(videoInput)
        
        // Configure photo output
        guard captureSession.canAddOutput(photoOutput) else {
            throw CameraError.setupFailed
        }
        captureSession.addOutput(photoOutput)
        
        // Configure photo settings
        photoOutput.isHighResolutionCaptureEnabled = true
        photoOutput.maxPhotoQualityPrioritization = .quality
        
        // Start running session
        captureSession.startRunning()
    }
    
    /// Capture and process an image from the camera
    /// Requirements addressed:
    /// - AI-powered furniture recognition (1.2): Capture and process furniture images
    public func captureImage() async throws -> ProcessedImage {
        guard state == .ready else {
            throw CameraError.captureFailed
        }
        
        state = .capturing
        
        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = Constants.photoQuality
        
        return try await withCheckedThrowingContinuation { continuation in
            let photoOutput = self.photoOutput
            
            photoOutput.capturePhoto(with: settings) { photoData in
                guard let imageData = photoData.fileDataRepresentation(),
                      let capturedImage = UIImage(data: imageData) else {
                    continuation.resume(throwing: CameraError.captureFailed)
                    return
                }
                
                Task {
                    do {
                        let processedImage = try await self.processCapturedImage(capturedImage)
                        continuation.resume(returning: processedImage)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    /// Process the captured image for furniture recognition
    /// Requirements addressed:
    /// - AI-powered furniture recognition (1.2): Process images for furniture detection
    private func processCapturedImage(_ image: UIImage) async throws -> ProcessedImage {
        state = .processing
        
        do {
            // Process image with timeout
            let processedImage = try await withThrowingTaskGroup(of: ProcessedImage.self) { group in
                group.addTask {
                    // Process image and perform furniture recognition
                    return try await self.imageProcessor.processImage(image)
                }
                
                // Wait for processing with timeout
                let result = try await group.next()
                group.cancelAll()
                
                guard let processedImage = result else {
                    throw CameraError.processingFailed
                }
                
                return processedImage
            }
            
            state = .ready
            lastProcessedImage = processedImage
            return processedImage
            
        } catch {
            state = .error
            errorMessage = error.localizedDescription
            throw CameraError.processingFailed
        }
    }
    
    /// Check and request camera permissions
    /// Requirements addressed:
    /// - Core Features (1.3): Handle camera permissions
    private func checkPermissions() async {
        do {
            let status = try await PermissionManager.shared.requestCameraPermission()
            hasPermission = status == .authorized
            
            if hasPermission {
                try await setupCamera()
            } else {
                errorMessage = "Camera permission is required to use this feature"
                state = .error
            }
        } catch {
            hasPermission = false
            errorMessage = "Failed to access camera: \(error.localizedDescription)"
            state = .error
        }
    }
    
    // MARK: - Deinitialization
    
    deinit {
        captureSession.stopRunning()
        cancellables.removeAll()
    }
}