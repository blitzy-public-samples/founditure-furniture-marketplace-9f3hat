//
// Typography.swift
// Founditure
//
// Human Tasks:
// 1. Verify font scaling ratios with design team for Material Design 3 compliance
// 2. Test dynamic type scaling across all iOS device sizes
// 3. Run automated WCAG 2.1 AA compliance tests for text contrast
// 4. Validate font rendering with custom font assets if used
// 5. Review accessibility settings impact on text scaling

import SwiftUI // Latest
import Foundation

// Relative imports for internal dependencies
import "../../Core/Constants/AppConstants"
import "./Colors"

/// Text style enumeration for consistent typography usage
/// Requirement: Visual Hierarchy - Material Design 3 with dynamic typography
enum TextStyle {
    case largeTitle
    case title1
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption
}

/// Founditure app typography definitions following Material Design 3 type scale
/// Requirements addressed:
/// - Visual Hierarchy: Material Design 3 with 8dp grid system and dynamic typography
/// - Accessibility: WCAG 2.1 AA compliance with adaptive typography
/// - Device Support: iOS 14+ with dynamic text sizing based on device settings
final class FounditureTypography {
    
    // MARK: - Static Font Definitions
    
    /// Large title font style - Used for main screen headers
    static let largeTitle: Font = .system(size: 34, weight: .bold, design: .rounded)
    
    /// Title 1 font style - Used for primary headings
    static let title1: Font = .system(size: 28, weight: .semibold, design: .rounded)
    
    /// Title 2 font style - Used for secondary headings
    static let title2: Font = .system(size: 22, weight: .semibold, design: .rounded)
    
    /// Title 3 font style - Used for tertiary headings
    static let title3: Font = .system(size: 20, weight: .semibold, design: .rounded)
    
    /// Headline font style - Used for emphasized body text
    static let headline: Font = .system(size: 17, weight: .semibold, design: .default)
    
    /// Body font style - Used for main content text
    static let body: Font = .system(size: 17, weight: .regular, design: .default)
    
    /// Callout font style - Used for emphasized secondary content
    static let callout: Font = .system(size: 16, weight: .regular, design: .default)
    
    /// Subheadline font style - Used for supporting text
    static let subheadline: Font = .system(size: 15, weight: .regular, design: .default)
    
    /// Footnote font style - Used for auxiliary information
    static let footnote: Font = .system(size: 13, weight: .regular, design: .default)
    
    /// Caption font style - Used for labels and annotations
    static let caption: Font = .system(size: 12, weight: .regular, design: .default)
    
    // MARK: - Private Initialization
    
    /// Private initializer to prevent instantiation as this is a utility class
    private init() {}
    
    // MARK: - Dynamic Font Scaling
    
    /// Returns a font adjusted for the current text size category while maintaining WCAG 2.1 AA readability standards
    /// - Parameters:
    ///   - style: The text style to apply
    ///   - size: The dynamic type size preference
    /// - Returns: Dynamically sized font for the given style with proper scaling
    static func dynamicFont(style: TextStyle, size: DynamicTypeSize) -> Font {
        let baseFont: Font
        let minSize: CGFloat
        let maxSize: CGFloat
        
        // Map text style to base font and size constraints
        switch style {
        case .largeTitle:
            baseFont = largeTitle
            minSize = 32
            maxSize = 44
        case .title1:
            baseFont = title1
            minSize = 26
            maxSize = 38
        case .title2:
            baseFont = title2
            minSize = 20
            maxSize = 32
        case .title3:
            baseFont = title3
            minSize = 18
            maxSize = 30
        case .headline:
            baseFont = headline
            minSize = 16
            maxSize = 24
        case .body:
            baseFont = body
            minSize = 16
            maxSize = 22
        case .callout:
            baseFont = callout
            minSize = 15
            maxSize = 21
        case .subheadline:
            baseFont = subheadline
            minSize = 14
            maxSize = 20
        case .footnote:
            baseFont = footnote
            minSize = 12
            maxSize = 18
        case .caption:
            baseFont = caption
            minSize = 11
            maxSize = 17
        }
        
        // Calculate scale factor based on dynamic type size
        let scaleFactor: CGFloat
        switch size {
        case .xSmall:
            scaleFactor = 0.8
        case .small:
            scaleFactor = 0.9
        case .medium:
            scaleFactor = 1.0
        case .large:
            scaleFactor = 1.1
        case .xLarge:
            scaleFactor = 1.2
        case .xxLarge:
            scaleFactor = 1.3
        case .xxxLarge:
            scaleFactor = 1.4
        @unknown default:
            scaleFactor = 1.0
        }
        
        // Calculate scaled size within constraints
        let baseSize = baseFont.size
        let scaledSize = baseSize * scaleFactor
        let clampedSize = min(max(scaledSize, minSize), maxSize)
        
        // Create scaled font with same weight and design
        return baseFont.withSize(clampedSize)
    }
    
    /// Returns text style configuration for given style with proper dynamic sizing
    /// - Parameter style: The text style to configure
    /// - Returns: Configured font for the style with proper scaling
    static func getTextStyle(style: TextStyle) -> Font {
        let baseFont: Font
        
        switch style {
        case .largeTitle:
            baseFont = largeTitle
        case .title1:
            baseFont = title1
        case .title2:
            baseFont = title2
        case .title3:
            baseFont = title3
        case .headline:
            baseFont = headline
        case .body:
            baseFont = body
        case .callout:
            baseFont = callout
        case .subheadline:
            baseFont = subheadline
        case .footnote:
            baseFont = footnote
        case .caption:
            baseFont = caption
        }
        
        // Apply dynamic sizing based on user preferences
        return baseFont.dynamic()
    }
}