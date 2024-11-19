//
// UserDefaultsManager.swift
// Founditure
//
// Human Tasks:
// 1. Verify UserDefaults suite name matches app's bundle identifier in production
// 2. Confirm all sensitive data is stored in Keychain instead of UserDefaults
// 3. Review default synchronization behavior impact on app performance
//

import Foundation // Latest
import Core.Constants.AppConstants

// MARK: - UserDefaults Keys
/// Addresses requirement: 2.3.2 Data Storage Solutions
/// Defines available storage keys for consistent data access across the app
enum UserDefaultsKeys: String {
    case lastSyncTimestamp
    case userPreferences
    case listingFilters
    case cameraSettings
    case mapSettings
    case notificationSettings
    case themeMode
    
    var key: String {
        return rawValue
    }
}

// MARK: - UserDefaults Manager
/// Addresses requirements:
/// - 2.3.2 Data Storage Solutions: Implement local storage for app preferences
/// - 1.3 Scope/Implementation Boundaries: Support data persistence on iOS 14+
final class UserDefaultsManager {
    
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = UserDefaultsManager()
    
    /// UserDefaults instance for persistent storage
    private let defaults: UserDefaults
    
    /// Suite name for UserDefaults domain
    private let suiteName: String
    
    // MARK: - Initialization
    
    private init() {
        self.suiteName = App.bundleIdentifier
        
        // Initialize UserDefaults with app's suite name for isolated storage
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            // Fallback to standard UserDefaults if suite creation fails
            self.defaults = UserDefaults.standard
            assertionFailure("Failed to create UserDefaults with suite name: \(suiteName)")
            return
        }
        
        self.defaults = defaults
        
        // Enable immediate synchronization for data persistence
        defaults.synchronize()
    }
    
    // MARK: - Public Methods
    
    /// Sets a value in UserDefaults for the specified key
    /// - Parameters:
    ///   - value: The value to store
    ///   - key: The UserDefaultsKeys enum case specifying the storage key
    func setValue(_ value: Any, for key: UserDefaultsKeys) {
        defaults.set(value, forKey: key.key)
        
        // Ensure immediate synchronization
        if !defaults.synchronize() {
            assertionFailure("Failed to synchronize UserDefaults after setting value for key: \(key)")
        }
    }
    
    /// Retrieves a value from UserDefaults for the specified key
    /// - Parameter key: The UserDefaultsKeys enum case specifying the storage key
    /// - Returns: The stored value if it exists, nil otherwise
    func getValue(for key: UserDefaultsKeys) -> Any? {
        return defaults.object(forKey: key.key)
    }
    
    /// Removes a value from UserDefaults for the specified key
    /// - Parameter key: The UserDefaultsKeys enum case specifying the storage key
    func removeValue(for key: UserDefaultsKeys) {
        defaults.removeObject(forKey: key.key)
        
        // Ensure immediate synchronization after removal
        if !defaults.synchronize() {
            assertionFailure("Failed to synchronize UserDefaults after removing value for key: \(key)")
        }
    }
    
    /// Removes all stored values from UserDefaults for the app's domain
    func clearAll() {
        // Get all stored keys
        guard let domain = defaults.persistentDomain(forName: suiteName) else {
            return
        }
        
        // Remove persistent domain for complete cleanup
        defaults.removePersistentDomain(forName: suiteName)
        
        // Verify cleanup
        if defaults.persistentDomain(forName: suiteName) != nil {
            assertionFailure("Failed to clear UserDefaults persistent domain")
        }
        
        // Ensure immediate synchronization
        if !defaults.synchronize() {
            assertionFailure("Failed to synchronize UserDefaults after clearing all values")
        }
    }
}