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
            TextEditor(text: $editorText)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color(NSColor.textBackgroundColor))
                .padding(4)
        }
    }
}

#Preview {
    @Previewable @State var editorText: String = "Preview Text"
    @Previewable @State var isRunning: Bool = false
    
    InputView(editorText: $editorText)
}
