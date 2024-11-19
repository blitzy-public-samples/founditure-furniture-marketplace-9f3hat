// Foundation framework - Latest
import Foundation
// Combine framework - Latest
import Combine

/// Human Tasks:
/// 1. Configure SSL certificate pinning in production environment
/// 2. Set up proper error logging and monitoring system
/// 3. Configure network security policies for different network types
/// 4. Review and adjust request timeout values based on network conditions
/// 5. Verify proper handling of background network tasks

/// APIClient: Main API client for making secure network requests
/// Requirements addressed:
/// - API Architecture (3.3.1): Implements REST/HTTP/2 protocol with TLS 1.3
/// - Network Security (5.3.1): Implements secure network communication with proper error handling
/// - Data Security (5.2.1): Ensures secure data transmission with TLS 1.3
@MainActor
public final class APIClient {
    // MARK: - Private Properties
    
    private let session: URLSession
    private let networkMonitor: NetworkMonitor
    private let decoder: JSONDecoder
    private let baseURL: String
    
    // MARK: - Constants
    
    private enum Constants {
        static let defaultTimeout: TimeInterval = 30
        static let uploadTimeout: TimeInterval = 60
        static let downloadTimeout: TimeInterval = 60
        static let baseURL = "https://api.founditure.com/v1"
    }
    
    // MARK: - Initialization
    
    /// Initializes the API client with custom configuration
    /// - Parameters:
    ///   - session: Optional custom URLSession (defaults to configured session)
    ///   - networkMonitor: Optional custom NetworkMonitor (defaults to new instance)
    public init(session: URLSession? = nil, networkMonitor: NetworkMonitor? = nil) {
        // Configure URLSession with security settings
        let configuration = URLSessionConfiguration.default
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv13
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv13
        configuration.timeoutIntervalForRequest = Constants.defaultTimeout
        configuration.timeoutIntervalForResource = Constants.defaultTimeout
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        // Set security headers
        configuration.httpAdditionalHeaders = [
            "X-Security-Version": "1.0",
            "X-Platform": "iOS",
            "X-Client-Version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        ]
        
        self.session = session ?? URLSession(configuration: configuration)
        self.networkMonitor = networkMonitor ?? NetworkMonitor()
        
        // Configure JSON decoder
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        self.baseURL = Constants.baseURL
        
        // Start network monitoring
        self.networkMonitor.startMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Performs a type-safe API request
    /// - Parameter endpoint: The API endpoint to request
    /// - Returns: Decoded response of type specified by endpoint
    public func request<T: APIEndpoint>(_ endpoint: T) async throws -> T.Response {
        // Check network connectivity
        try networkMonitor.checkConnectivity()
        
        // Create and validate request
        var urlRequest = try endpoint.asURLRequest()
        
        // Add base URL if not already present
        if urlRequest.url?.host == nil,
           let baseURL = URL(string: baseURL),
           let endpointURL = urlRequest.url {
            urlRequest.url = baseURL.appendingPathComponent(endpointURL.path)
        }
        
        // Perform request
        let (data, response) = try await session.data(for: urlRequest)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(0)
        }
        
        // Check status code
        switch httpResponse.statusCode {
        case 200...299:
            // Attempt to decode response
            do {
                return try decoder.decode(T.Response.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        default:
            // Handle error response
            throw APIError(responseData: data, statusCode: httpResponse.statusCode)
        }
    }
    
    /// Uploads data to specified endpoint
    /// - Parameters:
    ///   - data: Data to upload
    ///   - endpoint: The API endpoint for upload
    /// - Returns: Decoded response from the server
    public func uploadData<T: APIEndpoint>(_ data: Data, endpoint: T) async throws -> T.Response {
        // Check network connectivity
        try networkMonitor.checkConnectivity()
        
        // Create upload request
        var urlRequest = try endpoint.asURLRequest()
        urlRequest.timeoutInterval = Constants.uploadTimeout
        
        // Add base URL if needed
        if urlRequest.url?.host == nil,
           let baseURL = URL(string: baseURL),
           let endpointURL = urlRequest.url {
            urlRequest.url = baseURL.appendingPathComponent(endpointURL.path)
        }
        
        // Set upload data
        urlRequest.httpBody = data
        
        // Perform upload
        let (responseData, response) = try await session.upload(for: urlRequest, from: data)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(0)
        }
        
        // Check status code
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.Response.self, from: responseData)
            } catch {
                throw APIError.decodingError(error)
            }
        default:
            throw APIError(responseData: responseData, statusCode: httpResponse.statusCode)
        }
    }
    
    /// Downloads data from specified endpoint
    /// - Parameter endpoint: The API endpoint for download
    /// - Returns: Downloaded data
    public func downloadData<T: APIEndpoint>(_ endpoint: T) async throws -> Data {
        // Check network connectivity
        try networkMonitor.checkConnectivity()
        
        // Create download request
        var urlRequest = try endpoint.asURLRequest()
        urlRequest.timeoutInterval = Constants.downloadTimeout
        
        // Add base URL if needed
        if urlRequest.url?.host == nil,
           let baseURL = URL(string: baseURL),
           let endpointURL = urlRequest.url {
            urlRequest.url = baseURL.appendingPathComponent(endpointURL.path)
        }
        
        // Perform download
        let (data, response) = try await session.data(for: urlRequest)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(0)
        }
        
        // Check status code
        switch httpResponse.statusCode {
        case 200...299:
            return data
        default:
            throw APIError(responseData: data, statusCode: httpResponse.statusCode)
        }
    }
    
    // MARK: - Deinitialization
    
    deinit {
        networkMonitor.stopMonitoring()
    }
}