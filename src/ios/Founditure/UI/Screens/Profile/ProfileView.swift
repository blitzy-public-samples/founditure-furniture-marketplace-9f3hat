// SwiftUI framework - Latest
import SwiftUI

// Internal imports
import "../ProfileViewModel"
import "../../Components/AchievementBadge"
import "../../Components/LoadingIndicator"

/// Human Tasks:
/// 1. Verify accessibility labels with localization team
/// 2. Test color contrast ratios in both light and dark modes
/// 3. Validate animation performance on older devices
/// 4. Review haptic feedback patterns with UX team

/// ProfileView: Main profile screen view implementing Material Design 3 and accessibility standards
/// Requirements addressed:
/// - User Profile Management (1.2 System Overview/Core Features)
/// - Gamification System (1.1 Executive Summary)
/// - Visual Hierarchy (3.1 User Interface Design/3.1.1 Design Specifications)
@available(iOS 14.0, *)
struct ProfileView: View {
    // MARK: - Properties
    
    @State private var showingSettings = false
    @State private var showingAchievements = false
    @State private var showingLogoutAlert = false
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Constants
    
    private enum Constants {
        static let spacing: CGFloat = 16
        static let cornerRadius: CGFloat = 12
        static let avatarSize: CGFloat = 80
        static let progressHeight: CGFloat = 8
        static let gridColumns = 2
        static let badgeSpacing: CGFloat = 12
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                FounditureColors.background
                    .ignoresSafeArea()
                
