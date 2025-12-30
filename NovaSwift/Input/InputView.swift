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
            SyntaxHighlightEditor(text: $editorText)
                .padding(0) // NSTextView inside handles its own padding
        }
    }
}

#Preview {
    @Previewable @State var editorText: String = "Preview Text"
    InputView(editorText: $editorText)
}
