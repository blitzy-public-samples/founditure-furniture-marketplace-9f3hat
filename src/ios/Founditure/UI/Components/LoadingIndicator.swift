//
// LoadingIndicator.swift
// Founditure
//
// Human Tasks:
// 1. Verify animation timing with UX team for optimal user experience
// 2. Test loading indicator visibility against all background colors
// 3. Validate accessibility features with VoiceOver enabled
// 4. Review loading indicator size scaling on different device sizes

import SwiftUI // Latest
import Foundation

/// Relative import for theme colors
import "../Theme/Colors"

/// A SwiftUI view that displays an animated circular loading indicator following Material Design 3 specifications
/// Requirements addressed:
/// - Visual Hierarchy: Material Design 3 loading animation with elevation and dynamic color system
/// - Theme Support: Dynamic theming support with light/dark mode adaptation
/// - Accessibility: WCAG 2.1 AA compliant with proper contrast and accessibility labels
struct LoadingIndicator: View {
    // MARK: - Properties
    
    /// Size of the loading indicator (diameter)
    private let size: CGFloat
    
    /// Color of the loading indicator
    private let color: Color
    
    /// Current animation state
    @State private var isAnimating: Bool = false
    
    /// Current rotation angle in degrees
    @State private var rotationDegrees: Double = 0
    
    /// Current opacity level
    @State private var opacity: Double = 1.0
    
    /// Stroke width calculated based on size following Material Design 3 specs
    private let lineWidth: CGFloat
    
    // MARK: - Initialization
    
    /// Initializes a new loading indicator with customizable size and color
    /// - Parameters:
    ///   - size: Diameter of the loading indicator (default: 24.0 following MD3 specs)
    ///   - color: Custom color for the indicator (defaults to primary theme color)
    init(size: CGFloat = 24.0, color: Color? = nil) {
        self.size = size
        self.color = color ?? FounditureColors.primary
        self.lineWidth = size * 0.1 // MD3 spec for stroke width ratio
    }
    
    // MARK: - View Body
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.75) // MD3 spec for spinner arc length
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                )
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotationDegrees))
            .shadow(
                color: FounditureColors.surface.opacity(0.15),
                radius: 4,
                x: 0,
                y: 2
            ) // MD3 elevation
            .opacity(opacity)
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: rotationDegrees)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Loading")
            .accessibilityAddTraits(.updatesFrequently)
            .accessibilityValue(isAnimating ? "Active" : "Inactive")
            .onChange(of: isAnimating) { newValue in
                if newValue {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        rotationDegrees = 360
                    }
                } else {
                    withAnimation(.easeOut) {
                        opacity = 0
                        rotationDegrees = 0
                    }
                }
            }
    }
    
    // MARK: - Animation Control
    
    /// Starts the loading animation with proper timing curves
    func startAnimating() {
        isAnimating = true
        withAnimation(.easeIn(duration: 0.2)) {
            opacity = 1.0
        }
    }
    
    /// Stops the loading animation with smooth fadeout
    func stopAnimating() {
        isAnimating = false
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            rotationDegrees = 0
        }
    }
}