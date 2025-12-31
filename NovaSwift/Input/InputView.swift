//
//  EditorView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 29.12.25.
//

import SwiftUI

struct InputView: View {
    @Binding var editorText: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder Text
            if editorText.isEmpty {
                Text("Write or import your code here...")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(white: 0.4)) // Dark gray text
                    .padding(.leading, 45) // Match ruler width + padding
                    .padding(.top, 10)     // Match text container inset
                    .allowsHitTesting(false) // Let clicks pass through to the editor
                    .zIndex(1) // Ensure it sits on top of the background but below cursor if needed
            }
            
            SyntaxHighlightEditor(text: $editorText)
                .padding(0)
        }
    }
}

#Preview {
    @Previewable @State var editorText: String = "Preview Text"
    InputView(editorText: $editorText)
}
