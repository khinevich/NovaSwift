//
//  SettingsModel.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 03.01.26.
//

import Foundation
import UserNotifications
import SwiftUI

/// A model class that manages settings-related logic, particularly notification permissions and executable path resolution.
@Observable
class SettingsModel {
    /// The current authorization status for local notifications.
    var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    /// A textual representation of the notification status.
    var statusText: String {
        switch notificationStatus {
        case .authorized: return "Authorized"
        case .denied: return "Denied (Enable in System Settings)"
        case .notDetermined: return "Not Determined"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
    
    /// The color associated with the current notification status.
    var statusColor: Color {
        switch notificationStatus {
        case .authorized: return .green
        case .denied: return .red
        default: return .secondary
        }
    }
    
    /// Checks the current notification authorization status and updates `notificationStatus`.
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    /// Requests authorization for local notifications (alert and sound).
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            self.checkNotificationStatus()
        }
    }
    
    /// Opens the system settings for notification preferences.
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Resolves the path for a given executable name.
    ///
    /// - Parameter name: The name of the executable (e.g., "swift").
    /// - Returns: The absolute path to the executable if found, otherwise "Not found".
    func resolvePath(for name: String) -> String {
        if let url = ScriptExecutor.findExecutable(named: name) {
            return url.path
        }
        return "Not found"
    }
}
