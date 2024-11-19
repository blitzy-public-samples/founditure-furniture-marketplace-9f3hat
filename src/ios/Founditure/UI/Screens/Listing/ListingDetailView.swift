// SwiftUI framework - Latest
import SwiftUI
// Kingfisher framework - 7.0+
import Kingfisher

// Internal imports
import "../../../Models/Listing"
import "./ListingDetailViewModel"
import "../../Components/FounditureButton"

/// Human Tasks:
/// 1. Configure proper image caching policies for listing images
/// 2. Verify accessibility labels for image gallery navigation
/// 3. Test VoiceOver support for real-time message updates
/// 4. Review haptic feedback patterns with UX team
/// 5. Validate dynamic type scaling across all text elements

/// SwiftUI view displaying detailed information about a furniture listing
/// Requirements addressed:
/// - Location-based discovery (1.2): Location-based furniture discovery
/// - Real-time messaging (1.2): Real-time messaging between users
/// - Visual Hierarchy (3.1.1): Material Design 3 with 8dp grid system
struct ListingDetailView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: ListingDetailViewModel
    @State private var messageText: String = ""
    @State private var showingImageGallery: Bool = false
    @State private var selectedImageIndex: Int = 0
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    
    init(listingId: UUID) {
        _viewModel = StateObject(wrappedValue: ListingDetailViewModel(
            listingService: ListingService(apiClient: APIClient()),
            messageService: MessageService(apiClient: APIClient())
        ))
        
        // Load listing data
        Task {
            try? await viewModel.loadListing(listingId: listingId)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else if let listing = viewModel.listing {
                    VStack(alignment: .leading, spacing: 24) {
                        imageGallerySection(images: listing.imageUrls)
                        listingDetailsSection(listing: listing)
                        messagingSection
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingImageGallery) {
            imageGalleryFullscreen
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Loading listing details...")
                .font(FounditureTypography.dynamicFont(style: .body, size: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Error loading listing")
                .font(FounditureTypography.dynamicFont(style: .headline, size: .medium))
            
            Text(error.localizedDescription)
                .font(FounditureTypography.dynamicFont(style: .body, size: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            FounditureButton(
                title: "Try Again",
                style: .primary,
                action: {
                    Task {
                        try? await viewModel.loadListing(listingId: viewModel.listing?.id ?? UUID())
                    }
                }
            )
        }
        .padding()
    }
    
    // MARK: - Image Gallery Section
    
    private func imageGallerySection(images: [String]) -> some View {
        VStack(spacing: 8) {
            TabView(selection: $selectedImageIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, imageUrl in
                    KFImage(URL(string: imageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(height: 300)
                        .clipped()
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        .tag(index)
                        .onTapGesture {
                            selectedImageIndex = index
                            showingImageGallery = true
                        }
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .frame(height: 300)
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<images.count, id: \.self) { index in
                    Circle()
                        .fill(index == selectedImageIndex ? Color.primary : Color.secondary)
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
    
    // MARK: - Listing Details Section
    
    private func listingDetailsSection(listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and status
            HStack {
                Text(listing.title)
                    .font(FounditureTypography.dynamicFont(style: .title2, size: .medium))
                
                Spacer()
                
                statusBadge(status: listing.status)
            }
            
            // Description
            Text(listing.description)
                .font(FounditureTypography.dynamicFont(style: .body, size: .medium))
                .foregroundColor(.secondary)
            
            // Condition and category
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Condition")
                        .font(FounditureTypography.dynamicFont(style: .caption, size: .medium))
                        .foregroundColor(.secondary)
                    Text(listing.condition.rawValue.capitalized)
                        .font(FounditureTypography.dynamicFont(style: .body, size: .medium))
                }
                
                VStack(alignment: .leading) {
                    Text("Category")
                        .font(FounditureTypography.dynamicFont(style: .caption, size: .medium))
                        .foregroundColor(.secondary)
                    Text(listing.category.rawValue.capitalized)
                        .font(FounditureTypography.dynamicFont(style: .body, size: .medium))
                }
            }
            
            // Location
            VStack(alignment: .leading, spacing: 4) {
                Text("Location")
                    .font(FounditureTypography.dynamicFont(style: .caption, size: .medium))
                    .foregroundColor(.secondary)
                Text(listing.location.formattedAddress())
                    .font(FounditureTypography.dynamicFont(style: .body, size: .medium))
            }
            
            // Action buttons
            HStack(spacing: 16) {
                FounditureButton(
                    title: "Contact Seller",
                    style: .primary,
                    action: {
                        // Scroll to messaging section
                        withAnimation {
                            // Implement scroll to messages
                        }
                    }
                )
                
                if listing.status == .active {
                    FounditureButton(
                        title: "Mark as Collected",
                        style: .secondary,
                        action: {
                            Task {
                                try? await viewModel.updateListingStatus(.collected)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Messaging Section
    
    private var messagingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Messages")
                .font(FounditureTypography.dynamicFont(style: .headline, size: .medium))
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                    }
                }
            }
            .frame(maxHeight: 300)
            
            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                FounditureButton(
                    title: "Send",
                    style: .primary,
                    size: .small,
                    isEnabled: !messageText.isEmpty,
                    action: {
                        Task {
                            try? await viewModel.sendMessage(messageText)
                            messageText = ""
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func statusBadge(status: ListingStatus) -> some View {
        let (backgroundColor, textColor): (Color, Color) = {
            switch status {
            case .active:
                return (.green.opacity(0.2), .green)
            case .pending:
                return (.yellow.opacity(0.2), .yellow)
            case .collected:
                return (.blue.opacity(0.2), .blue)
            case .expired:
                return (.red.opacity(0.2), .red)
            }
        }()
        
        return Text(status.rawValue.capitalized)
            .font(FounditureTypography.dynamicFont(style: .caption, size: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(8)
    }
    
    private var imageGalleryFullscreen: some View {
        TabView(selection: $selectedImageIndex) {
            ForEach(Array(viewModel.listing?.imageUrls.enumerated() ?? [].enumerated()), id: \.offset) { index, imageUrl in
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFit()
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

// MARK: - Message Bubble View

private struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromUser(UserDefaults.standard.string(forKey: "userId") ?? "") {
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.content)
                    .font(FounditureTypography.dynamicFont(style: .body, size: .medium))
                    .padding(12)
                    .background(message.isFromUser(UserDefaults.standard.string(forKey: "userId") ?? "") ? Color.blue : Color.secondary.opacity(0.2))
                    .foregroundColor(message.isFromUser(UserDefaults.standard.string(forKey: "userId") ?? "") ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.sentAt.formatted(date: .abbreviated, time: .shortened))
                    .font(FounditureTypography.dynamicFont(style: .caption, size: .small))
                    .foregroundColor(.secondary)
            }
            
            if !message.isFromUser(UserDefaults.standard.string(forKey: "userId") ?? "") {
                Spacer()
            }
        }
    }
}