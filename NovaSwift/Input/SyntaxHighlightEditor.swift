//
//  SyntaxHighlightEditor.swift
//  NovaSwift
//
//  Created by NovaSwift AI on 30.12.25.
//

import SwiftUI
import AppKit

struct SyntaxHighlightEditor: NSViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat = 14

    func makeNSView(context: Context) -> NSScrollView {
        // We use a native NSScrollView + NSTextView backing because SwiftUI's TextEditor
        // currently lacks support for Attributed Strings (needed for syntax highlighting)
        // and advanced cursor control.
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        let textView = NSTextView()
        textView.isRichText = false // Maintain plain text data model, but allowing visual attributes.
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.backgroundColor = .textBackgroundColor
        textView.textColor = .textColor
        textView.allowsUndo = true
        
        // Disable smart substitutions to prevent "magic quotes" breaking code syntax.
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        
        // Setup layout constraints for full width/height
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        scrollView.documentView = textView
        textView.delegate = context.coordinator
        
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        if textView.string != text {
            // Preserve cursor position if possible
            let selectedRanges = textView.selectedRanges
            textView.string = text
            context.coordinator.highlightSyntax(in: textView)
            textView.selectedRanges = selectedRanges
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SyntaxHighlightEditor

        init(_ parent: SyntaxHighlightEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // 1. Update the SwiftUI Binding
            parent.text = textView.string
            
            // 2. Apply Syntax Highlighting
            highlightSyntax(in: textView)
        }
        
        func highlightSyntax(in textView: NSTextView) {
            guard let textStorage = textView.textStorage else { return }
            let fullRange = NSRange(location: 0, length: textStorage.length)
            
            // Reset to default style
            textStorage.removeAttribute(.foregroundColor, range: fullRange)
            textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
            textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .regular), range: fullRange)

            let code = textStorage.string as NSString
            
            // --- Highlighting Logic ---
            
            // 1. Keywords (Purple/Pink)
            let keywords = [
                "import", "var", "let", "func", "class", "struct", "enum", "extension",
                "if", "else", "guard", "return", "switch", "case", "default",
                "for", "in", "while", "do", "try", "catch", "throw", "throws",
                "public", "private", "internal", "fileprivate", "open", "static", "override",
                "init", "self", "super", "true", "false", "nil", "async", "await"
            ]
            let keywordColor = NSColor.systemPurple
            
            for word in keywords {
                // Find all occurrences using regex with word boundaries \b
                // We use NSRegularExpression for performance
                let pattern = "\\b\(word)\\b" // Corrected escaping for backslashes in regex pattern
                let regex = try? NSRegularExpression(pattern: pattern, options: [])
                regex?.enumerateMatches(in: textStorage.string, options: [], range: fullRange) { match, _, _ in
                    if let matchRange = match?.range {
                        textStorage.addAttribute(.foregroundColor, value: keywordColor, range: matchRange)
                        // Make keywords bold
                        textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .bold), range: matchRange)
                    }
                }
            }
            
            // 2. Strings (Red/Orange)
            // Matches "..." handling escape4quotes like \"
            let stringPattern = "\"(?:\\\\.|[^\\\\\"])*\""
            let stringColor = NSColor.systemRed
            if let regex = try? NSRegularExpression(pattern: stringPattern, options: []) {
                regex.enumerateMatches(in: textStorage.string, options: [], range: fullRange) { match, _, _ in
                    if let matchRange = match?.range {
                        textStorage.addAttribute(.foregroundColor, value: stringColor, range: matchRange)
                    }
                }
            }
            
            // 3. Comments (Green) - Single line //
            let commentPattern = "//.*"
            let commentColor = NSColor.systemGreen
            if let regex = try? NSRegularExpression(pattern: commentPattern, options: []) {
                regex.enumerateMatches(in: textStorage.string, options: [], range: fullRange) { match, _, _ in
                    if let matchRange = match?.range {
                        textStorage.addAttribute(.foregroundColor, value: commentColor, range: matchRange)
                    }
                }
            }
        }
    }
}
