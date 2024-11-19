// SwiftUI framework - Latest
import SwiftUI
// Kingfisher framework - 7.0+
import Kingfisher

// Internal imports
import "../../../Models/Listing"
import "../Theme/Colors"
import "../Theme/Typography"

/// Human Tasks:
/// 1. Verify image caching configuration with Kingfisher for optimal performance
/// 2. Test dynamic font scaling across all device sizes
/// 3. Validate color contrast ratios in both light and dark modes
/// 4. Review haptic feedback intensity with UX team
/// 5. Test distance calculation accuracy with location services team

/// A reusable card component that displays furniture listing information
/// Requirements addressed:
/// - Visual Hierarchy (3.1.1): Material Design 3 with 8dp grid system and elevation levels
/// - Component Library (3.1.1): Custom Design System with atomic design principles
/// - Responsive Design (3.1.1): Mobile-First with flexible grid layouts and adaptive typography
struct ListingCard: View {
    // MARK: - Properties
    
    private let listing: Listing
    private let userLocation: Location?
    private let onTap: (Listing) -> Void
    private let cornerRadius: CGFloat
    private let elevation: CGFloat
    
    // MARK: - Initialization
    
    init(
        listing: Listing,
        userLocation: Location? = nil,
        onTap: @escaping (Listing) -> Void
    ) {
        self.listing = listing
        self.userLocation = userLocation
        self.onTap = onTap
        self.cornerRadius = 12 // MD3 medium component radius
        self.elevation = 2 // MD3 default elevation
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            // Provide haptic feedback on tap
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onTap(listing)
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Listing Image
                if let firstImageUrl = listing.imageUrls.first {
                    KFImage(URL(string: firstImageUrl))
                        .placeholder {
                            Rectangle()
                                .foregroundColor(FounditureColors.surface)
                        }
                        .resizable()
                        .aspectRatio(4/3, contentMode: .fill)
                        .clipped()
                        .cornerRadius(cornerRadius)
                }
                
                // Listing Title
                Text(listing.title)
                    .font(FounditureTypography.title3)
                    .foregroundColor(FounditureColors.onSurface)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    // Condition Badge
                    Text(listing.condition.rawValue.capitalized)
                        .font(FounditureTypography.caption)
                        .foregroundColor(FounditureColors.onSurface)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            FounditureColors.surface
                                .opacity(0.8)
                                .cornerRadius(8)
                        )
                    
                    // Distance (if available)
                    if let userLocation = userLocation {
                        Text(formatDistance(from: userLocation))
                            .font(FounditureTypography.caption)
                            .foregroundColor(FounditureColors.onSurface.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Status Badge (if not active)
                    if listing.status != .active {
                        Text(listing.status.rawValue.capitalized)
                            .font(FounditureTypography.caption)
                            .foregroundColor(FounditureColors.onSurface)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                FounditureColors.accent
                                    .opacity(0.2)
                                    .cornerRadius(8)
                            )
                    }
                }
            }
            .padding(16)
            .background(
                FounditureColors.surface
                    .cornerRadius(cornerRadius)
                    .shadow(
                        color: FounditureColors.onSurface.opacity(0.1),
                        radius: elevation * 2,
                        x: 0,
                        y: elevation
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    /// Formats the distance to a user-friendly string
    /// - Parameter location: User's current location
    /// - Returns: Formatted distance string
    private func formatDistance(from location: Location) -> String {
        let distance = listing.distanceFrom(location)
        
        if distance < 1000 {
            return String(format: "%.0f m away", distance)
        } else {
            let kilometers = distance / 1000
            return String(format: "%.1f km away", kilometers)
        }
    }
}