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
        
        // Dark Theme
        let darkBackground = NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
        textView.backgroundColor = darkBackground
        textView.textColor = NSColor(white: 0.8, alpha: 1.0) // Light gray text
        
        // Add padding
        textView.textContainerInset = NSSize(width: 5, height: 10)
        
        // Delegate is needed to intercept link clicks
        textView.delegate = context.coordinator
        
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
            // Apply text with link detection
            context.coordinator.updateTextWithLinks(textView, text: text)
            
            // Auto-scroll logic:
            if !text.isEmpty {
                 textView.scrollToEndOfDocument(nil)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ConsoleTextView
        
        init(_ parent: ConsoleTextView) {
            self.parent = parent
        }
        
        func updateTextWithLinks(_ textView: NSTextView, text: String) {
            let attributedString = NSMutableAttributedString(string: text)
            let fullRange = NSRange(location: 0, length: text.utf16.count)
            
            // Default styling
            attributedString.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular), range: fullRange)
            attributedString.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: fullRange)
            
            // Detect patterns: /path/to/script.swift:LINE:COL
            // Regex: [^:]+\.swift:(\d+):(\d+)
            let pattern = "[^:]+\\.swift:(\\d+):(\\d+)"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                regex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
                    guard let match = match, match.numberOfRanges == 3 else { return }
                    
                    let lineRange = match.range(at: 1)
                    let colRange = match.range(at: 2)
                    
                    if let line = Int((text as NSString).substring(with: lineRange)),
                       let col = Int((text as NSString).substring(with: colRange)) {
                        
                        // Create a custom URL scheme for navigation
                        if let url = URL(string: "novaswift://jump?line=\(line)&col=\(col)") {
                            attributedString.addAttribute(.link, value: url, range: match.range)
                            // Optional: Make it look like a link (blue/underline) or keep it subtle
                            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: match.range)
                        }
                    }
                }
            }
            
            textView.textStorage?.setAttributedString(attributedString)
        }
    }
}
