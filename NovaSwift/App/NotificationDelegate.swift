//
//  NotificationDelegate.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 04.01.26.
//

import Foundation
import SwiftUI
import UserNotifications

/// A delegate class for handling user notifications within the application.
///
/// `NotificationDelegate` conforms to `UNUserNotificationCenterDelegate` to manage how notifications
/// are presented when the app is in the foreground. It also provides a static helper method
/// to request notification authorization from the user.
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    /// Handles a notification delivered to a foreground app.
    ///
    /// This method is called when a notification is delivered while the app is running in the foreground.
    /// It configures the system to present the notification as a banner and play a sound, overriding
    /// the default behavior which might suppress notifications for foreground apps.
    ///
    /// - Parameters:
    ///   - center: The shared user notification center object that manages the notification-related activities.
    ///   - notification: The notification that is being delivered.
    ///   - completionHandler: The block to execute with the presentation options for the notification.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification even if the app is in the foreground
        completionHandler([.banner, .sound])
    }
    
    /// Requests the user's authorization to display local notifications.
    ///
    /// This method requests permission for `.alert` (banners) and `.sound`.
    /// It logs an error to the console if authorization fails.
    ///
    /// - Note: This should typically be called at app launch.
    static func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization failed: \(error.localizedDescription)")
            }
        }
    }
}
