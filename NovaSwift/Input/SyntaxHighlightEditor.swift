//
//  SyntaxHighlightEditor.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 30.12.25.
//

import SwiftUI
import AppKit
import Foundation

struct SyntaxHighlightEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange
    var fontSize: CGFloat
    var theme: AppTheme
    var language: Language

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.wantsLayer = true
        
        let textView = NSTextView()
        textView.isRichText = false
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.allowsUndo = true
        
        // Disable substitutions
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        
        // Resize settings
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        // Container Setup
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 5, height: 10)

        // Ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        scrollView.verticalRulerView = LineNumberRulerView(textView: textView)
        
        scrollView.documentView = textView
        textView.delegate = context.coordinator
        
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // 1. Update Theme Colors
        let colors = ThemeColors.forTheme(theme)
        if textView.backgroundColor != colors.editorBackground {
            textView.backgroundColor = colors.editorBackground
            textView.textColor = colors.text
            textView.insertionPointColor = colors.insertionPoint
        }
        
        // 2. Pass data to Coordinator
        context.coordinator.update(theme: theme, fontSize: fontSize, language: language)
        
        // 3. Update Text content if changed externally
        if textView.string != text {
            textView.string = text
            context.coordinator.highlight(textView) // Trigger manual highlight
        }
        
        // 4. Update Selection
        if selectedRange.location != NSNotFound &&
           selectedRange.length + selectedRange.location <= (textView.string as NSString).length {
            if textView.selectedRange() != selectedRange {
                textView.setSelectedRange(selectedRange)
                textView.scrollRangeToVisible(selectedRange)
            }
        }
        
        // 5. Update Font
        if textView.font?.pointSize != fontSize {
            textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
            context.coordinator.highlight(textView) // Re-highlight for font size change
        }
        
        // 6. Refresh Ruler
        if let ruler = scrollView.verticalRulerView as? LineNumberRulerView {
            ruler.theme = theme
            ruler.needsDisplay = true
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SyntaxHighlightEditor
        var theme: AppTheme
        var fontSize: CGFloat
        var language: Language
        
        // Instance of our new engine
        let engine = SyntaxHighlightEngine()

        init(_ parent: SyntaxHighlightEditor) {
            self.parent = parent
            self.theme = parent.theme
            self.fontSize = parent.fontSize
            self.language = parent.language
        }
        
        func update(theme: AppTheme, fontSize: CGFloat, language: Language) {
            self.theme = theme
            self.fontSize = fontSize
            self.language = language
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Sync to SwiftUI
            parent.text = textView.string
            parent.selectedRange = textView.selectedRange()
            
            // Perform Highlight
            highlight(textView)
            
            // Update Ruler
            textView.enclosingScrollView?.verticalRulerView?.needsDisplay = true
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.selectedRange = textView.selectedRange()
        }
        
        func highlight(_ textView: NSTextView) {
            guard let storage = textView.textStorage else { return }
            // Delegate logic to the engine
            engine.highlight(storage, theme: theme, language: language, fontSize: fontSize)
        }
    }
}
