//
//  PaneBar.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 31.12.25.
//

import SwiftUI

/// A styled header bar component used for the top of pane containers (e.g., Input and Output views).
///
/// This view provides a consistent layout for pane headers, including a background,
/// padding, and a bottom divider. It is designed to host a horizontal stack of controls.
struct PaneBar<Content: View>: View {
    /// The content to be displayed within the pane bar, typically a collection of buttons and text.
    @ViewBuilder var content: Content
    
    var body: some View {
        HStack(spacing: 12) {
            content
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .buttonStyle(.borderless)
    }
}
