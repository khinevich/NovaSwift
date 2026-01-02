//
//  NovaSwiftApp.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 29.12.25.
//

import SwiftUI
import UserNotifications

@main
struct NovaSwiftApp: App {
    @State private var delegate = NotificationDelegate()
    
    init() {
        requestNotificationAuthorization()
        UNUserNotificationCenter.current().delegate = delegate
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowToolbarStyle(.unified)
        .handlesExternalEvents(matching: ["novaswift"])
    }
    
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization failed: \(error.localizedDescription)")
            }
        }
    }
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification even if the app is in the foreground
        completionHandler([.banner, .sound])
    }
}
