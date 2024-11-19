// Foundation framework - Latest
import Foundation
// Combine framework - Latest
import Combine
// SwiftUI framework - Latest
import SwiftUI

/// Human Tasks:
/// 1. Configure proper error logging for message delivery failures
/// 2. Set up analytics tracking for message interactions
/// 3. Review message list pagination requirements with team
/// 4. Configure proper message caching strategy

/// ViewModel responsible for managing the message list screen state and business logic
/// Requirements addressed:
/// - Real-time messaging (1.3 Scope/Core Features): Real-time message updates and delivery status tracking
/// - Push notification system (1.3 Scope/Core Features): Message delivery and status updates
@MainActor
@Observable
final class MessageListViewModel {
    // MARK: - Private Properties
    
    private let messageService: MessageService
    private let userService: UserService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    
    private(set) var messages: [Message] = []
    private(set) var state: MessageListState = .loading
    private var selectedListingId: UUID?
    
    // MARK: - Initialization
    
    /// Initializes the message list view model with required services
    /// - Parameters:
    ///   - messageService: Service for handling message operations
    ///   - userService: Service for accessing user information
    init(messageService: MessageService, userService: UserService) {
        self.messageService = messageService
        self.userService = userService
    }
    
    // MARK: - Public Methods
    
    /// Loads messages for the selected listing and sets up real-time updates
    /// Requirements addressed:
    /// - Real-time messaging (1.3 Scope/Core Features): Message loading and real-time updates
    func loadMessages(listingId: UUID) async {
        do {
            // Update selected listing
            self.selectedListingId = listingId
            
            // Set loading state
            state = .loading
            
            // Fetch initial messages
            let fetchedMessages = try await messageService.fetchMessages(listingId: listingId)
            
            // Update messages array
            messages = fetchedMessages.sorted { $0.sentAt > $1.sentAt }
            
            // Setup real-time subscription
            setupMessageSubscription(listingId: listingId)
            
            // Update state to loaded
            state = .loaded
            
            // Mark unread messages as read
            await markMessagesAsRead()
            
        } catch {
            state = .error(error)
        }
    }
    
    /// Marks unread messages as read using MessageService
    /// Requirements addressed:
    /// - Real-time messaging (1.3 Scope/Core Features): Message status tracking
    func markMessagesAsRead() async {
        guard let currentUser = userService.getCurrentUser() else { return }
        
        // Filter unread messages where current user is receiver
        let unreadMessages = messages.filter { message in
            message.status != .read && 
            message.receiverId == currentUser.id.uuidString
        }
        
        // Mark each message as read
        for message in unreadMessages {
            do {
                try await messageService.markAsRead(messageId: message.id)
                
                // Update local message status
                if let index = messages.firstIndex(where: { $0.id == message.id }) {
                    messages[index].markAsRead()
                }
            } catch {
                print("Failed to mark message as read: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up real-time message subscription for listing updates
    /// Requirements addressed:
    /// - Real-time messaging (1.3 Scope/Core Features): Real-time message updates
    private func setupMessageSubscription(listingId: UUID) {
        // Cancel existing subscriptions
        cancellables.removeAll()
        
        // Subscribe to message updates
        messageService.subscribeToMessages(listingId: listingId)
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                
                // Update existing message or add new one
                if let index = self.messages.firstIndex(where: { $0.id == message.id }) {
                    self.messages[index] = message
                } else {
                    self.messages.append(message)
                }
                
                // Sort messages by sent timestamp
                self.messages.sort { $0.sentAt > $1.sentAt }
                
                // Mark message as read if user is receiver
                if message.receiverId == self.userService.getCurrentUser()?.id.uuidString {
                    Task {
                        await self.markMessagesAsRead()
                    }
                }
            }
            .store(in: &cancellables)
    }
}