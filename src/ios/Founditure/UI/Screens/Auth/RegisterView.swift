// SwiftUI framework - Latest
import SwiftUI

/// Human Tasks:
/// 1. Verify color contrast ratios meet WCAG 2.1 AA standards
/// 2. Test VoiceOver functionality with accessibility team
/// 3. Validate form field touch targets meet minimum size requirements
/// 4. Review error message animations with UX team
/// 5. Test dynamic type scaling across all device sizes

/// RegisterView: SwiftUI view for user registration implementing Material Design 3
/// Requirements addressed:
/// - Authentication Methods (5.1.1): Email/Password registration with form validation
/// - Visual Hierarchy (3.1.1): Material Design 3 with 8dp grid system
/// - Accessibility (3.1.1): WCAG 2.1 AA compliance with screen reader support
struct RegisterView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = RegisterViewModel(authService: AuthService.shared)
    @Environment(\.dismiss) private var dismiss
    @State private var showError = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Logo/Header
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .accessibilityLabel("Founditure Logo")
                    .padding(.top, 48)
                
                // Registration Form
                VStack(spacing: 16) {
                    // Email Field
                    FounditureTextField(
                        text: $viewModel.email,
                        placeholder: "Email",
                        style: .outlined,
                        validationRules: [
                            { !$0.isEmpty },
                            { $0.contains("@") }
                        ]
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .accessibilityHint("Enter your email address")
                    
                    // Password Field
                    FounditureTextField(
                        text: $viewModel.password,
                        placeholder: "Password",
                        style: .outlined,
                        isSecure: true,
                        validationRules: [
                            { $0.count >= 8 }
                        ]
                    )
                    .textContentType(.newPassword)
                    .accessibilityHint("Enter a password with at least 8 characters")
                    
                    // Confirm Password Field
                    FounditureTextField(
                        text: $viewModel.confirmPassword,
                        placeholder: "Confirm Password",
                        style: .outlined,
                        isSecure: true,
                        validationRules: [
                            { $0 == viewModel.password }
                        ]
                    )
                    .textContentType(.newPassword)
                    .accessibilityHint("Re-enter your password to confirm")
                    
                    // Display Name Field
                    FounditureTextField(
                        text: $viewModel.displayName,
                        placeholder: "Display Name",
                        style: .outlined,
                        validationRules: [
                            { !$0.isEmpty }
                        ]
                    )
                    .textContentType(.name)
                    .accessibilityHint("Enter your display name")
                }
                .padding(.horizontal, 24)
                
                // Register Button
                FounditureButton(
                    title: "Register",
                    style: .primary,
                    size: .regular,
                    isLoading: viewModel.isLoading,
                    action: handleRegistration
                )
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                // Login Link
                Button(action: { dismiss() }) {
                    Text("Already have an account? Sign in")
                        .font(FounditureTypography.dynamicFont(style: .body, size: .medium))
                        .foregroundColor(FounditureColors.primary)
                }
                .padding(.top, 16)
                .accessibilityHint("Go back to sign in screen")
                
                Spacer()
            }
            .padding(.bottom, 32)
        }
        .alert("Registration Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
        .background(
            FounditureColors.background
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Private Methods
    
    /// Handles the registration button tap with loading state and error handling
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Secure registration with error handling
    private func handleRegistration() {
        Task {
            do {
                try await viewModel.register()
                dismiss()
            } catch let error as RegistrationError {
                errorMessage = getErrorMessage(for: error)
                showError = true
            } catch {
                errorMessage = "An unexpected error occurred. Please try again."
                showError = true
            }
        }
    }
    
    /// Converts registration errors to user-friendly messages
    /// - Parameter error: The registration error
    /// - Returns: User-friendly error message
    private func getErrorMessage(for error: RegistrationError) -> String {
        switch error {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPassword:
            return "Password must be at least 8 characters"
        case .passwordMismatch:
            return "Passwords do not match"
        case .weakPassword:
            return "Password must contain uppercase, lowercase, number, and special character"
        case .emailTaken:
            return "This email is already registered"
        }
    }
}

#if DEBUG
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
#endif