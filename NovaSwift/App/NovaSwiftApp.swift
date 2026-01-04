//
//  NovaSwiftApp.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 29.12.25.
//

import SwiftUI
import UserNotifications

@main
/// The main entry point for the NovaSwift application.
///
/// This struct conforms to the `App` protocol and configures the application's lifecycle.
/// It sets up the main window group and handles global configurations such as notification authorization.
struct NovaSwiftApp: App {
    /// The delegate responsible for handling user notifications.
    ///
    /// This state object is retained for the lifetime of the app to manage notification interactions.
    @State private var delegate = NotificationDelegate()
    
    /// Initializes the application.
    ///
    /// The initializer requests authorization for local notifications and assigns the
    /// notification center's delegate to handle incoming notifications.
    init() {
        NotificationDelegate.requestNotificationAuthorization()
        UNUserNotificationCenter.current().delegate = delegate
    }
    
    /// The content of the application's scenes.
    ///
    /// Defines a single `WindowGroup` containing `ContentView` as the root view.
    /// It also configures the window toolbar style and registers a handler for custom URL schemes
    /// (e.g., `novaswift://`) to support deep linking.
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowToolbarStyle(.unified)
        .handlesExternalEvents(matching: ["novaswift"])
    }
}
