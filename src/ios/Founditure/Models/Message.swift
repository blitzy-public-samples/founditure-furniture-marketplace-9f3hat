// Foundation framework - Latest
import Foundation

/// Human Tasks:
/// 1. Configure proper data encryption for message content at rest
/// 2. Set up monitoring for message delivery status changes
/// 3. Configure proper logging for message lifecycle events
/// 4. Review message expiration policy with business team

// MARK: - MessageStatus Enum
/// Represents the delivery status of a message
/// Requirements addressed:
/// - Real-time messaging (1.3 Scope/Core Features): Delivery status tracking
public enum MessageStatus: String, Codable {
    case sent
    case delivered
    case read
}

// MARK: - Message Class
/// Core model representing a message in the real-time messaging system
/// Requirements addressed:
/// - Real-time messaging (1.3 Scope/Core Features): Message delivery status tracking and timestamps
/// - Community Communication (1.1 Executive Summary): Structured messaging system between users
@objc
@objcMembers
public final class Message: Codable {
    // MARK: - Properties
    
    /// Unique identifier for the message
    public let id: UUID
    
    /// Identifier of the user who sent the message
    public let senderId: String
    
    /// Identifier of the user who receives the message
    public let receiverId: String
    
    /// Identifier of the furniture listing this message relates to
    public let listingId: UUID
    
    /// Content of the message
    public let content: String
    
    /// Current delivery status of the message
    public private(set) var status: MessageStatus
    
    /// Timestamp when the message was sent
    public let sentAt: Date
    
    /// Timestamp when the message was delivered (if applicable)
    public private(set) var deliveredAt: Date?
    
    /// Timestamp when the message was read (if applicable)
    public private(set) var readAt: Date?
    
    // MARK: - Initialization
    
    /// Initializes a new Message instance
    /// Requirements addressed:
    /// - Real-time messaging (1.3 Scope/Core Features): Message creation with timestamps
    public init(senderId: String, receiverId: String, listingId: UUID, content: String) {
        self.id = UUID()
        self.senderId = senderId
        self.receiverId = receiverId
        self.listingId = listingId
        self.content = content.sanitized // Sanitize content using String extension
        self.status = .sent
        self.sentAt = Date()
        self.deliveredAt = nil
        self.readAt = nil
    }
    
    // MARK: - Public Methods
    
    /// Marks the message as delivered and updates delivery timestamp
    /// Requirements addressed:
    /// - Real-time messaging (1.3 Scope/Core Features): Delivery status tracking
    public func markAsDelivered() {
        guard status == .sent else { return }
        status = .delivered
        deliveredAt = Date()
    }
    
    /// Marks the message as read and updates read timestamp
    /// Requirements addressed:
    /// - Real-time messaging (1.3 Scope/Core Features): Message status tracking
    public func markAsRead() {
        guard status == .delivered else { return }
        status = .read
        readAt = Date()
    }
    
    /// Checks if the message is from a specific user
    /// Requirements addressed:
    /// - Community Communication (1.1 Executive Summary): User message identification
    public func isFromUser(_ userId: String) -> Bool {
        return senderId == userId
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case id
        case senderId
        case receiverId
        case listingId
        case content
        case status
        case sentAt
        case deliveredAt
        case readAt
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        senderId = try container.decode(String.self, forKey: .senderId)
        receiverId = try container.decode(String.self, forKey: .receiverId)
        listingId = try container.decode(UUID.self, forKey: .listingId)
        content = try container.decode(String.self, forKey: .content)
        status = try container.decode(MessageStatus.self, forKey: .status)
        sentAt = try container.decode(Date.self, forKey: .sentAt)
        deliveredAt = try container.decodeIfPresent(Date.self, forKey: .deliveredAt)
        readAt = try container.decodeIfPresent(Date.self, forKey: .readAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(receiverId, forKey: .receiverId)
        try container.encode(listingId, forKey: .listingId)
        try container.encode(content, forKey: .content)
        try container.encode(status, forKey: .status)
        try container.encode(sentAt, forKey: .sentAt)
        try container.encodeIfPresent(deliveredAt, forKey: .deliveredAt)
        try container.encodeIfPresent(readAt, forKey: .readAt)
    }
}

// MARK: - Message Extensions

extension Message: Equatable {
    public static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Message: Identifiable {}