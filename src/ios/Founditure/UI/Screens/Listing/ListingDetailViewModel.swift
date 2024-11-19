// Foundation framework - Latest
import Foundation
// Combine framework - Latest
import Combine
// SwiftUI framework - Latest
import SwiftUI

/// Human Tasks:
/// 1. Configure proper error logging for listing status changes
/// 2. Set up monitoring for message delivery failures
/// 3. Review message update frequency with performance team
/// 4. Configure proper retry mechanisms for failed network requests
/// 5. Verify proper cleanup of message subscriptions

/// ViewModel managing the listing detail screen state and business logic with real-time updates
/// Requirements addressed:
/// - Location-based discovery (1.2): Location-based furniture discovery
/// - Real-time messaging (1.2): Real-time messaging between users
/// - Data Types (1.3): Furniture listings, user profiles, messages
@MainActor
public final class ListingDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var listing: Listing?
    @Published private(set) var messages: [Message] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    private let listingService: ListingService
    private let messageService: MessageService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the view model with required services
    /// - Parameters:
    ///   - listingService: Service for listing operations
    ///   - messageService: Service for messaging functionality
    public init(listingService: ListingService, messageService: MessageService) {
        self.listingService = listingService
        self.messageService = messageService
    }
    
    // MARK: - Public Methods
    
    /// Loads the listing details and initializes real-time message subscription
    /// Requirements addressed:
    /// - Location-based discovery (1.2): Fetch listing details
    /// - Real-time messaging (1.2): Initialize message subscription
    public func loadListing(listingId: UUID) async throws {
        isLoading = true
        error = nil
        
        do {
            // Fetch listing details
            listing = try await listingService.getListing(listingId)
            
            // Fetch existing messages
            messages = try await messageService.fetchMessages(listingId: listingId)
            
            // Subscribe to real-time message updates
            messageService.subscribeToMessages(listingId: listingId)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] message in
                    self?.handleNewMessage(message)
                }
                .store(in: &cancellables)
            
            // Check if listing is expired
            if let listing = listing, listing.isExpired() {
                try await updateListingStatus(.expired)
            }
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Sends a message about the listing
    /// Requirements addressed:
    /// - Real-time messaging (1.2): Message sending functionality
    public func sendMessage(_ content: String) async throws {
        guard let listing = listing else {
            throw APIError.invalidRequest("Listing not found")
        }
        
        do {
            let message = try await messageService.sendMessage(
                content: content,
                receiverId: listing.userId.uuidString,
                listingId: listing.id
            )
            
            // Update local messages array
            await MainActor.run {
                messages.append(message)
                messages.sort { $0.sentAt > $1.sentAt }
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Updates the status of the listing
    /// Requirements addressed:
    /// - Data Types (1.3): Listing lifecycle management
    public func updateListingStatus(_ newStatus: ListingStatus) async throws {
        guard let listing = listing else {
            throw APIError.invalidRequest("Listing not found")
        }
        
        do {
            let updatedListing = try await listingService.updateListingStatus(listing.id, status: newStatus)
            
            await MainActor.run {
                self.listing = updatedListing
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles new incoming messages
    private func handleNewMessage(_ message: Message) {
        // Add new message if not already present
        if !messages.contains(message) {
            messages.append(message)
            messages.sort { $0.sentAt > $1.sentAt }
            
            // Mark message as delivered
            Task {
                try? await messageService.markAsDelivered(messageId: message.id)
            }
        }
    }
    
    // MARK: - Deinitialization
    
    deinit {
        cancellables.removeAll()
    }
}