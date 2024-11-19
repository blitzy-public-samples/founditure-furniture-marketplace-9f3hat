// XCTest framework - Latest
import XCTest
// UIKit framework - Latest
import UIKit
@testable import Founditure

/// Human Tasks:
/// 1. Configure test image assets in the test bundle
/// 2. Set up mock ML model responses for furniture recognition
/// 3. Verify proper cleanup of test image resources
/// 4. Configure appropriate test timeouts for async operations
/// 5. Set up proper error logging for test failures

final class ImageProcessorTests: XCTestCase {
    // MARK: - Private Properties
    
    private var sut: ImageProcessor!
    private var mockAPIClient: MockAPIClient!
    private var testImage: UIImage!
    private var testImageData: Data!
    
    // MARK: - Setup and Teardown
    
    override func setUp() async throws {
        super.setUp()
        
        // Initialize mock API client
        mockAPIClient = MockAPIClient()
        
        // Initialize ImageProcessor with mock client
        sut = ImageProcessor(apiClient: mockAPIClient)
        
        // Create test image with specific dimensions
        let size = CGSize(width: 1024, height: 768)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.gray.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        testImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Convert test image to data
        testImageData = testImage.jpegData(compressionQuality: 1.0)
        XCTAssertNotNil(testImageData, "Test image data should be created")
    }
    
    override func tearDown() async throws {
        // Reset mock API client state
        mockAPIClient = nil
        
        // Clear test instance
        sut = nil
        
        // Clear test image resources
        testImage = nil
        testImageData = nil
        
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Tests successful image processing workflow
    /// Requirements addressed:
    /// - AI-powered furniture recognition (1.2): Verify AI recognition accuracy
    /// - Image Processing (2.2.1): Validate image processing operations
    @MainActor
    func testProcessImageSuccess() async throws {
        // Configure mock API client for successful response
        mockAPIClient.uploadCalled = false
        mockAPIClient.lastUploadedData = nil
        
        // Process test image
        let result = try await sut.processImage(testImage)
        
        // Verify processed image exists
        XCTAssertNotNil(result.image, "Processed image should not be nil")
        
        // Verify image dimensions are within limits
        let maxDimension: CGFloat = 2048.0
        XCTAssertLessThanOrEqual(result.image.size.width, maxDimension, "Image width should be within limits")
        XCTAssertLessThanOrEqual(result.image.size.height, maxDimension, "Image height should be within limits")
        
        // Verify recognition results
        XCTAssertNotNil(result.recognitionResult, "Recognition result should not be nil")
        XCTAssertFalse(result.recognitionResult.category.isEmpty, "Category should not be empty")
        XCTAssertGreaterThan(result.recognitionResult.confidence, 0.5, "Confidence should be above threshold")
        
        // Verify metadata
        XCTAssertNotNil(result.metadata["originalSize"], "Original size should be recorded")
        XCTAssertNotNil(result.metadata["processedSize"], "Processed size should be recorded")
        XCTAssertNotNil(result.metadata["timestamp"], "Timestamp should be recorded")
        XCTAssertNotNil(result.metadata["compressionQuality"], "Compression quality should be recorded")
        
        // Verify API client interaction
        XCTAssertTrue(mockAPIClient.uploadCalled, "Upload should be called")
        XCTAssertNotNil(mockAPIClient.lastUploadedData, "Upload data should not be nil")
    }
    
    /// Tests furniture recognition functionality
    /// Requirements addressed:
    /// - AI-powered furniture recognition (1.2): Verify recognition accuracy and confidence
    @MainActor
    func testRecognizeFurnitureSuccess() async throws {
        // Perform furniture recognition
        let result = try await sut.recognizeFurniture(testImage)
        
        // Verify recognition result
        XCTAssertNotNil(result, "Recognition result should not be nil")
        XCTAssertFalse(result.category.isEmpty, "Category should not be empty")
        XCTAssertGreaterThan(result.confidence, 0.5, "Confidence should be above threshold")
        
        // Verify furniture attributes
        XCTAssertNotNil(result.attributes["style"], "Style should be present")
        XCTAssertNotNil(result.attributes["material"], "Material should be present")
        XCTAssertNotNil(result.attributes["confidence_score"], "Confidence score should be present")
        
        // Verify attribute values
        if let style = result.attributes["style"] as? String {
            XCTAssertFalse(style.isEmpty, "Style should not be empty")
        }
        if let material = result.attributes["material"] as? String {
            XCTAssertFalse(material.isEmpty, "Material should not be empty")
        }
        if let confidence = result.attributes["confidence_score"] as? Float {
            XCTAssertGreaterThan(confidence, 0.0, "Confidence score should be positive")
        }
    }
    
    /// Tests image optimization for upload
    /// Requirements addressed:
    /// - Image Processing (2.2.1): Verify image optimization and compression
    func testOptimizeForUploadSuccess() throws {
        // Create large test image
        let largeSize = CGSize(width: 4096, height: 3072)
        UIGraphicsBeginImageContext(largeSize)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.blue.cgColor)
        context?.fill(CGRect(origin: .zero, size: largeSize))
        let largeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        XCTAssertNotNil(largeImage, "Large test image should be created")
        
        // Optimize image
        let quality: Float = 0.8
        let optimizedData = try sut.optimizeForUpload(largeImage!, quality: quality)
        
        // Verify optimized data exists
        XCTAssertNotNil(optimizedData, "Optimized data should not be nil")
        
        // Verify compressed size
        let maxSize = 10 * 1024 * 1024 // 10MB
        XCTAssertLessThan(optimizedData.count, maxSize, "Compressed size should be under limit")
        
        // Verify image can be recreated from data
        let optimizedImage = UIImage(data: optimizedData)
        XCTAssertNotNil(optimizedImage, "Image should be recreatable from optimized data")
        
        // Verify dimensions
        XCTAssertLessThanOrEqual(optimizedImage!.size.width, 2048.0, "Width should be within limits")
        XCTAssertLessThanOrEqual(optimizedImage!.size.height, 2048.0, "Height should be within limits")
    }
    
    /// Tests error handling for invalid images
    /// Requirements addressed:
    /// - Image Processing (2.2.1): Verify error handling for invalid inputs
    func testInvalidImageError() throws {
        // Create invalid image data
        let invalidData = "invalid image data".data(using: .utf8)!
        let invalidImage = UIImage(data: invalidData)
        
        // Attempt to process invalid image
        XCTAssertThrowsError(try sut.optimizeForUpload(invalidImage!, quality: 0.8)) { error in
            // Verify correct error type
            XCTAssertTrue(error is ImageProcessingError, "Should throw ImageProcessingError")
            
            // Verify specific error case
            if let processingError = error as? ImageProcessingError {
                XCTAssertEqual(processingError, .invalidImage, "Should be invalidImage error")
            }
        }
        
        // Verify no upload attempt was made
        XCTAssertFalse(mockAPIClient.uploadCalled, "Upload should not be called for invalid image")
        XCTAssertNil(mockAPIClient.lastUploadedData, "No data should be uploaded")
    }
}

// MARK: - Mock API Client

class MockAPIClient: APIClient {
    var uploadCalled = false
    var lastUploadedData: Data?
    
    override func uploadData<T>(_ data: Data, _ endpoint: T) async throws -> T.Response where T : APIEndpoint {
        uploadCalled = true
        lastUploadedData = data
        return EmptyResponse() as! T.Response
    }
}

// MARK: - Empty Response Type

private struct EmptyResponse: Decodable {}