                // Main content
                ScrollView {
                    VStack(spacing: Constants.spacing) {
                        // Profile header section
                        profileHeader()
                            .padding()
                            .background(FounditureColors.surface)
                            .cornerRadius(Constants.cornerRadius)
                            .shadow(
                                color: Color.black.opacity(0.1),
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                        
                        // Points section
                        pointsSection()
                            .padding()
                            .background(FounditureColors.surface)
                            .cornerRadius(Constants.cornerRadius)
                            .shadow(
                                color: Color.black.opacity(0.1),
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                        
                        // Achievements section
                        achievementsGrid()
                            .padding()
                            .background(FounditureColors.surface)
                            .cornerRadius(Constants.cornerRadius)
                            .shadow(
                                color: Color.black.opacity(0.1),
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                        
                        // Settings and logout buttons
                        VStack(spacing: Constants.spacing) {
                            Button(action: { showingSettings = true }) {
                                HStack {
                                    Image(systemName: "gear")
                                    Text("Settings")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(FounditureColors.surface)
                                .cornerRadius(Constants.cornerRadius)
                            }
                            .accessibilityLabel("Open Settings")
                            
                            Button(action: { showingLogoutAlert = true }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Logout")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(FounditureColors.surface)
                                .cornerRadius(Constants.cornerRadius)
                                .foregroundColor(FounditureColors.error)
                            }
                            .accessibilityLabel("Logout from account")
                        }
                    }
                    .padding()
                }
                .refreshable {
                    // Requirement: User Profile Management (1.2) - Keep profile data up-to-date
                    try? await viewModel.refreshData()
                }
                
                // Loading overlay
                if viewModel.isLoading {
                    LoadingIndicator(size: 48)
                        .startAnimating()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text("Logout"),
                    message: Text("Are you sure you want to logout?"),
                    primaryButton: .destructive(Text("Logout")) {
                        Task {
                            try? await viewModel.logout()
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showingSettings) {
                // Settings view would be implemented separately
                Text("Settings")
                    .navigationTitle("Settings")
            }
        }
    }
    
    // MARK: - Profile Header
    
    /// Creates the profile header section with Material Design 3 elevation
    /// Requirements addressed:
    /// - Visual Hierarchy (3.1): Material Design 3 implementation
    /// - User Profile Management (1.2): Display user information
    private func profileHeader() -> some View {
        HStack(spacing: Constants.spacing) {
            // User avatar
            if let avatarUrl = viewModel.currentUser?.profile.avatarUrl {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    FounditureColors.primary
                        .opacity(0.1)
                }
                .frame(width: Constants.avatarSize, height: Constants.avatarSize)
                .clipShape(Circle())
                .overlay(Circle().stroke(FounditureColors.primary, lineWidth: 2))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(FounditureColors.primary)
                    .frame(width: Constants.avatarSize, height: Constants.avatarSize)
            }
            
            VStack(alignment: .leading, spacing: Constants.spacing / 2) {
                // User name
                Text(viewModel.currentUser?.profile.displayName ?? "User")
                    .font(.headline)
                    .foregroundColor(FounditureColors.onSurface)
                
                // User email
                Text(viewModel.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(FounditureColors.onSurface.opacity(0.7))
            }
            
            Spacer()
            
            // Edit profile button
            Button(action: {
                // Edit profile action would be implemented separately
            }) {
                Image(systemName: "pencil.circle.fill")
                    .imageScale(.large)
                    .foregroundColor(FounditureColors.primary)
            }
            .accessibilityLabel("Edit Profile")
        }
    }
    
    // MARK: - Points Section
    
    /// Creates the points and status section with progress indicators
    /// Requirements addressed:
    /// - Gamification System (1.1): Display points and progress
    /// - Visual Hierarchy (3.1): Material Design 3 progress indicators
    private func pointsSection() -> some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            Text("Points")
                .font(.title2)
                .foregroundColor(FounditureColors.onSurface)
            
            HStack {
                Text("\(viewModel.userPoints)")
                    .font(.system(.title, design: .rounded))
                    .foregroundColor(FounditureColors.primary)
                
                Spacer()
                
                // Level indicator
                VStack(alignment: .trailing) {
                    Text("Level \(viewModel.userPoints / 100 + 1)")
                        .font(.headline)
                        .foregroundColor(FounditureColors.primary)
                    
                    Text("Next level in \(100 - (viewModel.userPoints % 100)) points")
                        .font(.caption)
                        .foregroundColor(FounditureColors.onSurface.opacity(0.7))
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: Constants.progressHeight / 2)
                        .fill(FounditureColors.primary.opacity(0.2))
                        .frame(height: Constants.progressHeight)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: Constants.progressHeight / 2)
                        .fill(FounditureColors.primary)
                        .frame(
                            width: geometry.size.width * CGFloat(viewModel.userPoints % 100) / 100,
                            height: Constants.progressHeight
                        )
                }
            }
            .frame(height: Constants.progressHeight)
            .accessibilityValue("Level progress: \(viewModel.userPoints % 100) percent")
        }
    }
    
    // MARK: - Achievements Grid
    
    /// Creates the achievements display grid with proper layout
    /// Requirements addressed:
    /// - Gamification System (1.1): Display achievements
    /// - Visual Hierarchy (3.1): Material Design 3 grid layout
    private func achievementsGrid() -> some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            HStack {
                Text("Achievements")
                    .font(.title2)
                    .foregroundColor(FounditureColors.onSurface)
                
                Spacer()
                
                Button(action: { showingAchievements = true }) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(FounditureColors.primary)
                }
                .accessibilityLabel("View all achievements")
            }
            
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: Constants.badgeSpacing),
                    count: Constants.gridColumns
                ),
                spacing: Constants.badgeSpacing
            ) {
                ForEach(viewModel.achievements, id: \.id) { achievement in
                    AchievementBadge(
                        achievement: achievement,
                        showDetails: false
                    )
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ProfileViewModel(
            userService: UserService(
                apiClient: APIClient(),
                keychainManager: KeychainManager.shared
            ),
            gamificationService: GamificationService(
                apiClient: APIClient()
            )
        )
        
        ProfileView(viewModel: viewModel)
            .preferredColorScheme(.light)
        
        ProfileView(viewModel: viewModel)
            .preferredColorScheme(.dark)
    }
}
#endif