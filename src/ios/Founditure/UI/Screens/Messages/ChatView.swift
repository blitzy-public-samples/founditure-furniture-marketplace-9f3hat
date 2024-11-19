// SwiftUI framework - Latest
import SwiftUI

/// Human Tasks:
/// 1. Verify VoiceOver support with accessibility team
/// 2. Test message input with different keyboard types
/// 3. Review animation performance on older devices
/// 4. Validate color contrast ratios in both themes
/// 5. Test chat scrolling behavior with large message history

/// ChatView: Main chat interface for real-time messaging between users
/// Requirements addressed:
/// - Real-time messaging (1.3 Scope/Core Features): Implements real-time messaging with delivery status
/// - Visual Hierarchy (3.1.1 Design Specifications): Material Design 3 with dynamic color system
/// - Accessibility (3.1.1 Design Specifications): WCAG 2.1 AA compliant with screen reader support
struct ChatView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Constants
    
    private enum Constants {
        static let messageSpacing: CGFloat = 8
        static let inputHeight: CGFloat = 56
        static let inputPadding: CGFloat = 16
        static let inputCornerRadius: CGFloat = 12
        static let maxInputLines: Int = 5
        static let loadingSize: CGFloat = 32
    }
    
    // MARK: - Initialization
    
    init(listingId: UUID, receiverId: String) {
        let viewModel = ChatViewModel(
            messageService: MessageService(apiClient: APIClient()),
            listingId: listingId,
            receiverId: receiverId
        )
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            messageList
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Message history")
            
            messageInput
                .background(FounditureColors.surface)
        }
        .background(FounditureColors.background)
        .overlay(loadingOverlay)
        .task {
            try? await viewModel.loadMessages()
        }
    }
    
    // MARK: - Message List
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Constants.messageSpacing) {
                    ForEach(viewModel.messages, id: \.id) { message in
                        MessageBubble(message: message, currentUserId: viewModel.receiverId)
                            .id(message.id)
                            .transition(.opacity)
                    }
                }
                .padding(.vertical, Constants.inputPadding)
            }
            .onChange(of: viewModel.messages) { messages in
                withAnimation {
                    if let lastMessage = messages.first {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
        .accessibilityAction(named: "Scroll to bottom") {
            if let lastMessage = viewModel.messages.first {
                withAnimation {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Message Input
    
    private var messageInput: some View {
        HStack(spacing: Constants.inputPadding) {
            TextField("Type a message...", text: $viewModel.messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...Constants.maxInputLines)
                .padding(Constants.inputPadding)
                .background(
                    RoundedRectangle(cornerRadius: Constants.inputCornerRadius)
                        .fill(FounditureColors.surface)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .focused($isInputFocused)
                .accessibilityLabel("Message input field")
            
            Button(action: {
                Task {
                    try? await viewModel.sendMessage()
                    isInputFocused = false
                }
            }) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(FounditureColors.primary)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(FounditureColors.surface)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
            }
            .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send message")
            .accessibilityHint("Double tap to send your message")
        }
        .padding(Constants.inputPadding)
        .background(FounditureColors.surface)
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        Group {
            if viewModel.isLoading {
                LoadingIndicator(size: Constants.loadingSize)
                    .accessibilityLabel("Loading messages")
            }
        }
    }
}

// MARK: - Preview Provider

#Preview {
    ChatView(
        listingId: UUID(),
        receiverId: "preview-user-id"
    )
}