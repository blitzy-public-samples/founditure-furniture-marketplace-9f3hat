// SwiftUI framework - Latest
import SwiftUI
// AVFoundation framework - Latest
import AVFoundation

/// Human Tasks:
/// 1. Configure proper camera session cleanup on app backgrounding
/// 2. Review camera preview layer configuration for optimal performance
/// 3. Verify haptic feedback intensity with UX team
/// 4. Test camera guidelines overlay visibility in different lighting conditions
/// 5. Validate camera permission handling flow with UX team

/// CameraView: Main view for camera functionality and furniture image capture
/// Requirements addressed:
/// - AI-powered furniture recognition (1.2): Provides camera interface for AI-powered furniture recognition with real-time feedback
/// - Core Features (1.3): Implements camera interface for furniture recognition and categorization with user feedback
/// - Visual Hierarchy (3.1.1): Follows Material Design 3 guidelines with proper elevation and accessibility support
@MainActor
struct CameraView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = CameraViewModel(imageProcessor: ImageProcessor(apiClient: APIClient()))
    @State private var showingPermissionAlert = false
    @State private var showingImagePreview = false
    @State private var capturedImage: UIImage?
    @State private var isProcessing = false
    
    // MARK: - Constants
    
    private enum Constants {
        static let previewAspectRatio: CGFloat = 4/3
        static let guidelineOpacity: Double = 0.3
        static let buttonSpacing: CGFloat = 16
        static let errorDisplayDuration: TimeInterval = 3
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Camera preview
            cameraPreview()
                .edgesIgnoringSafeArea(.all)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Camera preview")
            
            // Camera guidelines overlay
            GeometryReader { geometry in
                Path { path in
                    // Draw rule of thirds grid
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    // Vertical lines
                    path.move(to: CGPoint(x: width/3, y: 0))
                    path.addLine(to: CGPoint(x: width/3, y: height))
                    path.move(to: CGPoint(x: 2*width/3, y: 0))
                    path.addLine(to: CGPoint(x: 2*width/3, y: height))
                    
                    // Horizontal lines
                    path.move(to: CGPoint(x: 0, y: height/3))
                    path.addLine(to: CGPoint(x: width, y: height/3))
                    path.move(to: CGPoint(x: 0, y: 2*height/3))
                    path.addLine(to: CGPoint(x: width, y: 2*height/3))
                }
                .stroke(FounditureColors.onSurface.opacity(Constants.guidelineOpacity), lineWidth: 1)
            }
            
            // Controls overlay
            VStack {
                Spacer()
                
                // Capture button
                captureButton()
                    .padding(.bottom, Constants.buttonSpacing)
            }
            .padding()
            
            // Loading overlay
            if isProcessing {
                LoadingIndicator(size: 48)
                    .startAnimating()
            }
        }
        .alert(isPresented: $showingPermissionAlert) {
            Alert(
                title: Text("Camera Access Required"),
                message: Text("Please enable camera access in Settings to use this feature."),
                primaryButton: .default(Text("Settings"), action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }),
                secondaryButton: .cancel()
            )
        }
        .onChange(of: viewModel.hasPermission) { hasPermission in
            showingPermissionAlert = !hasPermission
        }
        .onAppear {
            Task {
                do {
                    try await viewModel.setupCamera()
                } catch {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    // MARK: - Camera Preview
    
    private func cameraPreview() -> some View {
        GeometryReader { geometry in
            ZStack {
                if viewModel.hasPermission {
                    CameraPreviewLayer(session: viewModel.captureSession)
                        .aspectRatio(Constants.previewAspectRatio, contentMode: .fit)
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.width * Constants.previewAspectRatio
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(
                            color: FounditureColors.surface.opacity(0.15),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                } else {
                    Color.black
                        .overlay(
                            Text("Camera access required")
                                .foregroundColor(.white)
                        )
                }
            }
        }
    }
    
    // MARK: - Capture Button
    
    private func captureButton() -> some View {
        FounditureButton(
            title: "Capture",
            style: .primary,
            size: .large,
            isEnabled: viewModel.hasPermission && !isProcessing,
            isLoading: isProcessing
        ) {
            Task {
                do {
                    isProcessing = true
                    
                    // Provide haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // Capture and process image
                    let processedImage = try await viewModel.captureImage()
                    capturedImage = processedImage.image
                    showingImagePreview = true
                    
                    // Success feedback
                    let successGenerator = UINotificationFeedbackGenerator()
                    successGenerator.notificationOccurred(.success)
                    
                } catch {
                    // Error feedback
                    let errorGenerator = UINotificationFeedbackGenerator()
                    errorGenerator.notificationOccurred(.error)
                    
                    // Display error message
                    if let errorMessage = viewModel.errorMessage {
                        withAnimation {
                            // Show error toast or alert
                            print(errorMessage)
                        }
                    }
                }
                
                isProcessing = false
            }
        }
        .accessibilityLabel("Capture furniture image")
        .accessibilityHint("Double tap to take a photo")
    }
}

// MARK: - Camera Preview Layer

/// UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer
private struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

#if DEBUG
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
#endif