// SwiftUI framework - Latest
import SwiftUI
// MapKit framework - Latest
import MapKit
// CoreLocation framework - Latest
import CoreLocation

// Internal imports with relative paths
import "../Components/ListingCard"
import "../Components/MapAnnotation"
import "./MapViewModel"

/// Human Tasks:
/// 1. Verify proper location permission handling in Info.plist
/// 2. Test map performance with large numbers of annotations
/// 3. Review map interaction gestures with UX team
/// 4. Configure map clustering settings for optimal performance
/// 5. Validate search radius limits with business requirements

/// Main view for the map screen implementing location-based furniture discovery
/// Requirements addressed:
/// - Location-based discovery (1.2): Location-based furniture discovery
/// - Geographic Boundaries (1.3): Major urban centers in North America
/// - Map View Integration (3.1.2): Map-based furniture item discovery and location visualization
struct MapView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = MapViewModel()
    @State private var selectedListing: Listing?
    @State private var showingListingDetail = false
    @State private var searchRadius: Double = 5.0 // Initial 5km radius
    
    // MARK: - View Body
    
    var body: some View {
        ZStack {
            // Map content
            mapContent()
                .ignoresSafeArea()
            
            // Search radius control overlay
            searchRadiusOverlay()
                .padding()
                .frame(maxHeight: .infinity, alignment: .top)
            
            // Selected listing overlay
            if let listing = selectedListing {
                selectedListingOverlay(listing: listing)
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: selectedListing)
            }
            
            // Loading indicator
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .onAppear {
            Task {
                try? await viewModel.startLocationUpdates()
            }
        }
    }
    
    // MARK: - Map Content
    
    private func mapContent() -> some View {
        Map(coordinateRegion: $viewModel.mapRegion,
            showsUserLocation: true,
            annotationItems: viewModel.nearbyListings) { listing in
            MapAnnotation(
                listing: listing,
                isSelected: selectedListing?.id == listing.id
            ) { tappedListing in
                withAnimation {
                    if selectedListing?.id == tappedListing.id {
                        showingListingDetail = true
                    } else {
                        selectedListing = tappedListing
                    }
                }
            }
        }
        .mapStyle(.standard)
        .gesture(
            DragGesture()
                .onEnded { _ in
                    // Deselect listing when map is dragged
                    withAnimation {
                        selectedListing = nil
                    }
                }
        )
    }
    
    // MARK: - Search Radius Overlay
    
    private func searchRadiusOverlay() -> some View {
        VStack(spacing: 8) {
            Text("Search Radius: \(Int(searchRadius))km")
                .font(.headline)
                .foregroundColor(.primary)
            
            Slider(
                value: $searchRadius,
                in: 1...50,
                step: 1
            ) { editing in
                if !editing {
                    Task {
                        viewModel.updateSearchRadius(searchRadius * 1000) // Convert to meters
                    }
                }
            }
            .tint(FounditureColors.primary)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(FounditureColors.surface)
                    .shadow(
                        color: FounditureColors.onSurface.opacity(0.1),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FounditureColors.surface.opacity(0.9))
                .shadow(
                    color: FounditureColors.onSurface.opacity(0.2),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
    
    // MARK: - Selected Listing Overlay
    
    private func selectedListingOverlay(listing: Listing) -> some View {
        VStack {
            Spacer()
            
            ListingCard(
                listing: listing,
                userLocation: viewModel.userLocation
            ) { tappedListing in
                showingListingDetail = true
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(FounditureColors.surface)
                    .shadow(
                        color: FounditureColors.onSurface.opacity(0.2),
                        radius: 12,
                        x: 0,
                        y: -6
                    )
            )
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        if gesture.translation.height > 50 {
                            withAnimation {
                                selectedListing = nil
                            }
                        }
                    }
            )
        }
        .sheet(isPresented: $showingListingDetail) {
            // Navigation to listing detail view would be implemented here
            // This is left as a stub since the detail view is not in scope
            Text("Listing Detail View")
        }
    }
}