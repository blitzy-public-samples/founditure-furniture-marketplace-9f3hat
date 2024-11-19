//
// FounditureButton.swift
// Founditure
//
// Human Tasks:
// 1. Verify button touch target sizes meet WCAG requirements on all supported devices
// 2. Test color contrast ratios in both light and dark modes
// 3. Validate dynamic type scaling across all text size categories
// 4. Review haptic feedback implementation with UX team
// 5. Test VoiceOver compatibility and accessibility labels

import SwiftUI // Latest
import Foundation

// Import theme dependencies
import "../Theme/Colors"
import "../Theme/Typography"

/// Button style options following Material Design 3 guidelines
/// Requirement: Visual Hierarchy - Material Design 3 with dynamic color system
public enum ButtonStyle {
    case primary
    case secondary
    case text
}

/// Button size options with WCAG-compliant touch targets
/// Requirement: Accessibility - WCAG 2.1 AA compliance with minimum touch targets 44x44pt
public enum ButtonSize {
    case small
    case regular
    case large
}

/// A customizable button component that follows the Founditure design system
/// Requirements addressed:
/// - Visual Hierarchy: Material Design 3 with 8dp grid system and dynamic color system
/// - Component Library: Custom Design System with atomic design principles
/// - Accessibility: WCAG 2.1 AA compliance with minimum touch targets 44x44pt
@available(iOS 14.0, *)
public struct FounditureButton: View {
    // MARK: - Properties
    
    private let title: String
    private let style: ButtonStyle
    private let size: ButtonSize
    private let isEnabled: Bool
    private let isLoading: Bool
    private let action: (() -> Void)?
    
    // MARK: - Private Properties
    
    private let minTouchTargetSize: CGFloat = 44 // WCAG 2.1 AA requirement
    
    // MARK: - Initialization
    
    /// Creates a new FounditureButton with the specified parameters
    /// - Parameters:
    ///   - title: The button's text label
    ///   - style: The button's visual style
    ///   - size: The button's size category
    ///   - isEnabled: Whether the button is interactive
    ///   - isLoading: Whether to show a loading indicator
    ///   - action: The closure to execute when tapped
    public init(
        title: String,
        style: ButtonStyle = .primary,
        size: ButtonSize = .regular,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: {
            if isEnabled && !isLoading {
                // Add haptic feedback for button press
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                action?()
            }
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(
                            tint: style == .primary ? FounditureColors.onPrimary : FounditureColors.primary
                        ))
                }
                
                Text(title)
                    .font(FounditureTypography.dynamicFont(
                        style: .body,
                        size: .medium
                    ))
            }
            .frame(maxWidth: size == .small ? nil : .infinity)
            .frame(minWidth: minTouchTargetSize, minHeight: minTouchTargetSize)
            .padding(.horizontal, buttonHorizontalPadding)
            .padding(.vertical, buttonVerticalPadding)
            .background(buttonBackground)
            .foregroundColor(buttonForegroundColor)
            .cornerRadius(8)
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityHint(isEnabled ? nil : "Button is disabled")
        .accessibilityAddTraits(.isButton)
        .if(isLoading) { view in
            view.accessibilityValue("Loading")
        }
    }
    
    // MARK: - Private Helpers
    
    private var buttonHorizontalPadding: CGFloat {
        switch size {
        case .small:
            return 12
        case .regular:
            return 16
        case .large:
            return 24
        }
    }
    
    private var buttonVerticalPadding: CGFloat {
        switch size {
        case .small:
            return 8
        case .regular:
            return 12
        case .large:
            return 16
        }
    }
    
    private var buttonBackground: Color {
        switch style {
        case .primary:
            return FounditureColors.dynamicColor(
                lightColor: FounditureColors.primary,
                darkColor: FounditureColors.primary,
                colorScheme: .light
            )
        case .secondary:
            return FounditureColors.dynamicColor(
                lightColor: FounditureColors.secondary,
                darkColor: FounditureColors.secondary,
                colorScheme: .light
            )
        case .text:
            return .clear
        }
    }
    
    private var buttonForegroundColor: Color {
        switch style {
        case .primary, .secondary:
            return FounditureColors.onPrimary
        case .text:
            return FounditureColors.primary
        }
    }
}

// MARK: - View Modifier Extension

extension View {
    fileprivate func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> AnyView {
        if condition {
            return AnyView(transform(self))
        }
        return AnyView(self)
    }
}

#if DEBUG
// MARK: - Preview Provider

struct FounditureButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            FounditureButton(
                title: "Primary Button",
                style: .primary,
                action: {}
            )
            
            FounditureButton(
                title: "Secondary Button",
                style: .secondary,
                action: {}
            )
            
            FounditureButton(
                title: "Text Button",
                style: .text,
                action: {}
            )
            
            FounditureButton(
                title: "Loading Button",
                isLoading: true,
                action: {}
            )
            
            FounditureButton(
                title: "Disabled Button",
                isEnabled: false,
                action: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif