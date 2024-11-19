// XCTest framework - Latest
import XCTest
// SwiftUI framework - Latest
import SwiftUI
// Combine framework - Latest
import Combine
@testable import Founditure

/// Human Tasks:
/// 1. Verify proper test coverage for all camera states and transitions
/// 2. Configure appropriate test timeouts for async operations
/// 3. Review mock data values for realistic test scenarios
/// 4. Set up proper cleanup of test resources and memory management

/// Requirements addressed:
/// - AI-powered furniture recognition (1.2): Verify camera capture and AI-powered furniture recognition functionality
/// - Core Features (1.3): Test AI-powered furniture recognition and categorization implementation

@MainActor
final class CameraViewModelTests: XCTestCase {
    // MARK: - Properties
    
    private var sut: CameraViewModel!
    private var mockImageProcessor: MockImageProcessor!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        mockImageProcessor = MockImageProcessor()
        sut = CameraViewModel(imageProcessor: mockImageProcessor)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockImageProcessor = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() throws {
        // Verify initial camera state
        XCTAssertEqual(sut.state, .ready, "Initial state should be ready")
        XCTAssertFalse(sut.hasPermission, "Initial permission should be false")
        XCTAssertNil(sut.errorMessage, "Initial error message should be nil")
        XCTAssertNil(sut.lastProcessedImage, "Initial processed image should be nil")
    }
    
    // MARK: - Image Capture Tests
    
    func testImageCapture() async throws {
        // Given
        let testImage = UIImage()
        let expectation = XCTestExpectation(description: "Image capture completion")
        
        // When
        Task {
            do {
                _ = try await sut.captureImage()
                expectation.fulfill()
            } catch {
                XCTFail("Image capture failed: \(error)")
            }
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(mockImageProcessor.processImageCalled, "Process image should be called")
        XCTAssertNotNil(sut.lastProcessedImage, "Last processed image should be set")
        XCTAssertEqual(sut.state, .ready, "State should return to ready after successful capture")
    }
    
    func testImageCaptureFailure() async throws {
        // Given
        class FailingImageProcessor: MockImageProcessor {
            override func processImage(_ image: UIImage) async throws -> ProcessedImage {
                throw ImageProcessingError.processingFailed
            }
        }
        
        sut = CameraViewModel(imageProcessor: FailingImageProcessor())
        
        // When
        do {
            _ = try await sut.captureImage()
            XCTFail("Should throw an error")
        } catch {
            // Then
            XCTAssertEqual(sut.state, .error, "State should be error after failure")
            XCTAssertNotNil(sut.errorMessage, "Error message should be set")
            XCTAssertNil(sut.lastProcessedImage, "Last processed image should remain nil")
        }
    }
    
    // MARK: - Furniture Recognition Tests
    
    func testFurnitureRecognition() async throws {
        // Given
        let expectedCategory = "chair"
        let expectedConfidence: Float = 0.95
        
        // When
        let expectation = XCTestExpectation(description: "Furniture recognition completion")
        
        Task {
            do {
                let result = try await sut.captureImage()
                XCTAssertEqual(result.recognitionResult.category, expectedCategory, "Should recognize furniture category")
                XCTAssertEqual(result.recognitionResult.confidence, expectedConfidence, "Should have expected confidence")
                expectation.fulfill()
            } catch {
                XCTFail("Furniture recognition failed: \(error)")
            }
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(mockImageProcessor.recognizeFurnitureCalled, "Recognize furniture should be called")
        XCTAssertEqual(sut.state, .ready, "State should return to ready after recognition")
    }
    
    // MARK: - State Transition Tests
    
    func testStateTransitionsDuringCapture() async throws {
        // Given
        var stateTransitions: [CameraState] = []
        let expectation = XCTestExpectation(description: "State transitions")
        
        // When
        let cancellable = sut.$state.sink { state in
            stateTransitions.append(state)
            if state == .ready && stateTransitions.count > 1 {
                expectation.fulfill()
            }
        }
        
        try await sut.captureImage()
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertEqual(stateTransitions, [.ready, .capturing, .processing, .ready], "Should follow expected state transitions")
        cancellable.cancel()
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorMessageHandling() async throws {
        // Given
        class ErrorThrowingProcessor: MockImageProcessor {
            override func processImage(_ image: UIImage) async throws -> ProcessedImage {
                throw ImageProcessingError.processingFailed
            }
        }
        
        sut = CameraViewModel(imageProcessor: ErrorThrowingProcessor())
        
        // When
        do {
            _ = try await sut.captureImage()
            XCTFail("Should throw an error")
        } catch {
            // Then
            XCTAssertNotNil(sut.errorMessage, "Error message should be set")
            XCTAssertEqual(sut.state, .error, "State should be error")
        }
    }
}

// MARK: - Mock Image Processor Implementation
private class MockImageProcessor: ImageProcessor {
    var processImageCalled = false
    var recognizeFurnitureCalled = false
    
    override func processImage(_ image: UIImage) async throws -> ProcessedImage {
        processImageCalled = true
        return ProcessedImage(
            image: image,
            recognitionResult: FurnitureRecognitionResult(
                category: "chair",
                confidence: 0.95,
                attributes: [:]
            ),
            metadata: [:]
        )
    }
    
    override func recognizeFurniture(_ image: UIImage) async throws -> FurnitureRecognitionResult {
        recognizeFurnitureCalled = true
        return FurnitureRecognitionResult(
            category: "chair",
            confidence: 0.95,
            attributes: [:]
        )
    }
}