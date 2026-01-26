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
    
    /// The delegate responsible for handling user notifications.
    ///
    /// This state object is retained for the lifetime of the app to manage notification interactions.
    @State private var delegate = NotificationDelegate()
    
    /// Singleton for app settings
    @State private var settings = AppSettings.shared
    
    /// The initializer requests authorization for local notifications and assigns the
    /// notification center's delegate to handle incoming notifications.
    init() {
        NotificationDelegate.requestNotificationAuthorization()
        UNUserNotificationCenter.current().delegate = delegate
    }
    
    
    /// Configures the window toolbar style and registers a handler for custom URL schemes
    /// (e.g., `novaswift://`) to support deep linking.
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)
                .preferredColorScheme(settings.theme == .dark ? .dark : .light)
        }
        .windowToolbarStyle(.unified)
        .handlesExternalEvents(matching: ["novaswift"])
    }
}
