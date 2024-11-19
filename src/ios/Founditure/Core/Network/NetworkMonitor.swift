// Network framework - Latest
import Network
// Foundation framework - Latest
import Foundation
// Combine framework - Latest
import Combine
// Internal imports
import Core

/// Human Tasks:
/// 1. Configure network monitoring alerts and logging in the monitoring system
/// 2. Set up appropriate network security policies for different network types
/// 3. Verify VPN and proxy handling configurations
/// 4. Review and adjust network monitoring frequency based on battery impact

/// NetworkMonitor: Responsible for monitoring network connectivity status and providing real-time updates
/// Requirements addressed:
/// - Network Security (5.3.1): Monitors network connectivity and security status
/// - Error Handling (5.2.1): Handles network state changes with appropriate error propagation
/// - System Monitoring (2.4.1): Provides real-time network status monitoring
@MainActor
public final class NetworkMonitor {
    // MARK: - Private Properties
    
    /// Network path monitor instance for tracking connectivity
    private let monitor: NWPathMonitor
    
    /// Dedicated serial queue for network monitoring operations
    private let monitorQueue: DispatchQueue
    
    /// Current value subject for publishing connection status changes
    private let connectionStatus: CurrentValueSubject<Bool, Never>
    
    // MARK: - Public Properties
    
    /// Current network connection status
    public var isConnected: Bool {
        connectionStatus.value
    }
    
    /// Publisher for observing network connection status changes
    public let connectionStatusPublisher: AnyPublisher<Bool, Never>
    
    // MARK: - Initialization
    
    /// Initializes the network monitor with default configuration
    public init() {
        // Initialize NWPathMonitor instance
        self.monitor = NWPathMonitor()
        
        // Create dedicated serial dispatch queue for monitoring
        self.monitorQueue = DispatchQueue(label: "com.founditure.networkmonitor",
                                        qos: .utility)
        
        // Initialize connection status publisher with initial false value
        self.connectionStatus = CurrentValueSubject<Bool, Never>(false)
        
        // Set up connection status publisher as eraseToAnyPublisher
        self.connectionStatusPublisher = connectionStatus
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    // MARK: - Public Methods
    
    /// Starts monitoring network connectivity changes
    public func startMonitoring() {
        // Configure path monitoring handler to update connection status
        monitor.pathUpdateHandler = { [weak self] path in
            // Determine connection status based on path status
            let isConnected = path.status == .satisfied
            
            // Update connection status on main thread
            Task { @MainActor [weak self] in
                self?.connectionStatus.send(isConnected)
            }
        }
        
        // Set monitoring queue to dedicated dispatch queue
        monitor.start(queue: monitorQueue)
        
        // Update initial connection status
        connectionStatus.send(monitor.currentPath.status == .satisfied)
    }
    
    /// Stops monitoring network connectivity changes
    public func stopMonitoring() {
        // Cancel the network path monitor
        monitor.cancel()
        
        // Update connection status to disconnected
        connectionStatus.send(false)
    }
    
    /// Checks current network connectivity status
    /// - Throws: APIError.noInternet if device is disconnected
    /// - Returns: True if connected
    public func checkConnectivity() throws -> Bool {
        // Check current connection status value
        guard isConnected else {
            throw APIError.noInternet
        }
        
        return true
    }
    
    // MARK: - Deinitialization
    
    deinit {
        stopMonitoring()
    }
}