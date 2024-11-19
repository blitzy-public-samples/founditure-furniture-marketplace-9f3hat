//
// Notification.swift
// Founditure
//
// Human Tasks:
// 1. Verify push notification entitlements are enabled in Xcode capabilities
// 2. Ensure proper APNS certificates are configured in Apple Developer Portal
// 3. Test notification handling in both foreground and background states
// 4. Validate notification payload format with backend team

import Foundation // Latest
import AppConstants

/// Addresses requirement: 2.2.1 Core Components - Real-time messaging and notification system
/// Defines different types of notifications supported in the application
@objc enum NotificationType: Int, Codable {
    case newListing
    case message
    case achievement
    case listingCollected
}

/// Addresses requirement: 2.2.1 Core Components - Real-time messaging and notification system
/// Defines priority levels for notification delivery and display
@objc enum NotificationPriority: Int, Codable {
    case low
    case normal
    case high
}

/// Addresses requirements:
/// - 2.2.1 Core Components - Real-time messaging and notification system
/// - 1.2 System Overview - 70% monthly active user retention through engagement features
@objc class Notification: NSObject, Codable {
    // MARK: - Properties
    let id: UUID
    let title: String
    let body: String
    let type: NotificationType
    let priority: NotificationPriority
    let createdAt: Date
    var isRead: Bool
    var metadata: [String: Any]?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case body
        case type
        case priority
        case createdAt
        case isRead
        case metadata
    }
    
    // MARK: - Initialization
    init(title: String, body: String, type: NotificationType, priority: NotificationPriority, metadata: [String: Any]? = nil) {
        guard Features.enablePushNotifications else {
            fatalError("Push notifications are disabled in app configuration")
        }
        
        self.id = UUID()
        self.title = title
        self.body = body
        self.type = type
        self.priority = priority
        self.createdAt = Date()
        self.isRead = false
        self.metadata = metadata
        
        super.init()
    }
    
    // MARK: - Codable Implementation
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        type = try container.decode(NotificationType.self, forKey: .type)
        priority = try container.decode(NotificationPriority.self, forKey: .priority)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        isRead = try container.decode(Bool.self, forKey: .isRead)
        
        // Handle metadata dictionary specially since it contains Any type
        if let metadataDict = try container.decodeIfPresent([String: String].self, forKey: .metadata) {
            metadata = metadataDict as [String: Any]
        } else {
            metadata = nil
        }
        
        super.init()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(body, forKey: .body)
        try container.encode(type, forKey: .type)
        try container.encode(priority, forKey: .priority)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(isRead, forKey: .isRead)
        
        // Encode metadata only if it contains string values
        if let metadata = metadata as? [String: String] {
            try container.encode(metadata, forKey: .metadata)
        }
    }
    
    // MARK: - Public Methods
    /// Marks the notification as read
    func markAsRead() {
        isRead = true
    }
}