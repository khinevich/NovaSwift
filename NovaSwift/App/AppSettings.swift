//
//  AppSettings.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 05.01.26.
//

import Foundation
import SwiftUI

/// Centralized manager for application-wide settings.
/// This ensures key names are defined once and stay consistent.
///
/// Singleton
@Observable
class AppSettings {
    static let shared = AppSettings()
    
    // Define your keys as constants to avoid typos
    private enum Keys {
        static let appTheme = "appTheme"
        static let fontSize = "editorFontSize"
        static let swiftPath = "customSwiftPath"
        static let kotlinPath = "customKotlinPath"
    }
    
    @ObservationIgnored private let defaults = UserDefaults.standard

    var theme: AppTheme {
        didSet {
            defaults.set(theme.rawValue, forKey: Keys.appTheme)
        }
    }
    
    var fontSize: Double {
        didSet {
            defaults.set(fontSize, forKey: Keys.fontSize)
        }
    }
    
    var swiftPath: String {
        didSet {
            defaults.set(swiftPath, forKey: Keys.swiftPath)
        }
    }
    
    var kotlinPath: String {
        didSet {
            defaults.set(kotlinPath, forKey: Keys.kotlinPath)
        }
    }

    private init() {
        self.theme = AppTheme(rawValue: UserDefaults.standard.string(forKey: Keys.appTheme) ?? "") ?? .dark
        
        let storedFontSize = UserDefaults.standard.double(forKey: Keys.fontSize)
        self.fontSize = storedFontSize == 0 ? 14.0 : storedFontSize
        
        self.swiftPath = UserDefaults.standard.string(forKey: Keys.swiftPath) ?? ""
        self.kotlinPath = UserDefaults.standard.string(forKey: Keys.kotlinPath) ?? ""
    }
}
