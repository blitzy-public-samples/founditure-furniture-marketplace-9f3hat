//
// PermissionManager.swift
// Founditure
//
// Human Tasks:
// 1. Verify notification authorization options match app requirements
// 2. Confirm location accuracy settings align with battery optimization goals
// 3. Review privacy usage description strings in Info.plist
// 4. Validate permission handling flows with UX team
//

import Foundation     // Latest
import CoreLocation  // Latest
import AVFoundation  // Latest
import Photos        // Latest
import UserNotifications  // Latest

// Relative import from Core/Constants
import AppConstants

// MARK: - Permission Enums

/// Addresses requirement: Core Features - Handle permissions for camera, location services, and push notifications
public enum PermissionType {
    case camera
    case location
    case notification
    case photoLibrary
}

/// Addresses requirement: Security Controls - Implement secure permission handling and user privacy controls
public enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
    case restricted
}

// MARK: - Permission Manager

/// Addresses requirement: Device Support - Support iOS 14+ devices with appropriate permission handling
@MainActor
public final class PermissionManager: NSObject {
    
    // MARK: - Properties
    
    private let locationManager: CLLocationManager
    private let notificationCenter: UNUserNotificationCenter
    private let notificationsEnabled: Bool
    
    /// Singleton instance for centralized permission management
    public static let shared = PermissionManager()
    
    // MARK: - Initialization
    
    private override init() {
        self.locationManager = CLLocationManager()
        self.notificationCenter = UNUserNotificationCenter.current()
        self.notificationsEnabled = Features.enablePushNotifications
        
        super.init()
        
        // Configure location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // MARK: - Camera Permission
    
    /// Addresses requirement: Core Features - Handle permissions for camera
    public func requestCameraPermission() async throws -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .authorized : .denied
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        @unknown default:
            return .denied
        }
    }
    
    // MARK: - Location Permission
    
    /// Addresses requirement: Core Features - Handle permissions for location services
    public func requestLocationPermission() async throws -> PermissionStatus {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Wait for delegate callback
            return await withCheckedContinuation { continuation in
                Task { @MainActor in
                    // Wait for a short duration to allow delegate to process
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    let newStatus = self.convertLocationAuthStatus(locationManager.authorizationStatus)
                    continuation.resume(returning: newStatus)
                }
            }
        default:
            return convertLocationAuthStatus(status)
        }
    }
    
    // MARK: - Notification Permission
    
    /// Addresses requirement: Core Features - Handle permissions for push notifications
    public func requestNotificationPermission() async throws -> PermissionStatus {
        guard notificationsEnabled else {
            return .denied
        }
        
        let settings = await notificationCenter.notificationSettings()
        
        switch settings.authorizationStatus {
        case .notDetermined:
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await notificationCenter.requestAuthorization(options: options)
            return granted ? .authorized : .denied
        case .denied:
            return .denied
        case .authorized, .provisional, .ephemeral:
            return .authorized
        @unknown default:
            return .denied
        }
    }
    
    // MARK: - Photo Library Permission
    
    /// Addresses requirement: Security Controls - Implement secure permission handling
    public func requestPhotoLibraryPermission() async throws -> PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return convertPhotoAuthStatus(status)
        default:
            return convertPhotoAuthStatus(status)
        }
    }
    
    // MARK: - Permission Status Check
    
    /// Addresses requirement: Security Controls - Implement user privacy controls
    public func checkPermissionStatus(permissionType: PermissionType) -> PermissionStatus {
        switch permissionType {
        case .camera:
            return convertCameraAuthStatus(AVCaptureDevice.authorizationStatus(for: .video))
        case .location:
            return convertLocationAuthStatus(locationManager.authorizationStatus)
        case .notification:
            let settings = Task {
                await notificationCenter.notificationSettings()
            }
            return convertNotificationAuthStatus(settings.value?.authorizationStatus ?? .notDetermined)
        case .photoLibrary:
            return convertPhotoAuthStatus(PHPhotoLibrary.authorizationStatus(for: .readWrite))
        }
    }
    
    // MARK: - Status Conversion Helpers
    
    private func convertCameraAuthStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }
    
    private func convertLocationAuthStatus(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }
    
    private func convertNotificationAuthStatus(_ status: UNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized, .provisional, .ephemeral: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }
    
    private func convertPhotoAuthStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized, .limited: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension PermissionManager: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Handle authorization changes if needed
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle location errors if needed
    }
}