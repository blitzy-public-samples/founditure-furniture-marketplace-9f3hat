// SwiftUI framework - Latest
import SwiftUI

/// LoginView: Main login screen view implementation following Material Design 3 guidelines with WCAG 2.1 AA compliance
/// Requirements addressed:
/// - Authentication Methods (5.1.1): Email/password and biometric authentication with JWT token management
/// - Visual Hierarchy (3.1.1): Material Design 3 with 8dp grid system and dynamic color system
/// - Accessibility (3.1.1): WCAG 2.1 AA compliance with screen reader support

// Import relative dependencies
import "../../Components/FounditureButton"
import "../../Components/FounditureTextField"
import "./LoginViewModel"

struct LoginView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = LoginViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Constants
    
    private enum Constants {
        static let verticalSpacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 24
        static let logoSize: CGFloat = 120
        static let minTouchTarget: CGFloat = 44
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.verticalSpacing) {
                // Logo and Title
                VStack(spacing: 16) {
                    Image("founditure_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Constants.logoSize, height: Constants.logoSize)
                        .accessibilityLabel("Founditure Logo")
                    
                    Text("Welcome Back")
                        .font(FounditureTypography.dynamicFont(style: .title1, size: .medium))
                        .foregroundColor(FounditureColors.onBackground)
                        .accessibilityAddTraits(.isHeader)
                }
                .padding(.top, Constants.verticalSpacing)
                
                // Login Form
                VStack(spacing: 16) {
                    // Email Field
                    FounditureTextField(
                        text: $viewModel.email,
                        placeholder: "Email",
                        style: .outlined,
                        validationRules: [
                            { email in
                                let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
                                let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
                                return emailPredicate.evaluate(with: email)
                            }
                        ]
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    
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
                    .textContentType(.password)
                }
                
                // Login Buttons
                VStack(spacing: 12) {
                    // Primary Login Button
                    FounditureButton(
                        title: "Log In",
                        style: .primary,
                        size: .regular,
                        isEnabled: !viewModel.email.isEmpty && !viewModel.password.isEmpty,
                        isLoading: viewModel.state == .loading
                    ) {
                        Task {
                            await viewModel.login()
                        }
                    }
                    
                    // Biometric Login Button
                    if viewModel.isBiometricsAvailable {
                        FounditureButton(
                            title: "Login with Face ID",
                            style: .secondary,
                            size: .regular
                        ) {
                            Task {
                                await viewModel.loginWithBiometrics()
                            }
                        }
                    }
                }
                
                // Additional Options
                VStack(spacing: 16) {
                    Button("Forgot Password?") {
                        // Handle forgot password
                    }
                    .font(FounditureTypography.dynamicFont(style: .body, size: .medium))
                    .foregroundColor(FounditureColors.primary)
                    .frame(minWidth: Constants.minTouchTarget, minHeight: Constants.minTouchTarget)
                    
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(FounditureTypography.dynamicFont(style: .body, size: .medium))
                            .foregroundColor(FounditureColors.onBackground)
                        
                        Button("Sign Up") {
                            // Handle sign up navigation
                        }
                        .font(FounditureTypography.dynamicFont(style: .body, size: .medium))
                        .foregroundColor(FounditureColors.primary)
                        .frame(minWidth: Constants.minTouchTarget, minHeight: Constants.minTouchTarget)
                    }
                }
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.bottom, Constants.verticalSpacing)
        }
        .background(FounditureColors.background)
        .overlay {
            loginStateView(state: viewModel.state)
        }
    }
    
    // MARK: - State Views
    
    @ViewBuilder
    private func loginStateView(state: LoginState) -> some View {
        switch state {
        case .loading:
            ProgressView("Logging in...")
                .progressViewStyle(CircularProgressViewStyle(tint: FounditureColors.primary))
                .accessibilityLabel("Loading")
                
        case .error(let error):
            Text(error.localizedDescription)
                .font(FounditureTypography.dynamicFont(style: .body, size: .medium))
                .foregroundColor(FounditureColors.error)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(FounditureColors.error.opacity(0.1))
                )
                .accessibilityLabel("Error: \(error.localizedDescription)")
                
        case .success:
            // Handle successful login
            dismiss()
            
        case .idle:
            EmptyView()
        }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
#endif