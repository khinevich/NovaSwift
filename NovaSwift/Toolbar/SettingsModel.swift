//
//  SettingsModel.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 03.01.26.
//

import Foundation
import UserNotifications
import SwiftUI

@Observable
class SettingsModel {
    var notificationStatus: UNAuthorizationStatus = .notDetermined
    
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
    
    var statusColor: Color {
        switch notificationStatus {
        case .authorized: return .green
        case .denied: return .red
        default: return .secondary
        }
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            self.checkNotificationStatus()
        }
    }
    
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func resolvePath(for name: String) -> String {
        if let url = ScriptExecutor.findExecutable(named: name) {
            return url.path
        }
        return "Not found"
    }
}
