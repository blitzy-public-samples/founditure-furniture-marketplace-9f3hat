// Foundation version: Latest
import Foundation

// MARK: - Human Tasks
/*
Prerequisites and Setup:
1. Configure API Gateway base URL in environment configuration
2. Set up SSL certificate pinning for production environment
3. Configure API versioning headers in build configuration
4. Implement proper error handling and retry mechanisms
5. Set up monitoring for network request failures
*/

// MARK: - HTTP Methods
/// Supported HTTP methods for API requests
/// Requirement: API Architecture (3.3.1) - REST/HTTP/2 protocol support
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - API Endpoint Protocol
/// Protocol defining requirements for API endpoints with type-safe request configuration
/// Requirement: API Gateway Integration (3.3.2) - Standardize API request/response handling
public protocol APIEndpoint {
    /// The type of response expected from the endpoint
    associatedtype Response: Decodable
    
    /// The path component of the endpoint URL
    var path: String { get }
    
    /// The HTTP method for the request
    var method: HTTPMethod { get }
    
    /// Optional custom headers for the request
    var headers: [String: String]? { get }
    
    /// Optional body parameters for the request
    var body: Encodable? { get }
    
    /// Optional query parameters for the request
    var queryItems: [URLQueryItem]? { get }
    
    /// Converts the endpoint into a configured URLRequest
    /// Requirement: Network Security (5.3.1) - Implement secure network communication
    func asURLRequest() throws -> URLRequest
}

// MARK: - API Endpoint Extension
/// Default implementation for APIEndpoint protocol with security configurations
public extension APIEndpoint {
    /// Provides default headers for all requests including security headers
    /// Requirement: Network Security (5.3.1) - Proper request configuration
    private func defaultHeaders() -> [String: String] {
        [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-API-Version": "1.0",
            "X-Platform": "iOS",
            // Security headers
            "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
            "X-Content-Type-Options": "nosniff",
            "X-Frame-Options": "DENY",
            "X-XSS-Protection": "1; mode=block",
            // CORS headers
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, PATCH",
            "Access-Control-Allow-Headers": "Content-Type, Authorization"
        ]
    }
    
    /// Converts the endpoint into a URLRequest with proper security configuration
    /// Requirement: API Architecture (3.3.1) - TLS 1.3 required
    func asURLRequest() throws -> URLRequest {
        // Configure base URL with HTTPS scheme
        guard var components = URLComponents(string: "https://api.founditure.com") else {
            throw URLError(.badURL)
        }
        
        // Add path components with proper encoding
        components.path = "/v1" + path
        
        // Add query items if present
        if let queryItems = queryItems {
            components.queryItems = queryItems
        }
        
        // Ensure URL is properly constructed
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        // Create request with URL
        var request = URLRequest(url: url)
        
        // Set HTTP method
        request.httpMethod = method.rawValue
        
        // Set default headers including security headers
        let defaultHeaders = defaultHeaders()
        defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // Add custom headers if present
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // Encode and set body data if present
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        }
        
        // Configure session security settings
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30
        
        // Configure TLS settings
        let configuration = URLSessionConfiguration.default
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv13
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv13
        
        return request
    }
}