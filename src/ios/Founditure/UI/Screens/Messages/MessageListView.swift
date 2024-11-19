// SwiftUI framework - Latest
import SwiftUI

/// Human Tasks:
/// 1. Configure push notification permissions for message delivery
/// 2. Test message list scrolling performance with large datasets
/// 3. Verify accessibility labels with VoiceOver enabled
/// 4. Review message list refresh intervals with UX team

/// MessageListView: SwiftUI view displaying a list of message conversations
/// Requirements addressed:
/// - Real-time messaging (1.3 Scope/Core Features): Real-time message list with delivery status
/// - Visual Hierarchy (3.1.1 Design Specifications): Material Design 3 implementation
/// - Responsive Design (3.1.1 Design Specifications): Adaptive layouts for iOS devices
struct MessageListView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = ChatViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var isShowingNewMessage = false
    @State private var searchText = ""
    
    // MARK: - Constants
    
    private enum Constants {
        static let listSpacing: CGFloat = 16
        static let bubblePadding: CGFloat = 12
        static let searchBarHeight: CGFloat = 44
        static let refreshThreshold: CGFloat = 50
        static let messagePreviewLength = 50
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color following Material Design 3
                FounditureColors.background
                    .adjustedForTheme(colorScheme: colorScheme == .light ? .light : .dark)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar with Material Design 3 styling
                    searchBar
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    
                    if viewModel.isLoading {
                        LoadingIndicator(size: 40)
                            .padding()
                    } else {
                        messageList
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Messages")
                        .font(.headline)
                        .foregroundColor(FounditureColors.onSurface)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    newMessageButton
                }
            }
            .sheet(isPresented: $isShowingNewMessage) {
                // New message composer view would be implemented here
                EmptyView()
            }
        }
    }
    
    // MARK: - Private Views
    
    /// Search bar with Material Design 3 styling
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search messages", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Constants.bubblePadding)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FounditureColors.surface)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Search messages")
    }
    
    /// Message list with Material Design 3 styling and animations
    private var messageList: some View {
        ScrollView {
            LazyVStack(spacing: Constants.listSpacing) {
                ForEach(viewModel.messages) { message in
                    MessageBubble(message: message, currentUserId: "currentUserId") // Replace with actual user ID
                        .transition(.opacity.combined(with: .slide))
                        .animation(.easeInOut, value: message.status)
                }
            }
            .padding()
        }
        .refreshable {
            try? await viewModel.loadMessages()
        }
    }
    
    /// New message button with Material Design 3 elevation
    private var newMessageButton: some View {
        Button(action: { isShowingNewMessage = true }) {
            Image(systemName: "square.and.pencil")
                .imageScale(.large)
                .foregroundColor(FounditureColors.primary)
                .padding(8)
                .background(
                    Circle()
                        .fill(FounditureColors.surface)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
        }
        .accessibilityLabel("New message")
    }
}

// MARK: - Preview Provider

struct MessageListView_Previews: PreviewProvider {
    static var previews: some View {
        MessageListView()
            .preferredColorScheme(.light)
        
        MessageListView()
            .preferredColorScheme(.dark)
    }
}