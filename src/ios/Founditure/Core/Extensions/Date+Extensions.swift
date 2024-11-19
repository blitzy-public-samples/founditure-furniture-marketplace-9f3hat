//
// Date+Extensions.swift
// Founditure
//
// Human Tasks:
// 1. Verify time formatting matches UI/UX design guidelines
// 2. Confirm cache expiration interval aligns with backend caching strategy
// 3. Review date formatting localization requirements for target markets

import Foundation // Latest
import AppConstants

// MARK: - Date Extension
/// Extends Date with utility functions for timestamp handling and formatting
/// throughout the Founditure application
extension Date {
    
    /// Returns a human-readable string representing time elapsed since this date
    /// Addresses requirement: Real-time Messaging - Enable message timestamp formatting and time-ago display
    func timeAgo() -> String {
        let interval = Date().timeIntervalSince(self)
        
        // Handle future dates
        if interval < 0 {
            return "just now"
        }
        
        // Define time intervals in seconds
        let minute: TimeInterval = 60
        let hour: TimeInterval = minute * 60
        let day: TimeInterval = hour * 24
        let week: TimeInterval = day * 7
        let month: TimeInterval = day * 30
        let year: TimeInterval = day * 365
        
        switch interval {
        case 0..<minute:
            return "just now"
        case minute..<hour:
            let minutes = Int(interval / minute)
            return "\(minutes)m ago"
        case hour..<day:
            let hours = Int(interval / hour)
            return "\(hours)h ago"
        case day..<week:
            let days = Int(interval / day)
            return "\(days)d ago"
        case week..<month:
            let weeks = Int(interval / week)
            return "\(weeks)w ago"
        case month..<year:
            let months = Int(interval / month)
            return "\(months)mo ago"
        default:
            let years = Int(interval / year)
            return "\(years)y ago"
        }
    }
    
    /// Checks if date has exceeded the cache expiration interval
    /// Addresses requirement: User Activity Tracking - Support user engagement time tracking and analytics
    func isExpired() -> Bool {
        let interval = Date().timeIntervalSince(self)
        return interval > AppConstants.Cache.expirationInterval
    }
    
    /// Returns date formatted according to specified DateFormatter style
    /// Addresses requirement: Listing Management - Support timestamp handling for furniture listings
    func formattedString(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: self)
    }
    
    /// Checks if date is on the same calendar day as another date
    /// Addresses requirement: Real-time Messaging - Enable message timestamp formatting and time-ago display
    func isSameDay(as otherDate: Date) -> Bool {
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.year, .month, .day]
        let selfComponents = calendar.dateComponents(components, from: self)
        let otherComponents = calendar.dateComponents(components, from: otherDate)
        
        return selfComponents.year == otherComponents.year &&
               selfComponents.month == otherComponents.month &&
               selfComponents.day == otherComponents.day
    }
    
    /// Returns new date by adding specified number of days
    /// Addresses requirement: Listing Management - Support timestamp handling for furniture listings
    func addingDays(_ days: Int) -> Date {
        let secondsInDay: TimeInterval = 86400
        let interval = TimeInterval(days) * secondsInDay
        return addingTimeInterval(interval)
    }
}