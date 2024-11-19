//
// LocationManager.swift
// Founditure
//
// Human Tasks:
// 1. Verify background location usage description in Info.plist
// 2. Configure location usage privacy strings in localizable files
// 3. Review battery optimization settings for background location updates
// 4. Confirm geofencing region monitoring limits for target iOS versions

import CoreLocation // Latest
import Foundation // Latest
import Combine // Latest

/// Notification posted when location is updated
let LocationUpdateNotification = Notification.Name("com.founditure.locationUpdate")

/// Addresses requirements:
/// - 1.2 System Overview/Core Features: Location-based furniture discovery with real-time updates
/// - 1.3 Scope/Implementation Boundaries: Major urban centers in North America
/// - 2.2 Component Details/2.2.1 Core Components: Location services with background updates
@MainActor
final class LocationManager: NSObject, CLLocationManagerDelegate {
    
    // MARK: - Properties
    
    /// Shared singleton instance
    private static let _shared = LocationManager()
    
    /// Core Location manager instance
    private let locationManager: CLLocationManager
    
    /// Current user location
    private(set) var currentLocation: Location?
    
    /// Publisher for location updates
    let locationPublisher = PassthroughSubject<Location, Never>()
    
    /// Flag indicating if location monitoring is active
    private(set) var isMonitoringLocation: Bool = false
    
    /// Current search radius for furniture discovery
    private(set) var searchRadius: Double
    
    // MARK: - Initialization
    
    private override init() {
        self.locationManager = CLLocationManager()
        self.searchRadius = AppConstants.Location.defaultSearchRadius
        
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .other
        
        Task {
            _ = await requestLocationPermission()
        }
    }
    
    // MARK: - Public Interface
    
    /// Returns the shared LocationManager instance
    @MainActor
    static var shared: LocationManager {
        return _shared
    }
    
    /// Starts monitoring user location updates
    func startMonitoringLocation() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
            isMonitoringLocation = true
            
            // Configure geofencing if we have a current location
            if let location = currentLocation {
                let region = CLCircularRegion(
                    center: location.coordinates,
                    radius: searchRadius * 1000, // Convert to meters
                    identifier: "FurnitureDiscoveryRegion"
                )
                region.notifyOnEntry = true
                region.notifyOnExit = true
                locationManager.startMonitoring(for: region)
            }
        default:
            Task {
                _ = await requestLocationPermission()
            }
        }
    }
    
    /// Stops monitoring user location updates
    func stopMonitoringLocation() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        
        // Remove all monitored regions
        locationManager.monitoredRegions.forEach { region in
            locationManager.stopMonitoring(for: region)
        }
        
        isMonitoringLocation = false
    }
    
    /// Updates the search radius for furniture discovery
    func updateSearchRadius(_ radius: Double) {
        guard radius > 0 else { return }
        
        searchRadius = radius
        
        // Update geofencing region if actively monitoring
        if isMonitoringLocation, let location = currentLocation {
            // Remove existing regions
            locationManager.monitoredRegions.forEach { region in
                locationManager.stopMonitoring(for: region)
            }
            
            // Create new region with updated radius
            let region = CLCircularRegion(
                center: location.coordinates,
                radius: searchRadius * 1000,
                identifier: "FurnitureDiscoveryRegion"
            )
            region.notifyOnEntry = true
            region.notifyOnExit = true
            locationManager.startMonitoring(for: region)
        }
    }
    
    /// Requests location permission from the user
    func requestLocationPermission() async -> Bool {
        let status = locationManager.authorizationStatus
        
        guard status == .notDetermined else {
            return status == .authorizedAlways || status == .authorizedWhenInUse
        }
        
        return await withCheckedContinuation { continuation in
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
            
            // Store continuation to resolve in delegate callback
            permissionContinuation = continuation
        }
    }
    
    // MARK: - Private Properties
    
    private var permissionContinuation: CheckedContinuation<Bool, Never>?
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let newLocation = Location(
            coordinates: location.coordinate,
            address: "", // Address will be reverse geocoded if needed
            country: "USA", // Default to USA for now
            postalCode: "" // Postal code will be reverse geocoded if needed
        )
        
        currentLocation = newLocation
        locationPublisher.send(newLocation)
        NotificationCenter.default.post(name: LocationUpdateNotification, object: newLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        let isAuthorized = status == .authorizedAlways || status == .authorizedWhenInUse
        
        permissionContinuation?.resume(returning: isAuthorized)
        permissionContinuation = nil
        
        if isAuthorized && !isMonitoringLocation {
            startMonitoringLocation()
        } else if !isAuthorized && isMonitoringLocation {
            stopMonitoringLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard region is CLCircularRegion else { return }
        // Handle region entry - could trigger furniture discovery refresh
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard region is CLCircularRegion else { return }
        // Handle region exit - could pause furniture discovery updates
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Region monitoring failed: \(error.localizedDescription)")
    }
}