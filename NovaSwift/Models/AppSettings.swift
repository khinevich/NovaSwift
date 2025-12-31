//
//  AppSettings.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 31.12.25.
//

import SwiftUI
import AppKit

/// Represents the visual theme of the application.
enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    
    var id: String { rawValue }
    
    /// The user-friendly display name of the theme.
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

/// A collection of colors corresponding to a specific `AppTheme`.
///
/// This structure defines the color palette used for syntax highlighting and UI elements
/// for a given theme.
struct ThemeColors {
    let background: NSColor
    let text: NSColor
    let insertionPoint: NSColor
    let lineNumbers: NSColor
    
    // Syntax
    let keyword: NSColor
    let type: NSColor
    let string: NSColor
    let number: NSColor
    let comment: NSColor
    let attribute: NSColor
    let call: NSColor
    let plain: NSColor
    
    /// Returns the color palette for the specified theme.
    ///
    /// - Parameter theme: The `AppTheme` to get colors for.
    /// - Returns: A `ThemeColors` instance with the defined palette.
    static func forTheme(_ theme: AppTheme) -> ThemeColors {
        switch theme {
        case .dark:
            return ThemeColors(
                background: NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0), // #1E1E1E
                text: .white,
                insertionPoint: .white,
                lineNumbers: NSColor(white: 0.5, alpha: 1.0),
                keyword: NSColor(red: 0.87, green: 0.63, blue: 0.87, alpha: 1.0), // #DDA0DD
                type: NSColor(red: 0.57, green: 0.83, blue: 0.38, alpha: 1.0), // #91D462
                string: NSColor(red: 1.0, green: 0.51, blue: 0.44, alpha: 1.0), // #FF8170
                number: NSColor(red: 0.85, green: 0.79, blue: 0.49, alpha: 1.0), // #D9C97C
                comment: NSColor(red: 0.42, green: 0.47, blue: 0.53, alpha: 1.0), // #6C7986
                attribute: NSColor(red: 0.69, green: 0.56, blue: 0.94, alpha: 1.0), // #B190F0
                call: NSColor(red: 0.31, green: 0.69, blue: 0.73, alpha: 1.0), // #4EB1BA
                plain: .white
            )
        case .light:
            return ThemeColors(
                background: .white,
                text: .black,
                insertionPoint: .black,
                lineNumbers: NSColor(white: 0.6, alpha: 1.0),
                keyword: NSColor(red: 0.6, green: 0.0, blue: 0.6, alpha: 1.0), // Purple
                type: NSColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0), // Green
                string: NSColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0), // Red
                number: NSColor(red: 0.0, green: 0.0, blue: 0.8, alpha: 1.0), // Blue
                comment: NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0), // Gray
                attribute: NSColor(red: 0.4, green: 0.3, blue: 0.6, alpha: 1.0), // Purple/Blue
                call: NSColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0), // Blue-ish
                plain: .black
            )
        }
    }
}
