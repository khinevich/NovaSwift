//
//  InputEditorView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 31.12.25.
//

import SwiftUI

/// A presentational view that displays a syntax-highlighted text editor with a placeholder.
///
/// This view wraps the underlying `SyntaxHighlightEditor` and provides a user-friendly
/// empty state message. It serves as the primary interface for editing code within the application.
struct InputEditorView: View {
    // MARK: - Bindings
    
    /// A binding to the text content being edited.
    /// Changes here are propagated back to the parent container.
    @Binding var text: String
    
    /// The language of the code being edited.
    ///
    /// This property determines the syntax highlighting rules applied by the editor.
    /// Defaults to `.swift`.
    var language: Language = .swift
    
    // MARK: - Settings
    
    /// The current application theme (Light/Dark), retrieved from `AppStorage`.
    @AppStorage("appTheme") private var currentTheme: AppTheme = .dark
    
    /// The font size for the editor, retrieved from `AppStorage`.
    @AppStorage("editorFontSize") private var fontSize: Double = 14.0
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder Text
            // Displayed only when the editor text is empty to guide the user.
            if text.isEmpty {
                Text("Write or import your code here...")
                    .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(white: 0.4))
                    .padding(.leading, 45) // Match ruler width + padding
                    .padding(.top, 10)     // Match text container inset
                    .allowsHitTesting(false) // Allow clicks to pass through to the editor
                    .zIndex(1)
            }
            
            // The core editor component handling text input and syntax highlighting.
            SyntaxHighlightEditor(text: $text, fontSize: fontSize, theme: currentTheme, language: language)
                .padding(0)
                .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}