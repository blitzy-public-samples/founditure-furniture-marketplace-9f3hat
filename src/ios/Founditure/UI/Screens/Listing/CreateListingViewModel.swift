// Foundation framework - Latest
import Foundation
// Combine framework - Latest
import Combine
// CoreLocation framework - Latest
import CoreLocation

/// Human Tasks:
/// 1. Configure proper error logging for listing creation failures
/// 2. Set up monitoring for image processing performance
/// 3. Verify location permission handling in production environment
/// 4. Review image compression settings for different network conditions
/// 5. Configure proper retry mechanisms for failed listing submissions

/// ViewModel responsible for managing furniture listing creation with AI recognition
/// Requirements addressed:
/// - AI-powered furniture recognition (1.2): Implements furniture recognition and categorization
/// - Location-based discovery (1.2): Handles location-based features
/// - Data Types (1.3): Manages furniture listing data
@MainActor
public final class CreateListingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var isLoading: Bool = false
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var category: FurnitureCategory = .other
    @Published var condition: FurnitureCondition = .good
    @Published var selectedImages: [UIImage] = []
    @Published private(set) var recognizedCategory: FurnitureCategory?
    @Published private(set) var error: Error?
    
    // MARK: - Private Properties
    
    private let listingService: ListingService
    private let imageProcessor: ImageProcessor
    private let locationManager: CLLocationManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the view model with required services
    /// Requirements addressed:
    /// - AI-powered furniture recognition (1.2): Sets up image processing service
    /// - Location-based discovery (1.2): Configures location services
    public init(listingService: ListingService, imageProcessor: ImageProcessor) {
        self.listingService = listingService
        self.imageProcessor = imageProcessor
        self.locationManager = CLLocationManager()
        
        setupLocationManager()
    }
    
    // MARK: - Public Methods
    
    /// Adds and processes a new image with AI recognition
    /// Requirements addressed:
    /// - AI-powered furniture recognition (1.2): Processes images for furniture recognition
    public func addImage(_ image: UIImage) async throws {
        isLoading = true
        error = nil
        
        do {
            // Process image and perform AI recognition
            let processedImage = try await imageProcessor.processImage(image)
            
            // Update recognized category if confidence is high enough
            if processedImage.recognitionResult.confidence > 0.7 {
                if let category = FurnitureCategory(rawValue: processedImage.recognitionResult.category.lowercased()) {
                    self.recognizedCategory = category
                    self.category = category
                }
            }
            
            // Add processed image to selected images
            selectedImages.append(image)
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Removes an image from the selected images array
    public func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
        
        // Reset recognized category if no images remain
        if selectedImages.isEmpty {
            recognizedCategory = nil
            category = .other
        }
    }
    
    /// Creates a new furniture listing with current data
    /// Requirements addressed:
    /// - Data Types (1.3): Creates furniture listing with complete data
    /// - Location-based discovery (1.2): Includes location data in listing
    public func createListing() async throws {
        guard validateInput() else {
            throw ValidationError.invalidInput
        }
        
        isLoading = true
        error = nil
        
        do {
            // Get current location
            guard let location = locationManager.location else {
                throw LocationError.locationUnavailable
            }
            
            // Create location object
            let listingLocation = Location(
                coordinates: location.coordinate,
                address: "Current Location", // Would be reverse geocoded in production
                country: "United States",
                postalCode: "00000"
            )
            
            // Process all images
            let processedImages = try await selectedImages.map { image in
                try await imageProcessor.processImage(image)
            }
            
            // Create listing
            _ = try await listingService.createListing(
                title: title,
                description: description,
                category: category,
                condition: condition,
                location: listingLocation,
                images: processedImages.map { $0.image.jpegData(compressionQuality: 0.8) ?? Data() }
            )
            
            // Clear form on success
            clearForm()
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func validateInput() -> Bool {
        guard !title.isEmpty,
              !description.isEmpty,
              !selectedImages.isEmpty,
              locationManager.authorizationStatus != .denied else {
            return false
        }
        return true
    }
    
    private func clearForm() {
        title = ""
        description = ""
        category = .other
        condition = .good
        selectedImages.removeAll()
        recognizedCategory = nil
    }
}

// MARK: - Error Types

private enum ValidationError: LocalizedError {
    case invalidInput
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Please fill in all required fields and add at least one image"
        }
    }
}

private enum LocationError: LocalizedError {
    case locationUnavailable
    
    var errorDescription: String? {
        switch self {
        case .locationUnavailable:
            return "Unable to determine current location"
        }
    }
}