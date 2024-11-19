// Foundation framework - Latest
import Foundation
// Combine framework - Latest
import Combine
// SwiftUI framework - Latest
import SwiftUI

/// Human Tasks:
/// 1. Configure proper message delivery timeout thresholds
/// 2. Set up monitoring for message delivery failures
/// 3. Review message retention policy with business team
/// 4. Verify push notification handling for background message updates

/// ChatViewModel: Manages chat screen business logic with real-time message updates
/// Requirements addressed:
/// - Real-time messaging (1.3 Scope/Core Features): Implements real-time messaging with delivery tracking
/// - Push notification system (1.3 Scope/Core Features): Handles message delivery updates
@MainActor
final class ChatViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Array of messages in the chat, sorted by timestamp
    @Published private(set) var messages: [Message] = []
    
    /// Loading state indicator
    @Published var isLoading: Bool = false
    
    /// Current message text input
    @Published var messageText: String = ""
    
    /// Current error state
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    private let messageService: MessageService
    private let listingId: UUID
    private let receiverId: String
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the chat view model with required dependencies
    /// - Parameters:
    ///   - messageService: Service for handling message operations
    ///   - listingId: ID of the listing this chat relates to
    ///   - receiverId: ID of the message recipient
    init(messageService: MessageService, listingId: UUID, receiverId: String) {
        self.messageService = messageService
        self.listingId = listingId
        self.receiverId = receiverId
        
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Loads existing messages for the chat
    /// Requirements addressed:
    /// - Real-time messaging (1.3 Scope/Core Features): Message history retrieval
    func loadMessages() async throws {
        isLoading = true
        
        do {
            let fetchedMessages = try await messageService.fetchMessages(listingId: listingId)
            messages = fetchedMessages.sorted { $0.sentAt > $1.sentAt }
            
            // Mark received messages as delivered
            for message in messages where message.status == .sent && message.receiverId == receiverId {
                try await messageService.markAsDelivered(messageId: message.id)
            }
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
        }
    }
    
    /// Sends a new message in the chat
    /// Requirements addressed:
    /// - Real-time messaging (1.3 Scope/Core Features): Message sending with delivery tracking
    func sendMessage() async throws {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let content = messageText.sanitized
        messageText = ""
        
        do {
            let message = try await messageService.sendMessage(
                content: content,
                receiverId: receiverId,
                listingId: listingId
            )
            
            // Update messages array with new message
            messages.insert(message, at: 0)
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up real-time message subscriptions
    /// Requirements addressed:
    /// - Real-time messaging (1.3 Scope/Core Features): Real-time message updates
    /// - Push notification system (1.3 Scope/Core Features): Message delivery status updates
    private func setupSubscriptions() {
        messageService.subscribeToMessages(listingId: listingId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                
                // Update existing message if found
                if let index = self.messages.firstIndex(where: { $0.id == message.id }) {
                    self.messages[index] = message
                } else {
                    // Insert new message at the beginning
                    self.messages.insert(message, at: 0)
                    
                    // Mark message as delivered if we're the receiver
                    if message.receiverId == self.receiverId {
                        Task {
                            try? await self.messageService.markAsDelivered(messageId: message.id)
                        }
                    }
                }
                
                // Keep messages sorted by timestamp
                self.messages.sort { $0.sentAt > $1.sentAt }
            }
            .store(in: &cancellables)
    }
}