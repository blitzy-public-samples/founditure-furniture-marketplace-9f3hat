//
// AppConstants.swift
// Founditure
//
// Human Tasks:
// 1. Verify the API base URL matches the production environment configuration
// 2. Review security constants with the security team before deployment
// 3. Confirm cache size limits are appropriate for target devices
// 4. Validate location update interval with battery optimization requirements
//

import Foundation  // Latest
import CoreGraphics  // Latest

// MARK: - API Configuration
/// Addresses requirement: 3.3.1 API Architecture - Define standardized API configurations
struct API {
    /// Base URL for all API endpoints with version prefix
    static let baseURL = "https://api.founditure.com/v1"
    
    /// Default timeout interval for network requests in seconds
    static let timeout: TimeInterval = 30.0
}

// MARK: - App Configuration
/// Addresses requirement: 1.3 Scope/Implementation Boundaries - Support iOS 14+ devices
struct App {
    /// Minimum supported iOS version
    static let minimumIOSVersion = 14.0
    
    /// Application bundle identifier
    static let bundleIdentifier = "com.founditure.app"
}

// MARK: - UI Configuration
/// Addresses requirement: 3.1.1 Design Specifications - Implement consistent UI constants
struct UI {
    /// Default duration for UI animations in seconds
    static let defaultAnimationDuration: TimeInterval = 0.3
    
    /// Standard corner radius for UI elements
    static let cornerRadius: CGFloat = 8.0
}

// MARK: - Location Configuration
/// Addresses requirement: 1.2 System Overview - Configure location-based discovery services
struct Location {
    /// Default search radius for furniture discovery in kilometers
    static let defaultSearchRadius: Double = 5.0
    
    /// Interval between location updates in seconds (5 minutes)
    static let locationUpdateInterval: TimeInterval = 300.0
}

// MARK: - Camera Configuration
struct Camera {
    /// Maximum allowed image size in bytes (10MB)
    static let maxImageSize: Int = 10_485_760
    
    /// JPEG compression quality for furniture photos (0.0 to 1.0)
    static let compressionQuality: CGFloat = 0.8
}

// MARK: - Security Configuration
/// Addresses requirement: 5.3.2 Security Controls - Implement security configuration constants
struct Security {
    /// Minimum required password length for user accounts
    static let minimumPasswordLength: Int = 8
    
    /// Authentication token expiration interval in seconds (1 hour)
    static let tokenExpirationInterval: TimeInterval = 3600
}

// MARK: - Feature Flags
struct Features {
    /// Enable gamification features throughout the app
    static let enableGamification = true
    
    /// Enable push notification functionality
    static let enablePushNotifications = true
}

// MARK: - Cache Configuration
struct Cache {
    /// Maximum disk space allocated for caching in bytes (100MB)
    static let maxDiskSpace: Int = 100_485_760
    
    /// Cache expiration interval in seconds (24 hours)
    static let expirationInterval: TimeInterval = 86400
}