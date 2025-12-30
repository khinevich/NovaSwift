//
//  ConsoleTextView.swift
//  NovaSwift
//
//  Created by NovaSwift AI on 30.12.25.
//

import SwiftUI
import AppKit

struct ConsoleTextView: NSViewRepresentable {
    let text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .clear
        textView.textColor = .secondaryLabelColor
        
        // Layout configuration
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        scrollView.documentView = textView
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        // Update only if content changed to avoid unnecessary redraws/scroll jumps.
        if textView.string != text {
            textView.string = text
            
            // Auto-scroll logic:
            // For a console-like experience, we want to follow the output as it generates.
            // Simple implementation: Always scroll to the bottom when new text arrives.
            if !text.isEmpty {
                 textView.scrollToEndOfDocument(nil)
            }
        }
    }
}
