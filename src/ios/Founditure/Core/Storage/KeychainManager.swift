//
// KeychainManager.swift
// Founditure
//
// Human Tasks:
// 1. Verify keychain access group configuration matches provisioning profile
// 2. Confirm keychain accessibility level meets security requirements
// 3. Review keychain sharing settings if app is part of an app group
// 4. Validate keychain configuration with security team before deployment
//

import Foundation  // Latest
import Security   // Latest

// Import security constants
import struct ../Constants/AppConstants.Security

/// Defines possible errors that can occur during keychain operations
/// Addresses requirement: 5.2.1 Encryption Standards - Provide comprehensive error handling for secure storage
public enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case unexpectedStatus(OSStatus)
    case encodingError
    case decodingError
}

/// A secure storage manager for handling sensitive data using iOS Keychain Services
/// Addresses requirements:
/// - 5.1.1 Authentication Methods: Secure storage for authentication tokens
/// - 5.2.1 Encryption Standards: iOS Keychain Services implementation
/// - 5.3.2 Security Controls: Secure data storage and access controls
public final class KeychainManager {
    
    // MARK: - Properties
    
    /// Singleton instance for centralized keychain access
    public static let shared = KeychainManager()
    
    /// Service identifier for keychain items, using app's bundle identifier
    private let serviceName: String
    
    /// Access group identifier for keychain sharing between apps
    private let accessGroup: String?
    
    // MARK: - Initialization
    
    private init() {
        self.serviceName = Bundle.main.bundleIdentifier ?? "com.founditure.app"
        // Configure access group if keychain sharing is needed
        self.accessGroup = nil
    }
    
    // MARK: - Public Methods
    
    /// Saves data securely to the keychain
    /// - Parameters:
    ///   - data: The data to be stored securely
    ///   - key: Unique identifier for the stored data
    /// - Returns: Result indicating success or specific error
    public func save(data: Data, key: String) -> Result<Void, KeychainError> {
        var query = baseQuery(for: key)
        
        // Configure data protection
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        
        // Configure additional security attributes
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleAfterFirstUnlock,
            .privateKeyUsage,
            nil
        )
        query[kSecAttrAccessControl as String] = access
        
        // Attempt to add item to keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            return .success(())
        case errSecDuplicateItem:
            // Update existing item
            let updateQuery = baseQuery(for: key)
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let updateStatus = SecItemUpdate(
                updateQuery as CFDictionary,
                updateAttributes as CFDictionary
            )
            
            return updateStatus == errSecSuccess ? .success(()) : .failure(.unexpectedStatus(updateStatus))
        default:
            return .failure(.unexpectedStatus(status))
        }
    }
    
    /// Retrieves data from the keychain
    /// - Parameter key: Unique identifier for the stored data
    /// - Returns: Result containing the retrieved data or specific error
    public func retrieve(key: String) -> Result<Data, KeychainError> {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                return .failure(.decodingError)
            }
            return .success(data)
        case errSecItemNotFound:
            return .failure(.itemNotFound)
        default:
            return .failure(.unexpectedStatus(status))
        }
    }
    
    /// Deletes specific data from the keychain
    /// - Parameter key: Unique identifier for the stored data
    /// - Returns: Result indicating success or specific error
    public func delete(key: String) -> Result<Void, KeychainError> {
        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess:
            return .success(())
        case errSecItemNotFound:
            return .failure(.itemNotFound)
        default:
            return .failure(.unexpectedStatus(status))
        }
    }
    
    /// Removes all keychain items associated with the app
    /// - Returns: Result indicating success or specific error
    public func clear() -> Result<Void, KeychainError> {
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = serviceName
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess, errSecItemNotFound:
            return .success(())
        default:
            return .failure(.unexpectedStatus(status))
        }
    }
    
    // MARK: - Private Methods
    
    /// Creates a base query dictionary for keychain operations
    /// - Parameter key: Unique identifier for the keychain item
    /// - Returns: Dictionary containing base query attributes
    private func baseQuery(for key: String) -> [String: Any] {
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = serviceName
        query[kSecAttrAccount as String] = key
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Add synchronization if iCloud keychain is enabled
        query[kSecAttrSynchronizable as String] = kCFBooleanFalse
        
        return query
    }
}