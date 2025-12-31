//
//  OutputConsoleView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 31.12.25.
//

import SwiftUI

/// A presentational view that displays the read-only console output.
///
/// This view wraps the `ConsoleTextView` to provide a scrollable, styled display
/// for the script execution results.
struct OutputConsoleView: View {
    // MARK: - Properties
    
    /// The text content to display in the console.
    let text: String
    
    // MARK: - Settings
    
    @AppStorage("appTheme") private var currentTheme: AppTheme = .dark
    @AppStorage("editorFontSize") private var fontSize: Double = 14.0
    
    // MARK: - Body
    
    var body: some View {
        ConsoleTextView(text: text, fontSize: fontSize, theme: currentTheme)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
