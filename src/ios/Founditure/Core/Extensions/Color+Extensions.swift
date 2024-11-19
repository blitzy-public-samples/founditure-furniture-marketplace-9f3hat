//
// Color+Extensions.swift
// Founditure
//
// Human Tasks:
// 1. Ensure SwiftUI and UIKit frameworks are properly linked in the Xcode project
// 2. Verify that the app's Info.plist includes required color space configurations
// 3. Test color contrast ratios with actual brand colors once defined
// 4. Validate color adjustments on both light and dark modes with design team

import SwiftUI  // Latest
import UIKit    // Latest

extension Color {
    // MARK: - Hex Color Initialization
    
    /// Initializes a Color from a hexadecimal string, supporting Material Design 3 color tokens
    /// Requirement: Visual Hierarchy - Material Design 3 with dynamic color system implementation
    /// - Parameter hex: A hexadecimal color string (e.g., "#FF0000" or "FF0000")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Dark Mode Detection
    
    /// Determines if a color is considered dark for contrast purposes using WCAG relative luminance formula
    /// Requirement: Accessibility - WCAG 2.1 AA compliance with minimum contrast ratio 4.5:1
    var isDark: Bool {
        guard let components = UIColor(self).cgColor.components else { return false }
        
        // Extract RGB components and apply gamma correction
        let r = components[0] <= 0.03928 ? components[0] / 12.92 : pow((components[0] + 0.055) / 1.055, 2.4)
        let g = components[1] <= 0.03928 ? components[1] / 12.92 : pow((components[1] + 0.055) / 1.055, 2.4)
        let b = components[2] <= 0.03928 ? components[2] / 12.92 : pow((components[2] + 0.055) / 1.055, 2.4)
        
        // Calculate relative luminance using W3C formula
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        
        return luminance < 0.179 // W3C threshold for dark colors
    }
    
    // MARK: - Contrast Ratio Calculation
    
    /// Calculates WCAG 2.1 contrast ratio with another color to ensure AA compliance
    /// Requirement: Accessibility - WCAG 2.1 AA compliance with minimum contrast ratio 4.5:1
    /// - Parameter other: The color to compare against
    /// - Returns: Contrast ratio between the two colors (1-21)
    func contrastRatio(with other: Color) -> Double {
        func luminance(for color: Color) -> Double {
            guard let components = UIColor(color).cgColor.components else { return 0 }
            
            // Apply gamma correction to RGB components
            let r = components[0] <= 0.03928 ? components[0] / 12.92 : pow((components[0] + 0.055) / 1.055, 2.4)
            let g = components[1] <= 0.03928 ? components[1] / 12.92 : pow((components[1] + 0.055) / 1.055, 2.4)
            let b = components[2] <= 0.03928 ? components[2] / 12.92 : pow((components[2] + 0.055) / 1.055, 2.4)
            
            return 0.2126 * r + 0.7152 * g + 0.0722 * b
        }
        
        let l1 = luminance(for: self)
        let l2 = luminance(for: other)
        
        // Ensure lighter color is used as numerator
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    // MARK: - Theme Adjustment
    
    /// Returns a color adjusted for current theme mode following Material Design 3 color system
    /// Requirement: Theme Support - Light/dark mode support with dynamic color system
    /// - Parameter colorScheme: The current color scheme (light/dark)
    /// - Returns: Theme-adjusted color with appropriate opacity and contrast
    func adjustedForTheme(colorScheme: ColorScheme) -> Color {
        let uiColor = UIColor(self)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        switch colorScheme {
        case .dark:
            // Material Design 3 dark theme adjustments
            let adjustedBrightness = min(b * 0.8, 0.9) // Reduce brightness in dark mode
            let adjustedSaturation = min(s * 1.15, 1.0) // Slightly increase saturation
            return Color(hue: h, saturation: adjustedSaturation, brightness: adjustedBrightness, opacity: a)
            
        case .light:
            // Material Design 3 light theme adjustments
            let adjustedBrightness = min(b * 1.1, 1.0) // Increase brightness in light mode
            let adjustedSaturation = min(s * 0.95, 1.0) // Slightly reduce saturation
            return Color(hue: h, saturation: adjustedSaturation, brightness: adjustedBrightness, opacity: a)
            
        @unknown default:
            return self
        }
    }
}