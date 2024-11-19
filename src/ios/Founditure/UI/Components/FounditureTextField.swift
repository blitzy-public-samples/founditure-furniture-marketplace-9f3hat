//
// FounditureTextField.swift
// Founditure
//
// Human Tasks:
// 1. Verify color contrast ratios meet WCAG 2.1 AA standards with design team
// 2. Test dynamic type scaling across all iOS device sizes
// 3. Validate VoiceOver functionality with accessibility team
// 4. Review error message animations with UX team

import SwiftUI // Latest
import Combine // Latest

// Import relative dependencies
import "../Theme/Colors"
import "../Theme/Typography"

/// Text field style options following Material Design 3 guidelines
/// Requirement: Visual Hierarchy - Material Design 3 with 8dp grid system
enum TextFieldStyle {
    case standard
    case outlined
    case filled
}

/// Type definition for validation rule functions
typealias ValidationRule = (String) -> Bool

/// Custom text field component implementing Founditure design system with Material Design 3
/// Requirements addressed:
/// - Visual Hierarchy: Material Design 3 with 8dp grid system and dynamic color system
/// - Component Library: Custom Design System with shared component library
/// - Accessibility: WCAG 2.1 AA compliance with screen reader support
@ViewBuilder
struct FounditureTextField: View {
    // MARK: - Properties
    
    @Binding private var text: String
    private let placeholder: String
    private let style: TextFieldStyle
    private let isSecure: Bool
    private var errorMessage: String?
    private let validationRules: [ValidationRule]
    
    // Accessibility properties
    private let isAccessibilityElement: Bool = true
    private let accessibilityLabel: String
    private let accessibilityHint: String?
    
    // Internal state
    @State private var isEditing: Bool = false
    @State private var isValid: Bool = true
    @State private var showError: Bool = false
    
    // MARK: - Initialization
    
    /// Initializes a new text field with Material Design 3 styling
    /// - Parameters:
    ///   - text: Binding to the text value
    ///   - placeholder: Placeholder text
    ///   - style: Material Design 3 text field style
    ///   - isSecure: Whether the field should mask input
    ///   - validationRules: Array of validation rules to apply
    init(
        text: Binding<String>,
        placeholder: String,
        style: TextFieldStyle = .standard,
        isSecure: Bool = false,
        validationRules: [ValidationRule] = []
    ) {
        self._text = text
        self.placeholder = placeholder
        self.style = style
        self.isSecure = isSecure
        self.validationRules = validationRules
        self.accessibilityLabel = placeholder
        self.accessibilityHint = isSecure ? "Secure text field" : nil
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Main text field
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .onChange(of: text) { validateInput() }
                } else {
                    TextField(placeholder, text: $text)
                        .onChange(of: text) { validateInput() }
                }
            }
            .textFieldStyle(PlainTextFieldStyle())
            .font(FounditureTypography.dynamicFont(style: .body, size: .medium))
            .foregroundColor(FounditureColors.dynamicColor(
                lightColor: FounditureColors.onSurface,
                darkColor: FounditureColors.onSurface,
                colorScheme: .light
            ))
            .applyStyle(style)
            
            // Error message
            if showError, let error = errorMessage {
                Text(error)
                    .font(FounditureTypography.dynamicFont(style: .caption, size: .medium))
                    .foregroundColor(FounditureColors.error)
                    .transition(.opacity)
                    .accessibility(label: Text("Error: \(error)"))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showError)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityValue(text)
    }
    
    // MARK: - Private Methods
    
    /// Validates text input against provided validation rules
    /// - Returns: Whether input passes all validation rules
    private func validateInput() {
        let isValidInput = validationRules.allSatisfy { rule in
            rule(text)
        }
        
        isValid = isValidInput
        showError = !isValidInput
    }
    
    /// Applies the selected Material Design 3 text field style
    /// - Parameter style: The style to apply
    /// - Returns: Styled view
    private func applyStyle(_ style: TextFieldStyle) -> some View {
        Group {
            switch style {
            case .standard:
                self
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        Rectangle()
                            .fill(Color.clear)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(
                                        isValid ? FounditureColors.primary : FounditureColors.error
                                    )
                                    .offset(y: 1),
                                alignment: .bottom
                            )
                    )
                
            case .outlined:
                self
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(
                                isValid ? FounditureColors.primary : FounditureColors.error,
                                lineWidth: 1
                            )
                    )
                
            case .filled:
                self
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(FounditureColors.dynamicColor(
                                lightColor: FounditureColors.primary.opacity(0.1),
                                darkColor: FounditureColors.primary.opacity(0.2),
                                colorScheme: .light
                            ))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(
                                isValid ? FounditureColors.primary : FounditureColors.error,
                                lineWidth: isEditing ? 2 : 0
                            )
                    )
            }
        }
        .onTapGesture {
            isEditing = true
        }
    }
}