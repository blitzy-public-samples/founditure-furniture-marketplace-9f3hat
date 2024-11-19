// SwiftUI framework - Latest
import SwiftUI

// Internal imports
import struct ../../Models/Achievement
import struct ../../Components/AchievementBadge
import class ../../Services/GamificationService

/*
Human Tasks:
1. Verify accessibility labels with localization team
2. Test color contrast ratios with vision-impaired users
3. Review animation performance on older devices
4. Validate haptic feedback patterns with UX team
*/

/// SwiftUI view displaying user achievements and points with Material Design 3 styling
/// Requirements addressed:
/// - Achievement Display (3.1 User Interface Design/3.1.7 Profile/Points Screen)
/// - Gamification System (1.1 Executive Summary)
/// - User Engagement (1.2 System Overview/Success Criteria)
@available(iOS 14.0, *)
struct AchievementsView: View {
    // MARK: - Properties
    
    @StateObject private var gamificationService = GamificationService()
    @State private var achievements: [Achievement] = []
    @State private var totalPoints: Int = 0
    @State private var isLoading: Bool = true
    private let userId: UUID
    
    // MARK: - Constants
    
    private enum Constants {
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 12
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 4
        static let titleFont: Font = .title2.bold()
        static let subtitleFont: Font = .subheadline
        static let headerFont: Font = .headline
    }
    
    // MARK: - Initialization
    
    init(userId: UUID) {
        self.userId = userId
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.spacing) {
                // Points section
                pointsSection()
                    .padding(.horizontal, Constants.padding)
                    .padding(.top, Constants.padding)
                
                // Achievements section
                achievementsSection()
                    .padding(.horizontal, Constants.padding)
            }
            .padding(.bottom, Constants.padding)
        }
        .background(Color(.systemBackground))
        .task {
            await loadAchievements()
        }
        .refreshable {
            await loadAchievements()
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Achievements and Points")
    }
    
    // MARK: - Private Methods
    
    /// Loads user achievements and points data
    /// Requirements addressed:
    /// - Achievement Display (3.1 User Interface Design/3.1.7 Profile/Points Screen)
    private func loadAchievements() async {
        isLoading = true
        
        do {
            async let achievementsTask = gamificationService.getUserAchievements(userId: userId)
            async let pointsTask = gamificationService.getUserPoints(userId: userId)
            
            let (fetchedAchievements, fetchedPoints) = try await (achievementsTask, pointsTask)
            
            withAnimation(.easeInOut) {
                achievements = fetchedAchievements
                totalPoints = fetchedPoints
                isLoading = false
            }
        } catch {
            // Handle error state
            isLoading = false
        }
    }
    
    /// Creates the points summary section with Material Design 3 styling
    /// Requirements addressed:
    /// - Achievement Display (3.1 User Interface Design/3.1.7 Profile/Points Screen)
    private func pointsSection() -> some View {
        VStack(spacing: Constants.spacing) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.title)
                    .foregroundColor(.primary)
                    .accessibility(hidden: true)
                
                Text("Total Points")
                    .font(Constants.titleFont)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(totalPoints)")
                    .font(Constants.titleFont)
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Total Points: \(totalPoints)")
            
            // Points description
            Text("Earn points by completing achievements")
                .font(Constants.subtitleFont)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Points are earned by completing achievements")
        }
        .padding(Constants.padding)
        .background(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(Color(.secondarySystemBackground))
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: Constants.shadowRadius,
                    x: 0,
                    y: 2
                )
        )
    }
    
    /// Creates the achievements list section with Material Design 3 cards
    /// Requirements addressed:
    /// - Achievement Display (3.1 User Interface Design/3.1.7 Profile/Points Screen)
    /// - Gamification System (1.1 Executive Summary)
    private func achievementsSection() -> some View {
        VStack(spacing: Constants.spacing) {
            // Section header
            Text("Achievements")
                .font(Constants.headerFont)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            
            if achievements.isEmpty && !isLoading {
                // Empty state
                Text("No achievements yet")
                    .font(Constants.subtitleFont)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Constants.padding)
            } else {
                // Achievements list
                LazyVStack(spacing: Constants.spacing) {
                    ForEach(achievements, id: \.id) { achievement in
                        AchievementBadge(achievement: achievement, showDetails: true)
                            .transition(.opacity)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Achievements List")
    }
}

// MARK: - Preview Provider

#if DEBUG
struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview
            AchievementsView(userId: UUID())
                .preferredColorScheme(.light)
            
            // Dark mode preview
            AchievementsView(userId: UUID())
                .preferredColorScheme(.dark)
        }
    }
}
#endif