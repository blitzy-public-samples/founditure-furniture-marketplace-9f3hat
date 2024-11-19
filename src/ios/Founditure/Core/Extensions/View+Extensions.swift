//
// View+Extensions.swift
// Founditure
//
// Human Tasks:
// 1. Test shadow rendering performance on older iOS devices
// 2. Validate tap target sizes with accessibility guidelines
// 3. Review theme transitions with design team
// 4. Run automated accessibility tests for all view modifiers
// 5. Verify color contrast ratios in both light and dark modes

import SwiftUI // Latest

// Relative imports
import "../../UI/Theme/ThemeManager"

/// SwiftUI View extensions for Material Design 3 styling and accessibility
/// Requirements addressed:
/// - Visual Hierarchy: Material Design 3 with 8dp grid system and elevation levels 0-5
/// - Accessibility: Touch targets 44x44pt and screen reader support
/// - Theme Support: Light/dark mode with dynamic theme switching
/// - Responsive Design: Flexible grid layouts and adaptive typography
extension View {
    
    // MARK: - Material Design Shadow
    
    /// Applies Material Design 3 elevation shadow with specified level
    /// - Parameter level: Elevation level (0-5) following MD3 guidelines
    /// - Returns: Modified view with Material Design 3 compliant shadow
    func materialShadow(level: Int) -> some View {
        // Validate elevation level
        let validLevel = min(max(level, 0), 5)
        
        // Calculate shadow parameters based on MD3 specifications
        let opacity = 0.14 + Double(validLevel) * 0.02
        let radius = CGFloat(validLevel) * 4.0
        let offset = CGSize(width: 0, height: CGFloat(validLevel) * 2.0)
        
        return self.shadow(
            color: Color.black.opacity(opacity),
            radius: radius,
            x: offset.width,
            y: offset.height
        )
    }
    
    // MARK: - Adaptive Spacing
    
    /// Applies spacing based on Material Design 3 8dp grid system
    /// - Parameter multiplier: Grid unit multiplier
    /// - Returns: Calculated spacing value following 8dp grid
    func adaptiveSpacing(_ multiplier: Int) -> CGFloat {
        // Base unit of 8 points following Material Design grid
        let baseUnit: CGFloat = 8.0
        return baseUnit * CGFloat(multiplier)
    }
    
    // MARK: - Accessibility
    
    /// Ensures minimum tap target size of 44x44 points following WCAG 2.1 AA
    /// - Returns: Modified view with accessible tap area
    func accessibleTapArea() -> some View {
        self.frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle()) // Ensure entire frame is tappable
    }
    
    // MARK: - Theme Support
    
    /// Applies Material Design 3 theme-aware styling with WCAG 2.1 AA color contrast
    /// - Returns: Theme-aware modified view
    func themeAware() -> some View {
        let themeManager = ThemeManager.shared
        let colors = themeManager.getCurrentThemeColors()
        let typography = themeManager.getCurrentTypography()
        
        return self
            .environment(\.colorScheme, themeManager.currentTheme == .dark ? .dark : .light)
            .foregroundColor(colors["onBackground"])
            .background(colors["background"])
    }
    
    // MARK: - Conditional Modifier
    
    /// Conditionally applies a view modifier based on runtime condition
    /// - Parameters:
    ///   - condition: Boolean condition to evaluate
    ///   - modifier: View modifier to apply if condition is true
    /// - Returns: Conditionally modified view
    func conditionalModifier<Content: View>(
        _ condition: Bool,
        modifier: @escaping (Self) -> Content
    ) -> some View {
        Group {
            if condition {
                modifier(self)
            } else {
                self
            }
        }
    }
}