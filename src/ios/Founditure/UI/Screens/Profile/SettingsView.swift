//
// SettingsView.swift
// Founditure
//
// Human Tasks:
// 1. Verify dark mode implementation works correctly with system settings
// 2. Test notification permissions on physical devices
// 3. Confirm location services integration with device settings
// 4. Review accessibility labels and VoiceOver support

import SwiftUI // Latest
import Combine // Latest

// Relative imports
import "../../../Core/Storage/UserDefaultsManager"
import "../../../Core/Utilities/NotificationManager"
import "../../../Core/Constants/AppConstants"

/// Represents different sections in the settings view
private enum SettingsSection: String, CaseIterable {
    case notifications = "Notifications"
    case privacy = "Privacy"
    case appearance = "Appearance"
    case about = "About"
}

/// Addresses requirements:
/// - 1.3 Scope/Implementation Boundaries: Support iOS 14+ devices
/// - 2.2.1 Core Components: Enable notification management
/// - 3.1.1 Design Specifications: Material Design 3 implementation
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool
    @Published var darkModeEnabled: Bool
    @Published var locationTrackingEnabled: Bool
    let appVersion: String
    
    init() {
        // Initialize settings from UserDefaults
        self.notificationsEnabled = UserDefaultsManager.shared.getValue(for: .notificationSettings) as? Bool ?? false
        self.darkModeEnabled = UserDefaultsManager.shared.getValue(for: .themeMode) as? Bool ?? false
        self.locationTrackingEnabled = UserDefaultsManager.shared.getValue(for: .mapSettings) as? Bool ?? false
        
        // Get app version from bundle
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    func toggleNotifications() {
        guard Features.enablePushNotifications else { return }
        
        notificationsEnabled.toggle()
        
        Task {
            // Request notification authorization
            NotificationManager.shared.requestAuthorization { granted in
                Task { @MainActor in
                    if !granted {
                        self.notificationsEnabled = false
                    }
                    // Save preference
                    UserDefaultsManager.shared.setValue(self.notificationsEnabled, for: .notificationSettings)
                }
            }
        }
    }
    
    func toggleDarkMode() {
        darkModeEnabled.toggle()
        UserDefaultsManager.shared.setValue(darkModeEnabled, for: .themeMode)
    }
    
    func toggleLocationTracking() {
        locationTrackingEnabled.toggle()
        UserDefaultsManager.shared.setValue(locationTrackingEnabled, for: .mapSettings)
    }
}

/// Addresses requirements:
/// - 3.1.1 Design Specifications: Implement Material Design 3 principles
/// - 1.3 Scope/Implementation Boundaries: Support iOS 14+ devices
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            List {
                // Notifications Section
                Section(header: Text(SettingsSection.notifications.rawValue)) {
                    if Features.enablePushNotifications {
                        Toggle(isOn: $viewModel.notificationsEnabled) {
                            Label {
                                Text("Push Notifications")
                            } icon: {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .onChange(of: viewModel.notificationsEnabled) { _ in
                            viewModel.toggleNotifications()
                        }
                    }
                }
                
                // Privacy Section
                Section(header: Text(SettingsSection.privacy.rawValue)) {
                    Toggle(isOn: $viewModel.locationTrackingEnabled) {
                        Label {
                            Text("Location Services")
                        } icon: {
                            Image(systemName: "location.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .onChange(of: viewModel.locationTrackingEnabled) { _ in
                        viewModel.toggleLocationTracking()
                    }
                }
                
                // Appearance Section
                Section(header: Text(SettingsSection.appearance.rawValue)) {
                    Toggle(isOn: $viewModel.darkModeEnabled) {
                        Label {
                            Text("Dark Mode")
                        } icon: {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.purple)
                        }
                    }
                    .onChange(of: viewModel.darkModeEnabled) { _ in
                        viewModel.toggleDarkMode()
                    }
                }
                
                // About Section
                Section(header: Text(SettingsSection.about.rawValue)) {
                    HStack {
                        Label {
                            Text("Version")
                        } icon: {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .listStyle(InsetGroupedListStyle())
            // Apply Material Design 3 styling
            .accentColor(.blue)
            .preferredColorScheme(viewModel.darkModeEnabled ? .dark : .light)
        }
        // Support iOS 14+ navigation style
        .navigationViewStyle(StackNavigationViewStyle())
        // Accessibility
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Settings Screen")
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView()
                .preferredColorScheme(.light)
            
            SettingsView()
                .preferredColorScheme(.dark)
        }
    }
}
#endif