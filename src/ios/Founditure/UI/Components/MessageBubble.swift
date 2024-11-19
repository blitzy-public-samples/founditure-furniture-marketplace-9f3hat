// SwiftUI framework - Latest
import SwiftUI

/// Human Tasks:
/// 1. Verify contrast ratios meet WCAG requirements in both light and dark modes
/// 2. Test message bubble layout with different text lengths and screen sizes
/// 3. Validate accessibility labels and voice-over support
/// 4. Review animation performance on older devices

/// A SwiftUI view component that renders chat message bubbles with Material Design 3 styling
/// Requirements addressed:
/// - Real-time messaging (1.3 Scope/Core Features): Visual distinction between sent and received messages
/// - Visual Hierarchy (3.1.1 Design Specifications): Material Design 3 with dynamic color system
struct MessageBubble: View {
    // MARK: - Properties
    
    /// The message to display
    private let message: Message
    
    /// ID of the current user for determining message direction
    private let currentUserId: String
    
    /// Current color scheme for dynamic theming
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Constants
    
    private enum Constants {
        static let bubblePadding: CGFloat = 16
        static let bubbleCornerRadius: CGFloat = 12
        static let maxBubbleWidth: CGFloat = 280
        static let statusIconSize: CGFloat = 16
        static let bubbleSpacing: CGFloat = 8
        static let messageFont: Font = .body
    }
    
    // MARK: - Initialization
    
    /// Initializes a new MessageBubble view
    /// - Parameters:
    ///   - message: The message to display
    ///   - currentUserId: ID of the current user
    init(message: Message, currentUserId: String) {
        self.message = message
        self.currentUserId = currentUserId
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .bottom, spacing: Constants.bubbleSpacing) {
            if message.isFromUser(currentUserId) {
                Spacer(minLength: Constants.bubbleSpacing)
                messageBubbleContent
                    .accessibilityLabel("Sent message: \(message.content)")
            } else {
                messageBubbleContent
                    .accessibilityLabel("Received message: \(message.content)")
                Spacer(minLength: Constants.bubbleSpacing)
            }
        }
        .padding(.horizontal, Constants.bubblePadding)
    }
    
    // MARK: - Private Views
    
    /// Content view for the message bubble
    private var messageBubbleContent: some View {
        VStack(alignment: message.isFromUser(currentUserId) ? .trailing : .leading, spacing: 4) {
            Text(message.content)
                .font(Constants.messageFont)
                .foregroundColor(textColor)
                .fixedSize(horizontal: false, vertical: true)
                .padding(Constants.bubblePadding)
                .background(
                    RoundedRectangle(cornerRadius: Constants.bubbleCornerRadius)
                        .fill(bubbleColor)
                )
                .frame(maxWidth: Constants.maxBubbleWidth, alignment: message.isFromUser(currentUserId) ? .trailing : .leading)
            
            if message.isFromUser(currentUserId) {
                messageStatus
            }
        }
    }
    
    /// Status indicator for sent messages
    private var messageStatus: some View {
        HStack(spacing: 4) {
            switch message.status {
            case .sent:
                Image(systemName: "checkmark")
                    .accessibilityLabel("Message sent")
            case .delivered:
                Image(systemName: "checkmark.circle")
                    .accessibilityLabel("Message delivered")
            case .read:
                Image(systemName: "checkmark.circle.fill")
                    .accessibilityLabel("Message read")
            }
        }
        .font(.caption2)
        .foregroundColor(.secondary)
        .frame(height: Constants.statusIconSize)
    }
    
    // MARK: - Private Methods
    
    /// Determines the bubble background color based on sender and theme
    /// Requirements addressed:
    /// - Visual Hierarchy (3.1.1): Material Design 3 color system with WCAG compliance
    private var bubbleColor: Color {
        if message.isFromUser(currentUserId) {
            return FounditureColors.primary
                .adjustedForTheme(colorScheme: colorScheme == .light ? .light : .dark)
        } else {
            return FounditureColors.surface
                .adjustedForTheme(colorScheme: colorScheme == .light ? .light : .dark)
        }
    }
    
    /// Determines the text color based on bubble background color
    /// Requirements addressed:
    /// - Visual Hierarchy (3.1.1): WCAG compliant contrast ratios
    private var textColor: Color {
        if message.isFromUser(currentUserId) {
            return .white
        } else {
            return colorScheme == .light ? .black : .white
        }
    }
}