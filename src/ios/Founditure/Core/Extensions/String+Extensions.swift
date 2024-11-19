//
// String+Extensions.swift
// Founditure
//
// Human Tasks:
// 1. Review email regex pattern with security team to ensure it meets latest RFC standards
// 2. Validate address formatting rules with business team for international expansion
// 3. Confirm XSS sanitization rules cover all required security cases
//

import Foundation // Latest
import AppConstants

// MARK: - String Extensions
extension String {
    
    /// Addresses requirement: 5.3.2 Security Controls - Input Validation
    /// Validates if the string is a properly formatted email address using RFC 5322 compliant regex
    var isValidEmail: Bool {
        let emailRegex = "^(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self.lowercased())
    }
    
    /// Addresses requirement: 5.3.2 Security Controls - Input Validation
    /// Validates if the string meets password security requirements
    var isValidPassword: Bool {
        guard self.count >= Security.minimumPasswordLength else { return false }
        
        let uppercaseRegex = ".*[A-Z]+.*"
        let lowercaseRegex = ".*[a-z]+.*"
        let numberRegex = ".*[0-9]+.*"
        let specialCharRegex = ".*[^A-Za-z0-9]+.*"
        
        let uppercasePredicate = NSPredicate(format: "SELF MATCHES %@", uppercaseRegex)
        let lowercasePredicate = NSPredicate(format: "SELF MATCHES %@", lowercaseRegex)
        let numberPredicate = NSPredicate(format: "SELF MATCHES %@", numberRegex)
        let specialCharPredicate = NSPredicate(format: "SELF MATCHES %@", specialCharRegex)
        
        return uppercasePredicate.evaluate(with: self) &&
               lowercasePredicate.evaluate(with: self) &&
               numberPredicate.evaluate(with: self) &&
               specialCharPredicate.evaluate(with: self)
    }
    
    /// Addresses requirement: 5.3.3 Security Compliance/Data Privacy
    /// Returns a sanitized version of the string with potentially harmful characters escaped
    var sanitized: String {
        var sanitized = self
        
        // Remove HTML tags
        sanitized = sanitized.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Escape special characters
        let specialCharacters: [String: String] = [
            "<": "&lt;",
            ">": "&gt;",
            "&": "&amp;",
            "\"": "&quot;",
            "'": "&#39;"
        ]
        
        for (char, escaped) in specialCharacters {
            sanitized = sanitized.replacingOccurrences(of: char, with: escaped)
        }
        
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Addresses requirement: 1.3 Scope/Implementation Boundaries - Support English language formatting
    /// Formats string as a standardized US phone number
    var formatPhoneNumber: String {
        let numbers = self.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        guard numbers.count == 10 else { return self }
        
        let areaCode = numbers.prefix(3)
        let prefix = numbers.dropFirst(3).prefix(3)
        let line = numbers.dropFirst(6)
        
        return "(\(areaCode)) \(prefix)-\(line)"
    }
    
    /// Addresses requirement: 1.3 Scope/Implementation Boundaries - Support English language formatting
    /// Formats string as a standardized US address
    var formatAddress: String {
        let components = self.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard !components.isEmpty else { return self }
        
        let stateAbbreviations: [String: String] = [
            "alabama": "AL", "alaska": "AK", "arizona": "AZ",
            // Add all state mappings as needed
        ]
        
        var formattedComponents: [String] = []
        
        for (index, component) in components.enumerated() {
            var formatted = component.capitalized
            
            // Don't capitalize articles except at start
            let articles = ["The", "A", "An", "And", "Or", "Of", "For", "To"]
            for article in articles {
                formatted = formatted.replacingOccurrences(
                    of: " \(article) ",
                    with: " \(article.lowercased()) "
                )
            }
            
            // Handle state abbreviations in the last component
            if index == components.count - 1 {
                let parts = formatted.components(separatedBy: " ")
                if parts.count >= 2,
                   let stateAbbr = stateAbbreviations[parts[0].lowercased()] {
                    // Format ZIP code if present
                    let zip = parts.last?.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    if let zip = zip, zip.count == 5 {
                        formatted = "\(stateAbbr) \(zip)"
                    } else {
                        formatted = stateAbbr
                    }
                }
            }
            
            formattedComponents.append(formatted)
        }
        
        return formattedComponents.joined(separator: ", ")
    }
    
    /// Returns truncated string with ellipsis if exceeds specified length
    func truncated(length: Int) -> String {
        guard self.count > length else { return self }
        return String(self.prefix(length - 3)) + "..."
    }
}