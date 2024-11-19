// SwiftUI framework - Latest
import SwiftUI
// PhotosUI framework - Latest
import PhotosUI

/// Human Tasks:
/// 1. Verify proper camera and photo library usage descriptions in Info.plist
/// 2. Review image compression settings for optimal performance
/// 3. Configure proper error logging for permission and processing failures
/// 4. Test furniture recognition accuracy with various lighting conditions
/// 5. Validate memory management with large image processing tasks

// MARK: - Photo Picker Source
/// Requirements addressed:
/// - Core Features (1.3): User authentication and profile management
public enum PhotoPickerSource {
    case camera
    case photoLibrary
}

// MARK: - Photo Picker Error
/// Requirements addressed:
/// - Core Features (1.3): Define error handling for photo selection
public enum PhotoPickerError: Error {
    case permissionDenied
    case imageSelectionFailed
    case processingFailed
}

// MARK: - Photo Picker View
/// Requirements addressed:
/// - AI-powered furniture recognition (1.2): Implement furniture recognition capabilities
/// - Device Support (1.3): Support iOS 14+ deployment target
@MainActor
public struct PhotoPicker: View {
    // MARK: - Private Properties
    
    private let imageProcessor: ImageProcessor
    private let permissionManager: PermissionManager
    @Binding private var selectedImage: UIImage?
    @Binding private var isPresented: Bool
    private let source: PhotoPickerSource
    private let onImageSelected: (UIImage) -> Void
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // MARK: - Initialization
    
    public init(
        imageProcessor: ImageProcessor,
        selectedImage: Binding<UIImage?>,
        isPresented: Binding<Bool>,
        source: PhotoPickerSource,
        onImageSelected: @escaping (UIImage) -> Void
    ) {
        self.imageProcessor = imageProcessor
        self._selectedImage = selectedImage
        self._isPresented = isPresented
        self.source = source
        self.onImageSelected = onImageSelected
        self.permissionManager = PermissionManager.shared
    }
    
    // MARK: - Body
    
    public var body: some View {
        EmptyView()
            .sheet(isPresented: $showingImagePicker) {
                if source == .photoLibrary {
                    ImagePicker(selectedImage: $selectedImage) { image in
                        Task {
                            await handleSelectedImage(image)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(selectedImage: $selectedImage) { image in
                    Task {
                        await handleSelectedImage(image)
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    showingError = false
                }
            } message: {
                Text(errorMessage)
            }
            .task {
                await checkPermissions()
            }
    }
    
    // MARK: - Private Methods
    
    /// Check and request necessary permissions
    /// Requirements addressed:
    /// - Core Features (1.3): Handle permissions for camera and photo library
    private func checkPermissions() async {
        do {
            let status: PermissionStatus
            switch source {
            case .camera:
                status = try await permissionManager.requestCameraPermission()
            case .photoLibrary:
                status = try await permissionManager.requestPhotoLibraryPermission()
            }
            
            switch status {
            case .authorized:
                showPickerForSource()
            case .denied, .restricted:
                showError(message: "Permission denied. Please enable access in Settings.")
            case .notDetermined:
                showError(message: "Unable to determine permission status.")
            }
        } catch {
            showError(message: "Failed to check permissions: \(error.localizedDescription)")
        }
    }
    
    /// Show appropriate picker based on source
    private func showPickerForSource() {
        switch source {
        case .camera:
            showingCamera = true
        case .photoLibrary:
            showingImagePicker = true
        }
    }
    
    /// Process selected image with furniture recognition
    /// Requirements addressed:
    /// - AI-powered furniture recognition (1.2): Process images with AI recognition
    private func handleSelectedImage(_ image: UIImage) async {
        do {
            // Process image and perform furniture recognition
            let processedImage = try await imageProcessor.processImage(image)
            
            // Update UI and call completion handler
            await MainActor.run {
                selectedImage = processedImage.image
                onImageSelected(processedImage.image)
                isPresented = false
            }
        } catch {
            showError(message: "Failed to process image: \(error.localizedDescription)")
        }
    }
    
    /// Show error alert with message
    private func showError(message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Image Picker
private struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                return
            }
            
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard let image = image as? UIImage else { return }
                
                Task { @MainActor in
                    self?.parent.selectedImage = image
                    self?.parent.onImageSelected(image)
                }
            }
        }
    }
}

// MARK: - Camera View
private struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            
            if let image = info[.originalImage] as? UIImage {
                Task { @MainActor in
                    parent.selectedImage = image
                    parent.onImageSelected(image)
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}