// Foundation framework - Latest
import Foundation
// Combine framework - Latest
import Combine
// SwiftUI framework - Latest
import SwiftUI

/// Human Tasks:
/// 1. Configure proper error logging for registration failures
/// 2. Review password strength requirements with security team
/// 3. Verify email validation regex pattern meets security standards
/// 4. Set up analytics tracking for registration events
/// 5. Configure proper rate limiting handling

/// RegistrationError: Defines possible validation errors during registration
/// Requirements addressed:
/// - Authentication Methods (5.1.1): Comprehensive form validation
public enum RegistrationError: Error {
    case invalidEmail
    case invalidPassword
    case passwordMismatch
    case weakPassword
    case emailTaken
}

/// RegisterViewModel: Manages registration form state and validation
/// Requirements addressed:
/// - Authentication Methods (5.1.1): Email/password registration with validation
/// - Data Security (5.2.1): Secure handling of registration data
@MainActor
@Observable
public final class RegisterViewModel {
    // MARK: - Private Properties
    
    private let authService: AuthService
    private let emailRegex = "^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$"
    private let minimumPasswordLength = AppConstants.Security.minimumPasswordLength
    
    // MARK: - Public Properties
    
    public var email: String = ""
    public var password: String = ""
    public var confirmPassword: String = ""
    public var displayName: String = ""
    public var isLoading: Bool = false
    public var error: Error?
    public private(set) var validationErrors: Set<RegistrationError> = []
    
    // MARK: - Initialization
    
    /// Initializes view model with auth service dependency
    /// - Parameter authService: Service handling authentication operations
    public init(authService: AuthService) {
        self.authService = authService
    }
    
    // MARK: - Public Methods
    
    /// Validates registration form input
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Comprehensive form validation
    public func validateForm() -> Bool {
        validationErrors.removeAll()
        
        // Validate email format
        if !NSPredicate(format: "SELF MATCHES %@", emailRegex)
            .evaluate(with: email.trimmingCharacters(in: .whitespaces)) {
            validationErrors.insert(.invalidEmail)
        }
        
        // Validate password strength
        if password.count < minimumPasswordLength {
            validationErrors.insert(.weakPassword)
        }
        
        // Check for password complexity
        let hasUppercase = password.contains(where: { $0.isUppercase })
        let hasLowercase = password.contains(where: { $0.isLowercase })
        let hasNumber = password.contains(where: { $0.isNumber })
        let hasSpecialCharacter = password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) })
        
        if !hasUppercase || !hasLowercase || !hasNumber || !hasSpecialCharacter {
            validationErrors.insert(.weakPassword)
        }
        
        // Validate password confirmation
        if password != confirmPassword {
            validationErrors.insert(.passwordMismatch)
        }
        
        // Validate display name
        if displayName.trimmingCharacters(in: .whitespaces).count < 3 {
            validationErrors.insert(.invalidPassword)
        }
        
        return validationErrors.isEmpty
    }
    
    /// Attempts to register new user
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Secure user registration
    /// - Data Security (5.2.1): Secure credential handling
    public func register() async throws {
        isLoading = true
        error = nil
        
        do {
            // Validate form input
            guard validateForm() else {
                throw validationErrors.first ?? RegistrationError.invalidPassword
            }
            
            // Create user profile
            let profile = UserProfile(
                displayName: displayName.trimmingCharacters(in: .whitespaces)
            )
            
            // Attempt registration
            try await authService.register(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                profile: profile
            )
            
            // Clear form on success
            clearForm()
        } catch let authError as AuthError {
            switch authError {
            case .registrationError:
                error = RegistrationError.emailTaken
            default:
                error = authError
            }
            throw error!
        } catch {
            self.error = error
            throw error
        } finally {
            isLoading = false
        }
    }
    
    /// Securely clears form data
    /// Requirements addressed:
    /// - Data Security (5.2.1): Secure data handling
    public func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
        validationErrors.removeAll()
        error = nil
    }
}