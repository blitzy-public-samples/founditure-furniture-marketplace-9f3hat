// Foundation framework - Latest
import Foundation
// Combine framework - Latest
import Combine

/// Human Tasks:
/// 1. Configure push notification certificates for message delivery
/// 2. Set up proper monitoring for message delivery failures
/// 3. Configure message retention policy with operations team
/// 4. Review and adjust message delivery timeout thresholds

/// MessageEndpoint: API endpoints for message operations
/// Requirements addressed:
/// - Real-time messaging (1.3 Scope/Core Features): Define message API endpoints
private enum MessageEndpoint: APIEndpoint {
    case send
    case fetch
    case markDelivered
    case markRead
    
    var path: String {
        switch self {
        case .send:
            return "/messages"
        case .fetch:
            return "/messages"
        case .markDelivered:
            return "/messages/delivered"
        case .markRead:
            return "/messages/read"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .send:
            return .post
        case .fetch:
            return .get
        case .markDelivered, .markRead:
            return .put
        }
    }
    
    var headers: [String: String]? {
        return nil
    }
    
    var body: Encodable? {
        return nil
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
}

/// MessageService: Service class managing real-time messaging functionality
/// Requirements addressed:
/// - Real-time messaging (1.3 Scope/Core Features): Implement message delivery and status tracking
/// - Push notification system (1.3 Scope/Core Features): Handle message delivery notifications
@MainActor
public final class MessageService {
    // MARK: - Private Properties
    
    private let apiClient: APIClient
    private let messageSubject = PassthroughSubject<Message, Never>()
    private var activeSubscriptions: Set<UUID> = []
    
    // MARK: - Initialization
    
    /// Initializes the message service with required dependencies
    /// - Parameter apiClient: API client for network requests
    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    // MARK: - Public Methods
    
    /// Sends a new message to another user
    /// Requirements addressed:
    /// - Real-time messaging (1.3 Scope/Core Features): Message sending functionality
    public func sendMessage(content: String, receiverId: String, listingId: UUID) async throws -> Message {
        struct SendMessageRequest: Codable {
            let content: String
            let receiverId: String
            let listingId: UUID
        }
        
        let request = SendMessageRequest(
            content: content,
            receiverId: receiverId,
            listingId: listingId
        )
        
        var endpoint = MessageEndpoint.send
        endpoint.body = request
        
        let message = try await apiClient.request(endpoint)
        messageSubject.send(message)
        
        return message
    }
    
    /// Fetches messages for a specific listing
    /// Requirements addressed:
    /// - Real-time messaging (1.3 Scope/Core Features): Message retrieval functionality
    public func fetchMessages(listingId: UUID) async throws -> [Message] {
        var endpoint = MessageEndpoint.fetch
        endpoint.queryItems = [URLQueryItem(name: "listingId", value: listingId.uuidString)]
        
        let messages = try await apiClient.request(endpoint)
        return messages.sorted { $0.sentAt > $1.sentAt }
    }
    
    /// Marks a message as delivered
    /// Requirements addressed:
    /// - Real-time messaging (1.3 Scope/Core Features): Message delivery status tracking
    public func markAsDelivered(messageId: UUID) async throws {
        struct DeliveryRequest: Codable {
            let messageId: UUID
            let deliveredAt: Date
        }
        
        var endpoint = MessageEndpoint.markDelivered
        endpoint.body = DeliveryRequest(
            messageId: messageId,
            deliveredAt: Date()
        )
        
        let updatedMessage = try await apiClient.request(endpoint)
        updatedMessage.markAsDelivered()
        messageSubject.send(updatedMessage)
    }
    
    /// Marks a message as read
    /// Requirements addressed:
    /// - Real-time messaging (1.3 Scope/Core Features): Message read status tracking
    public func markAsRead(messageId: UUID) async throws {
        struct ReadRequest: Codable {
            let messageId: UUID
            let readAt: Date
        }
        
        var endpoint = MessageEndpoint.markRead
        endpoint.body = ReadRequest(
            messageId: messageId,
            readAt: Date()
        )
        
        let updatedMessage = try await apiClient.request(endpoint)
        updatedMessage.markAsRead()
        messageSubject.send(updatedMessage)
    }
    
    /// Subscribes to real-time message updates for a specific listing
    /// Requirements addressed:
    /// - Real-time messaging (1.3 Scope/Core Features): Real-time message updates
    public func subscribeToMessages(listingId: UUID) -> AnyPublisher<Message, Never> {
        activeSubscriptions.insert(listingId)
        
        return messageSubject
            .filter { $0.listingId == listingId }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Deinitialization
    
    deinit {
        activeSubscriptions.removeAll()
    }
}