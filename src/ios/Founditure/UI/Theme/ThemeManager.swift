//
// ThemeManager.swift
// Founditure
//
// Human Tasks:
// 1. Verify theme color accessibility with vision-impaired users
// 2. Test dynamic type scaling across all supported iOS versions
// 3. Run automated WCAG 2.1 AA compliance tests for all theme combinations
// 4. Review dark mode appearance with design team
// 5. Validate theme persistence across app launches

import SwiftUI // Latest
import Combine // Latest

// Relative imports
import "./Colors"
import "./Typography"
import "../../Core/Storage/UserDefaultsManager"

/// Theme mode enumeration for app-wide appearance settings
enum ThemeMode {
    case light
    case dark
    case system
}

/// Manages application theming following Material Design 3 guidelines with WCAG 2.1 AA compliance
/// Requirements addressed:
/// - Theme Support: Light/dark mode with custom color schemes and auto theme switching
/// - Visual Hierarchy: Material Design 3 with dynamic color system
/// - Device Support: iOS 14+ with dynamic theme adaptation
@MainActor
final class ThemeManager {
    
    // MARK: - Properties
    
    /// Current theme mode with read-only access
    private(set) var currentTheme: ThemeMode
    
    /// Publisher for theme change notifications
    let themeChangePublisher = PassthroughSubject<ThemeMode, Never>()
    
    /// User defaults manager for theme persistence
    private let userDefaultsManager: UserDefaultsManager
    
    // MARK: - Initialization
    
    /// Initializes theme manager with default settings and user preferences
    /// - Parameter userDefaultsManager: Manager for persisting theme preferences
    init(userDefaultsManager: UserDefaultsManager = .shared) {
        self.userDefaultsManager = userDefaultsManager
        
        // Load saved theme preference or default to system
        if let savedTheme = userDefaultsManager.getValue(for: .themeMode) as? String,
           let theme = ThemeMode(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .system
            // Save default theme preference
            userDefaultsManager.setValue(ThemeMode.system.rawValue, for: .themeMode)
        }
    }
    
    // MARK: - Theme Management
    
    /// Updates the current theme mode and persists the change
    /// - Parameter mode: New theme mode to apply
    func setTheme(_ mode: ThemeMode) {
        // Update current theme
        currentTheme = mode
        
        // Persist theme preference
        userDefaultsManager.setValue(mode.rawValue, for: .themeMode)
        
        // Notify observers of theme change
        themeChangePublisher.send(mode)
    }
    
    /// Returns WCAG 2.1 AA compliant color set for current theme
    /// - Returns: Dictionary of Material Design 3 theme colors
    func getCurrentThemeColors() -> [String: Color] {
        let colorScheme: ColorScheme
        
        switch currentTheme {
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .system:
            // Use system color scheme
            colorScheme = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
        }
        
        // Get theme-specific colors with WCAG compliance
        return FounditureColors.getThemeColors(colorScheme: colorScheme)
    }
    
    /// Returns typography settings with dynamic type support
    /// - Returns: Dictionary of Material Design 3 text styles
    func getCurrentTypography() -> [TextStyle: Font] {
        // Get current text size category from system
        let currentCategory = UIApplication.shared.preferredContentSizeCategory
        let dynamicSize = DynamicTypeSize(contentSizeCategory: currentCategory)
        
        // Create typography dictionary with all text styles
        var typography: [TextStyle: Font] = [:]
        
        // Configure each text style with dynamic sizing
        TextStyle.allCases.forEach { style in
            typography[style] = FounditureTypography.dynamicFont(
                style: style,
                size: dynamicSize
            )
        }
        
        return typography
    }
}

// MARK: - ThemeMode Raw Value Support

extension ThemeMode: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "light": self = .light
        case "dark": self = .dark
        case "system": self = .system
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .light: return "light"
        case .dark: return "dark"
        case .system: return "system"
        }
    }
}