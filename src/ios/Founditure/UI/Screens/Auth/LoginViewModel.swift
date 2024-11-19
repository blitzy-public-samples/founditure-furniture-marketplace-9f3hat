// Foundation framework - Latest
import Foundation
// Combine framework - Latest
import Combine
// LocalAuthentication framework - Latest
import LocalAuthentication

/// Human Tasks:
/// 1. Configure proper error logging for authentication failures
/// 2. Set up analytics tracking for login attempts
/// 3. Review biometric authentication settings with security team
/// 4. Verify proper handling of background authentication state

/// LoginState: Defines possible states during login process
/// Requirements addressed:
/// - Authentication Methods (5.1.1): Comprehensive state management for auth flow
public enum LoginState {
    case idle
    case loading
    case success(User)
    case error(AuthError)
}

/// LoginViewModel: Manages login screen state and authentication logic
/// Requirements addressed:
/// - Authentication Methods (5.1.1): Implementation of email/password and biometric authentication
/// - Security Controls (5.3.2): Secure authentication flow with input validation
@MainActor
public class LoginViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published public var email: String = ""
    @Published public var password: String = ""
    @Published public var state: LoginState = .idle
    @Published public var isBiometricsAvailable: Bool = false
    
    // MARK: - Private Properties
    
    private let authService: AuthService
    private let biometricContext = LAContext()
    
    // MARK: - Constants
    
    private enum Constants {
        static let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        static let minimumPasswordLength = 8
    }
    
    // MARK: - Initialization
    
    /// Initializes the login view model with authentication service
    /// - Parameter authService: Service handling authentication operations
    public init(authService: AuthService) {
        self.authService = authService
        
        // Check biometric authentication availability
        var error: NSError?
        isBiometricsAvailable = biometricContext.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
    }
    
    // MARK: - Public Methods
    
    /// Attempts to log in user with email and password credentials
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Email/password authentication implementation
    /// - Security Controls (5.3.2): Input validation and secure auth flow
    public func login() async {
        // Validate input before attempting login
        guard validateInput() else {
            state = .error(.invalidCredentials)
            return
        }
        
        // Update state to loading
        state = .loading
        
        do {
            // Attempt login with provided credentials
            let user = try await authService.login(email: email, password: password)
            
            // Verify token validity
            guard user.isTokenValid() else {
                state = .error(.tokenExpired)
                return
            }
            
            // Update state with successful login
            state = .success(user)
        } catch let error as AuthError {
            // Handle specific authentication errors
            state = .error(error)
        } catch {
            // Handle unexpected errors
            state = .error(.networkError)
        }
    }
    
    /// Attempts biometric authentication if available
    /// Requirements addressed:
    /// - Authentication Methods (5.1.1): Biometric authentication implementation
    public func loginWithBiometrics() async {
        // Verify biometric authentication is available
        guard isBiometricsAvailable else {
            state = .error(.biometricError)
            return
        }
        
        // Update state to loading
        state = .loading
        
        do {
            // Attempt biometric authentication
            let success = try await authService.authenticateWithBiometrics()
            
            if success {
                // Verify token validity after biometric auth
                guard let user = try? await authService.currentUser,
                      user.isTokenValid() else {
                    state = .error(.tokenExpired)
                    return
                }
                
                state = .success(user)
            } else {
                state = .error(.biometricError)
            }
        } catch let error as AuthError {
            // Handle specific authentication errors
            state = .error(error)
        } catch {
            // Handle unexpected errors
            state = .error(.biometricError)
        }
    }
    
    /// Validates user input credentials format
    /// Requirements addressed:
    /// - Security Controls (5.3.2): Input validation implementation
    private func validateInput() -> Bool {
        // Validate email format using regex
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", Constants.emailRegex)
        let isEmailValid = emailPredicate.evaluate(with: email)
        
        // Validate password requirements
        let isPasswordValid = password.count >= Constants.minimumPasswordLength
        
        return isEmailValid && isPasswordValid
    }
}