// SwiftUI framework - Latest
import SwiftUI

// Internal imports
import "./Core/Network/NetworkMonitor"
import "./Core/Storage/UserDefaultsManager"
import "./UI/Screens/Home/HomeView"

/// Human Tasks:
/// 1. Configure proper app lifecycle monitoring in production environment
/// 2. Set up crash reporting and analytics services
/// 3. Verify network security policies for different connection types
/// 4. Review app state restoration settings for iOS 14+ compatibility
/// 5. Configure proper logging for app lifecycle events

/// Main entry point for the Founditure iOS application
/// Requirements addressed:
/// - Device Support (1.3): Support iOS 14+ deployment target
/// - Core Features (1.2): Initialize and configure core app features and services
/// - Network Security (5.3.1): Implement network monitoring and security controls
@main
struct FounditureApp: App {
    // MARK: - Properties
    
    /// Network monitoring service for connection status
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    /// User preferences manager for app settings
    @StateObject private var userDefaults = UserDefaultsManager.shared
    
    /// Current scene phase for app lifecycle management
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(networkMonitor)
                .environmentObject(userDefaults)
                .onAppear {
                    // Start network monitoring when app appears
                    networkMonitor.startMonitoring()
                    
                    // Configure initial app settings
                    configureInitialSettings()
                }
                .onChange(of: scenePhase) { newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }
    
    // MARK: - Private Methods
    
    /// Configures initial app settings and preferences
    private func configureInitialSettings() {
        // Set default theme mode if not already set
        if userDefaults.getValue(for: .themeMode) == nil {
            userDefaults.setValue("system", for: .themeMode)
        }
        
        // Configure default notification settings
        if userDefaults.getValue(for: .notificationSettings) == nil {
            let defaultSettings: [String: Bool] = [
                "pushEnabled": true,
                "locationEnabled": true,
                "messageEnabled": true
            ]
            userDefaults.setValue(defaultSettings, for: .notificationSettings)
        }
        
        // Set default listing filters
        if userDefaults.getValue(for: .listingFilters) == nil {
            let defaultFilters: [String: Any] = [
                "radius": 5.0,
                "categories": ["all"],
                "condition": ["excellent", "good", "fair"]
            ]
            userDefaults.setValue(defaultFilters, for: .listingFilters)
        }
    }
    
    /// Handles app lifecycle phase changes
    /// - Parameter newPhase: The new scene phase
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active
            networkMonitor.startMonitoring()
            
            // Update last active timestamp
            userDefaults.setValue(Date(), for: .lastSyncTimestamp)
            
        case .inactive:
            // App became inactive
            // Perform cleanup if needed
            break
            
        case .background:
            // App entered background
            // Save any pending changes
            userDefaults.synchronize()
            
        @unknown default:
            // Handle future scene phases
            break
        }
    }
}