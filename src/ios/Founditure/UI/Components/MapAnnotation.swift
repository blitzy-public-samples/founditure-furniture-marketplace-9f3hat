// SwiftUI framework - Latest
import SwiftUI
// MapKit framework - Latest
import MapKit

/// Human Tasks:
/// 1. Verify map annotation performance with large datasets
/// 2. Review accessibility requirements for map annotations
/// 3. Test annotation interaction on different device sizes
/// 4. Configure proper map annotation clustering settings

/// A custom map annotation view for displaying furniture listings
/// Requirements addressed:
/// - Location-based discovery (1.2): Interactive map annotations for furniture discovery
/// - Map View Integration (3.1.2): Interactive annotations for location visualization
public struct MapAnnotation: View, MapAnnotationProtocol {
    // MARK: - Properties
    
    /// The furniture listing associated with this annotation
    private let listing: Listing
    
    /// Whether the annotation is currently selected
    private let isSelected: Bool
    
    /// Closure to handle tap events on the annotation
    private let onTap: (Listing) -> Void
    
    // MARK: - Computed Properties
    
    /// The geographic coordinate for the annotation's position
    public var coordinate: CLLocationCoordinate2D {
        listing.location.coordinates
    }
    
    // MARK: - Initialization
    
    /// Creates a new map annotation view
    /// - Parameters:
    ///   - listing: The furniture listing to display
    ///   - isSelected: Whether the annotation is selected
    ///   - onTap: Handler for tap gestures
    public init(listing: Listing, isSelected: Bool, onTap: @escaping (Listing) -> Void) {
        self.listing = listing
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    // MARK: - View Body
    
    public var body: some View {
        VStack(spacing: 4) {
            // Condition indicator circle
            Circle()
                .fill(conditionColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            
            // Listing title
            Text(listing.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .onTapGesture {
            onTap(listing)
        }
    }
    
    // MARK: - Private Methods
    
    /// Returns the appropriate color based on furniture condition
    private var conditionColor: Color {
        switch listing.condition {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .orange
        case .poor:
            return .red
        }
    }
}

// MARK: - MapAnnotationProtocol Extension

extension MapAnnotation {
    /// Provides the annotation's visual representation
    /// Requirements addressed:
    /// - Map View Integration (3.1.2): Condition-based visual styling
    public var annotationImage: Image {
        Image(systemName: "mappin.circle.fill")
            .foregroundColor(conditionColor)
            .scaleEffect(isSelected ? 1.2 : 1.0)
    }
}