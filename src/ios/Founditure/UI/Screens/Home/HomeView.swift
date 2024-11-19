// SwiftUI framework - Latest
import SwiftUI

// Internal imports
import "../../../Core/Network/APIError"
import "../Components/ListingCard"
import "../Theme/Colors"
import "./HomeViewModel"

/// Human Tasks:
/// 1. Verify pull-to-refresh animation smoothness across devices
/// 2. Test location permission handling with different authorization states
/// 3. Review loading state transitions with UX team
/// 4. Validate error alert messaging with content team
/// 5. Test scroll performance with large listing datasets

/// HomeView: Main view for displaying nearby furniture listings
/// Requirements addressed:
/// - Location-based discovery (1.2): Real-time furniture discovery with location updates
/// - Visual Hierarchy (3.1.1): Material Design 3 with 8dp grid system
/// - Responsive Design (3.1.1): Mobile-First with adaptive layouts
struct HomeView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: HomeViewModel
    @State private var isRefreshing = false
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Constants
    
    private enum Constants {
        static let gridSpacing: CGFloat = 16
        static let contentPadding: CGFloat = 16
        static let loadingOpacity: Double = 0.6
        static let errorDisplayDuration: Double = 3.0
    }
    
    // MARK: - Initialization
    
    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                FounditureColors.background
                    .ignoresSafeArea()
                
                // Main Content
                ScrollView {
                    RefreshControl(isRefreshing: $isRefreshing) {
                        await handleRefresh()
                    }
                    
                    LazyVStack(spacing: Constants.gridSpacing) {
                        // Listings Grid
                        ForEach(viewModel.nearbyListings, id: \.id) { listing in
                            ListingCard(
                                listing: listing,
                                userLocation: viewModel.currentLocation
                            ) { selectedListing in
                                // Handle listing selection
                                handleListingSelection(selectedListing)
                            }
                            .padding(.horizontal, Constants.contentPadding)
                        }
                    }
                    .padding(.vertical, Constants.contentPadding)
                }
                .opacity(viewModel.isLoading ? Constants.loadingOpacity : 1)
                
                // Loading Indicator
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(
                            tint: FounditureColors.primary
                        ))
                }
                
                // Error Alert
                if let error = viewModel.error {
                    ErrorAlert(error: error) {
                        await handleRefresh()
                    }
                }
            }
            .navigationTitle("Nearby Furniture")
            .navigationBarTitleDisplayMode(.large)
        }
        .accentColor(FounditureColors.primary)
        .onAppear {
            Task {
                await handleRefresh()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Handles pull-to-refresh action
    private func handleRefresh() async {
        isRefreshing = true
        await viewModel.refreshListings()
        isRefreshing = false
    }
    
    /// Handles listing selection
    private func handleListingSelection(_ listing: Listing) {
        // Implement navigation to listing detail
        // Note: Navigation implementation will be handled by the navigation coordinator
    }
}

// MARK: - Supporting Views

/// Custom refresh control with Material Design styling
private struct RefreshControl: View {
    @Binding var isRefreshing: Bool
    let action: () async -> Void
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.frame(in: .global).minY > 0 {
                Spacer()
                    .frame(height: geometry.size.height)
                    .clipped()
                    .refreshable {
                        await action()
                    }
            }
        }
    }
}

/// Error alert view with Material Design 3 styling
private struct ErrorAlert: View {
    let error: Error
    let retryAction: () async -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Error")
                .font(FounditureTypography.headline)
                .foregroundColor(FounditureColors.error)
            
            Text(error.localizedDescription)
                .font(FounditureTypography.body)
                .foregroundColor(FounditureColors.onSurface)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await retryAction()
                }
            }) {
                Text("Retry")
                    .font(FounditureTypography.body)
                    .foregroundColor(FounditureColors.onPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(FounditureColors.primary)
                    .cornerRadius(8)
            }
        }
        .padding(24)
        .background(
            FounditureColors.surface
                .cornerRadius(12)
                .shadow(
                    color: FounditureColors.onSurface.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .padding(.horizontal, 32)
    }
}

// MARK: - Preview Provider

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let mockViewModel = HomeViewModel(
            listingService: MockListingService(),
            locationService: MockLocationService()
        )
        
        HomeView(viewModel: mockViewModel)
            .preferredColorScheme(.light)
        
        HomeView(viewModel: mockViewModel)
            .preferredColorScheme(.dark)
    }
}
#endif