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
/// empty state message.
struct InputEditorView: View {
    // MARK: - Bindings
    
    /// A binding to the text content being edited.
    @Binding var text: String
    
    // MARK: - Settings
    
    @AppStorage("appTheme") private var currentTheme: AppTheme = .dark
    @AppStorage("editorFontSize") private var fontSize: Double = 14.0
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder Text
            if text.isEmpty {
                Text("Write or import your code here...")
                    .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(white: 0.4))
                    .padding(.leading, 45) // Match ruler width + padding
                    .padding(.top, 10)     // Match text container inset
                    .allowsHitTesting(false)
                    .zIndex(1)
            }
            
            SyntaxHighlightEditor(text: $text, fontSize: fontSize, theme: currentTheme)
                .padding(0)
                .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
