// SwiftUI framework - Latest
import SwiftUI

// Internal model and theme imports
import struct ../../Models/Achievement
import class ../Theme/Colors

/*
Human Tasks:
1. Verify accessibility labels with localization team
2. Test color contrast ratios with vision-impaired users
3. Validate animation performance on older devices
4. Review haptic feedback patterns with UX team
*/

/// A reusable achievement badge component following Material Design 3 guidelines
/// Requirements addressed:
/// - Achievement Display (3.1 User Interface Design/3.1.7 Profile/Points Screen)
/// - Visual Hierarchy (3. SYSTEM DESIGN/3.1 User Interface Design/3.1.1 Design Specifications)
/// - Gamification System (1.1 Executive Summary)
@available(iOS 14.0, *)
struct AchievementBadge: View {
    // MARK: - Properties
    
    private let achievement: Achievement
    private let showDetails: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Constants
    
    private enum Constants {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 4
        static let iconSize: CGFloat = 32
        static let spacing: CGFloat = 8
        static let progressHeight: CGFloat = 6
        static let badgeHeight: CGFloat = 80
        static let badgePadding: CGFloat = 16
        static let titleFont: Font = .headline
        static let detailFont: Font = .subheadline
        static let progressFont: Font = .caption
    }
    
    // MARK: - Initialization
    
    /// Creates a new achievement badge view
    /// - Parameters:
    ///   - achievement: The achievement to display
    ///   - showDetails: Whether to show detailed information
    init(achievement: Achievement, showDetails: Bool = false) {
        self.achievement = achievement
        self.showDetails = showDetails
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            HStack(spacing: Constants.spacing) {
                // Achievement icon based on type
                achievementIcon
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .foregroundColor(achievement.isUnlocked ? FounditureColors.success : FounditureColors.primary)
                
                VStack(alignment: .leading, spacing: Constants.spacing / 2) {
                    // Achievement title
                    Text(achievement.title)
                        .font(Constants.titleFont)
                        .foregroundColor(FounditureColors.onSurface)
                    
                    // Points value
                    Text("\(achievement.pointsValue) pts")
                        .font(Constants.detailFont)
                        .foregroundColor(FounditureColors.primary)
                }
                
                Spacer()
                
                // Unlocked indicator
                if achievement.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(FounditureColors.success)
                        .accessibility(label: Text("Achievement Unlocked"))
                }
            }
            
            // Progress indicator for locked achievements
            if !achievement.isUnlocked {
                progressView
            }
            
            // Optional detailed description
            if showDetails {
                Text(achievement.description)
                    .font(Constants.detailFont)
                    .foregroundColor(FounditureColors.onSurface)
                    .padding(.top, Constants.spacing)
            }
        }
        .padding(Constants.badgePadding)
        .frame(minHeight: Constants.badgeHeight)
        .background(FounditureColors.surface)
        .cornerRadius(Constants.cornerRadius)
        .shadow(
            color: Color.black.opacity(0.1),
            radius: Constants.shadowRadius,
            x: 0,
            y: 2
        )
        .accessibilityElement(children: .combine)
        .accessibility(label: Text("\(achievement.title) Achievement"))
        .accessibility(value: Text(achievement.isUnlocked ? "Unlocked" : "\(Int(achievement.progressPercentage()))% Complete"))
        .accessibility(hint: Text(showDetails ? achievement.description : ""))
    }
    
    // MARK: - Private Views
    
    /// Achievement type icon with Material Design 3 styling
    private var achievementIcon: some View {
        Group {
            switch achievement.type {
            case .firstFind:
                Image(systemName: "star.fill")
            case .quickCollector:
                Image(systemName: "bolt.fill")
            case .superSaver:
                Image(systemName: "trophy.fill")
            }
        }
        .imageScale(.large)
        .accessibility(hidden: true)
    }
    
    /// Progress indicator with Material Design 3 styling
    private var progressView: some View {
        VStack(spacing: Constants.spacing / 2) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: Constants.progressHeight / 2)
                        .fill(FounditureColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.progressHeight / 2)
                                .stroke(FounditureColors.primary.opacity(0.2), lineWidth: 1)
                        )
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: Constants.progressHeight / 2)
                        .fill(FounditureColors.primary)
                        .frame(width: geometry.size.width * CGFloat(achievement.progressPercentage() / 100))
                }
            }
            .frame(height: Constants.progressHeight)
            .animation(.spring(), value: achievement.progressPercentage())
            
            // Progress percentage
            Text("\(Int(achievement.progressPercentage()))%")
                .font(Constants.progressFont)
                .foregroundColor(FounditureColors.primary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibility(hidden: true)
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct AchievementBadge_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Unlocked achievement
            AchievementBadge(
                achievement: Achievement(
                    id: "1",
                    title: "First Find",
                    description: "Found your first furniture item",
                    pointsValue: 50,
                    requiredValue: 1,
                    type: .firstFind
                ),
                showDetails: true
            )
            
            // In-progress achievement
            AchievementBadge(
                achievement: Achievement(
                    id: "2",
                    title: "Quick Collector",
                    description: "Collect 5 items within 24 hours",
                    pointsValue: 100,
                    requiredValue: 5,
                    type: .quickCollector
                ),
                showDetails: false
            )
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
#endif