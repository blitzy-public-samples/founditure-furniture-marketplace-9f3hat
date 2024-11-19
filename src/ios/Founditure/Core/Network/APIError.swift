// Foundation framework - Latest
import Foundation

/// Human Tasks:
/// 1. Ensure proper error logging configuration is set up in the monitoring system
/// 2. Verify that error messages are properly localized for all supported languages
/// 3. Configure appropriate timeout intervals based on network conditions
/// 4. Set up proper SSL/TLS certificate validation for network security

// MARK: - APIError
/// Comprehensive error type for handling network-related errors in the Founditure app
/// Requirements addressed:
/// - Network Security (5.3.1): Implements secure error handling for network operations
/// - API Architecture (3.3.1): Provides standardized error handling for REST/HTTP/2
/// - Error Monitoring (2.4.1): Includes detailed error information for monitoring
public enum APIError: Error, LocalizedError {
    /// Request construction or parameter validation failed
    case invalidRequest(String)
    
    /// Server response had unexpected format or status code
    case invalidResponse(Int)
    
    /// Response data could not be decoded to expected type
    case decodingError(Error)
    
    /// Network transmission or connectivity error
    case networkError(Error)
    
    /// Server returned an explicit error message
    case serverError(String)
    
    /// Authentication failed or token is invalid
    case unauthorized
    
    /// Device has no internet connectivity
    case noInternet
    
    /// Request exceeded timeout threshold
    case timeout(TimeInterval)
    
    /// Server enforced rate limiting
    case rateLimited(Int)
    
    // MARK: - LocalizedError Protocol Properties
    
    public var errorDescription: String {
        switch self {
        case .invalidRequest(let details):
            return "Invalid request: \(details)"
        case .invalidResponse(let statusCode):
            return "Invalid response received (Status: \(statusCode))"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error occurred: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unauthorized:
            return "Unauthorized access"
        case .noInternet:
            return "No internet connection"
        case .timeout(let interval):
            return "Request timed out after \(String(format: "%.1f", interval)) seconds"
        case .rateLimited(let retryAfter):
            return "Rate limit exceeded. Retry after \(retryAfter) seconds"
        }
    }
    
    public var errorCode: String {
        switch self {
        case .invalidRequest: return "FND_ERR_001"
        case .invalidResponse: return "FND_ERR_002"
        case .decodingError: return "FND_ERR_003"
        case .networkError: return "FND_ERR_004"
        case .serverError: return "FND_ERR_005"
        case .unauthorized: return "FND_ERR_006"
        case .noInternet: return "FND_ERR_007"
        case .timeout: return "FND_ERR_008"
        case .rateLimited: return "FND_ERR_009"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidRequest:
            return "Please verify the request parameters and try again"
        case .invalidResponse:
            return "Please try again later or contact support if the issue persists"
        case .decodingError:
            return "Please update to the latest version of the app"
        case .networkError:
            return "Please check your network connection and try again"
        case .serverError:
            return "Please try again later"
        case .unauthorized:
            return "Please sign in again"
        case .noInternet:
            return "Please check your internet connection"
        case .timeout:
            return "Please try again with a better network connection"
        case .rateLimited(let retryAfter):
            return "Please wait \(retryAfter) seconds before trying again"
        }
    }
    
    public var failureReason: String {
        switch self {
        case .invalidRequest:
            return "The request parameters were invalid or malformed"
        case .invalidResponse(let statusCode):
            return "Server returned unexpected status code: \(statusCode)"
        case .decodingError:
            return "Response data format was unexpected"
        case .networkError:
            return "Network communication failed"
        case .serverError:
            return "Server encountered an internal error"
        case .unauthorized:
            return "Authentication token is invalid or expired"
        case .noInternet:
            return "Device is offline"
        case .timeout:
            return "Network request exceeded timeout threshold"
        case .rateLimited:
            return "Too many requests in a short time period"
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize APIError from raw server response
    /// - Parameters:
    ///   - responseData: Raw response data from server
    ///   - statusCode: HTTP status code
    /// - Returns: Appropriate APIError case
    public init(responseData: Data, statusCode: Int) {
        // Handle different HTTP status code ranges
        switch statusCode {
        case 400:
            if let error = try? JSONDecoder().decode(ServerError.self, from: responseData) {
                self = .invalidRequest(error.message)
            } else {
                self = .invalidRequest("Bad Request")
            }
            
        case 401:
            self = .unauthorized
            
        case 403:
            self = .unauthorized
            
        case 429:
            if let retryAfter = try? JSONDecoder().decode(RateLimitError.self, from: responseData) {
                self = .rateLimited(retryAfter.retryAfterSeconds)
            } else {
                self = .rateLimited(60) // Default retry after 60 seconds
            }
            
        case 500...599:
            if let error = try? JSONDecoder().decode(ServerError.self, from: responseData) {
                self = .serverError(error.message)
            } else {
                self = .serverError("Internal Server Error")
            }
            
        default:
            self = .invalidResponse(statusCode)
        }
    }
    
    // MARK: - Utility Methods
    
    /// Convert error to dictionary for logging purposes
    /// - Returns: Dictionary containing error details
    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "errorCode": errorCode,
            "errorDescription": errorDescription,
            "failureReason": failureReason
        ]
        
        if let recovery = recoverySuggestion {
            dict["recoverySuggestion"] = recovery
        }
        
        // Add additional context based on error type
        switch self {
        case .invalidResponse(let statusCode):
            dict["statusCode"] = statusCode
        case .rateLimited(let retryAfter):
            dict["retryAfter"] = retryAfter
        case .timeout(let interval):
            dict["timeoutInterval"] = interval
        default:
            break
        }
        
        return dict
    }
}

// MARK: - Supporting Types

private struct ServerError: Decodable {
    let message: String
}

private struct RateLimitError: Decodable {
    let retryAfterSeconds: Int
    
    private enum CodingKeys: String, CodingKey {
        case retryAfterSeconds = "retry_after"
    }
}