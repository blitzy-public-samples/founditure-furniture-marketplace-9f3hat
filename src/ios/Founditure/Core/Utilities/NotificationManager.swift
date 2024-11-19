//
// NotificationManager.swift
// Founditure
//
// Human Tasks:
// 1. Configure Firebase Cloud Messaging in Firebase Console
// 2. Add required capabilities in Xcode (Push Notifications, Background Modes)
// 3. Add GoogleService-Info.plist to the project
// 4. Configure APNs authentication key in Firebase Console
// 5. Test push notification delivery in development and production environments

import UserNotifications // Latest
import FirebaseMessaging // v10.0.0
import Foundation // Latest

// Relative imports
import "../Models/Notification"
import "../Core/Constants/AppConstants"

/// Addresses requirements:
/// - 2.2.1 Core Components - Real-time messaging and notification system
/// - 1.2 System Overview - 70% monthly active user retention through engagement features
@objc class NotificationManager: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    // MARK: - Properties
    
    /// Singleton instance for centralized notification management
    static let shared = NotificationManager()
    
    /// User notification center instance
    private let center: UNUserNotificationCenter
    
    /// Firebase messaging delegate
    private let messagingDelegate: MessagingDelegate
    
    /// Dictionary to store notification handlers for different notification types
    private var notificationHandlers: [NotificationType: ((Notification) -> Void)]
    
    // MARK: - Initialization
    
    private override init() {
        self.center = UNUserNotificationCenter.current()
        self.messagingDelegate = Messaging.messaging().delegate as? MessagingDelegate ?? MessagingDelegate()
        self.notificationHandlers = [:]
        
        super.init()
        
        // Configure notification center delegate
        center.delegate = self
        Messaging.messaging().delegate = self
        
        // Setup notification categories and actions
        configureNotificationCategories()
    }
    
    // MARK: - Public Methods
    
    /// Request notification permissions and configure Firebase messaging
    /// - Parameter completion: Callback with authorization status
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard Features.enablePushNotifications else {
            completion(false)
            return
        }
        
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        center.requestAuthorization(options: options) { [weak self] granted, error in
            guard error == nil else {
                completion(false)
                return
            }
            
            if granted {
                self?.configureFirebaseMessaging()
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            completion(granted)
        }
    }
    
    /// Schedule a local notification
    /// - Parameters:
    ///   - notification: Notification object containing content
    ///   - delay: Time interval after which to show the notification
    func scheduleLocalNotification(notification: Notification, delay: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        
        // Set notification priority
        switch notification.priority {
        case .high:
            content.interruptionLevel = .timeSensitive
        case .normal:
            content.interruptionLevel = .active
        case .low:
            content.interruptionLevel = .passive
        }
        
        // Add metadata as userInfo
        if let metadata = notification.metadata {
            content.userInfo = metadata
        }
        
        // Create trigger with specified delay
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        // Create request with unique identifier
        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// Handle received notification
    /// - Parameter notification: Received notification object
    func handleNotification(_ notification: Notification) {
        if let handler = notificationHandlers[notification.type] {
            handler(notification)
        }
        
        // Mark notification as read
        notification.markAsRead()
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: NSNotification.Name("NotificationReceived"),
            object: nil,
            userInfo: ["notification": notification]
        )
    }
    
    /// Register handler for specific notification type
    /// - Parameters:
    ///   - type: Type of notification to handle
    ///   - handler: Handler closure to be executed when notification is received
    func registerNotificationHandler(type: NotificationType, handler: @escaping (Notification) -> Void) {
        notificationHandlers[type] = handler
    }
    
    // MARK: - Private Methods
    
    private func configureNotificationCategories() {
        let categories: Set<UNNotificationCategory> = [
            UNNotificationCategory(
                identifier: "default",
                actions: [],
                intentIdentifiers: [],
                options: .customDismissAction
            )
        ]
        center.setNotificationCategories(categories)
    }
    
    private func configureFirebaseMessaging() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM token: \(error.localizedDescription)")
                return
            }
            if let token = token {
                print("FCM token: \(token)")
                // TODO: Send token to backend for storage
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        // Handle notification response based on userInfo
        completionHandler()
    }
    
    // MARK: - MessagingDelegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("Refreshed FCM token: \(token)")
            // TODO: Update token on backend if changed
        }
    }
}