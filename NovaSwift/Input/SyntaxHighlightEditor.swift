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
        
        // 1. Setup Ruler for Line Numbers
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        
        let textView = NSTextView()
        
        let rulerView = LineNumberRulerView(textView: textView)
        scrollView.verticalRulerView = rulerView
        
        textView.isRichText = false
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        // Force Dark Background to match the custom color palette
        let darkBackground = NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0) // #1E1E1E
        textView.backgroundColor = darkBackground
        textView.textColor = .white
        textView.insertionPointColor = .white
        
        // Add padding around text
        textView.textContainerInset = NSSize(width: 5, height: 10)
        
        textView.allowsUndo = true
        
        // Fixing doublequotes for coding:
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
            
            // Refresh ruler
            nsView.verticalRulerView?.needsDisplay = true
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
            
            // 3. Update Line Numbers
            textView.enclosingScrollView?.verticalRulerView?.needsDisplay = true
        }
        
        func highlightSyntax(in textView: NSTextView) {
            guard let textStorage = textView.textStorage else { return }
            let fullRange = NSRange(location: 0, length: textStorage.length)
            let string = textStorage.string
            
            // 1. Reset to plain text
            textStorage.removeAttribute(.foregroundColor, range: fullRange)
            textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
            textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .regular), range: fullRange)
            
            // Helper to apply regex
            func apply(_ pattern: String, color: NSColor, fontTrait: NSFontDescriptor.SymbolicTraits? = nil) {
                guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
                regex.enumerateMatches(in: string, options: [], range: fullRange) { match, _, _ in
                    if let matchRange = match?.range {
                        textStorage.addAttribute(.foregroundColor, value: color, range: matchRange)
                        if let trait = fontTrait, trait.contains(.bold) {
                            textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .bold), range: matchRange)
                        }
                    }
                }
            }
            
            // --- Colors (Custom Palette) ---
            // Helper for Hex Colors
            func color(_ hex: Int) -> NSColor {
                let r = CGFloat((hex >> 16) & 0xFF) / 255.0
                let g = CGFloat((hex >> 8) & 0xFF) / 255.0
                let b = CGFloat(hex & 0xFF) / 255.0
                return NSColor(red: r, green: g, blue: b, alpha: 1.0)
            }
            
            let defaultColor = color(0xFFFFFF) // White
            let stringColor  = color(0xFF8170) // Soft Red/Salmon
            let keywordColor = color(0xDDA0DD) // Light Magenta/Purple
            let commentColor = color(0x6C7986) // Slate Gray
            let numberColor  = color(0xD9C97C) // Muted Gold
            let typeColor    = color(0x91D462) // Light Green
            let callColor    = color(0x4EB1BA) // Teal/Cyan
            let attrColor    = color(0xB190F0) // Bright Purple
            
            // 1. Reset to plain text (White)
            textStorage.removeAttribute(.foregroundColor, range: fullRange)
            textStorage.addAttribute(.foregroundColor, value: defaultColor, range: fullRange)
            textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .regular), range: fullRange)
            let keywords = [
                "associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func", "import", "init", "inout", "internal", "let", "open", "operator", "private", "protocol", "public", "static", "struct", "subscript", "typealias", "var",
                "break", "case", "continue", "default", "defer", "do", "else", "fallthrough", "for", "guard", "if", "in", "repeat", "return", "switch", "where", "while",
                "as", "Any", "catch", "false", "is", "nil", "rethrows", "super", "self", "Self", "throw", "throws", "true", "try",
                "async", "await", "actor"
            ]
            let keywordPattern = "\\b(" + keywords.joined(separator: "|") + ")\\b"
            apply(keywordPattern, color: keywordColor, fontTrait: .bold)
            
            // 3. Built-in Types (Basic list)
            let types = [
                "Int", "Double", "Float", "Bool", "String", "Array", "Dictionary", "Set", "Character", "Data", "Date", "URL", "UUID", "CGFloat", "CGRect", "CGPoint", "CGSize", "Void", "Error", "Result", "OptionSet"
            ]
            let typePattern = "\\b(" + types.joined(separator: "|") + ")\\b"
            apply(typePattern, color: typeColor)
            
            // 4. Numbers
            apply("\\b\\d+(\\.\\d+)?\\b", color: numberColor)
            
            // 5. Attributes (@State, @Binding, etc.)
            apply("@\\w+", color: attrColor)
            
            // 6. Function Calls / Definitions (Word followed by '(')
            // Note: This regex matches the word, then checks for '('.
            // We iterate manually to only color the word, not the paren.
            if let regex = try? NSRegularExpression(pattern: "\\b(\\w+)(?=\\()", options: []) {
                regex.enumerateMatches(in: string, options: [], range: fullRange) { match, _, _ in
                    if let matchRange = match?.range(at: 1) { // Capture group 1 (the word)
                        textStorage.addAttribute(.foregroundColor, value: callColor, range: matchRange)
                    }
                }
            }
            
            // 7. Strings (Last, to overwrite keywords inside strings)
            let stringPattern = "\"(?:\\\\.|[^\\\\\"])*\""
            apply(stringPattern, color: stringColor)
            
            // 8. Comments (Last, to overwrite everything inside comments)
            let commentPattern = "//.*"
            apply(commentPattern, color: commentColor)
        }
    }
}

// MARK: - Line Number Ruler

class LineNumberRulerView: NSRulerView {
    var font: NSFont {
        return .monospacedSystemFont(ofSize: 10, weight: .regular)
    }
    
    init(textView: NSTextView) {
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 40
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = self.clientView as? NSTextView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer
        else { return }
        
        // 1. Get the origin of the text textContainer relative to the text view
        // This accounts for textContainerInset (the 10pt top padding we added)
        let textContainerOrigin = textView.textContainerOrigin
        
        let visibleRect = scrollView?.documentVisibleRect ?? .zero
        
        // 2. Find the range of glyphs currently visible
        // We look a bit outside the visible rect to ensure smooth scrolling
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect.offsetBy(dx: -textContainerOrigin.x, dy: -textContainerOrigin.y), in: textContainer)
        
        var glyphIndex = glyphRange.location
        var lineNumber = 1
        
        // Calculate the starting line number for the first visible glyph
        // (This can be slow for huge files, but simple regex count is fast enough for now)
        let initialString = (textView.string as NSString).substring(to: layoutManager.characterIndexForGlyph(at: glyphIndex))
        lineNumber += initialString.filter { $0 == "\n" }.count
        
        let lineNumberAttributes: [NSAttributedString.Key: Any] = [
            .font: self.font,
            .foregroundColor: NSColor(white: 0.5, alpha: 1.0) // Gray
        ]
        
        while glyphIndex < NSMaxRange(glyphRange) {
            let characterIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            let lineRange = (textView.string as NSString).lineRange(for: NSRange(location: characterIndex, length: 0))
            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            
            // Get rect for the line fragment in container coordinates
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
            
            // 3. Convert to View Coordinates (add padding/inset)
            let viewRectY = lineRect.minY + textContainerOrigin.y
            
            // Draw only if visible (optimization)
            if viewRectY >= visibleRect.minY - 20 && viewRectY <= visibleRect.maxY + 20 {
                let labelText = "\(lineNumber)" as NSString
                let labelSize = labelText.size(withAttributes: lineNumberAttributes)
                
                // Center vertically within the line height
                let drawPoint = NSPoint(
                    x: self.ruleThickness - labelSize.width - 8,
                    y: viewRectY + (lineRect.height - labelSize.height) / 2
                )
                
                labelText.draw(at: drawPoint, withAttributes: lineNumberAttributes)
            }
            
            lineNumber += 1
            glyphIndex = NSMaxRange(lineGlyphRange)
            
            // Handle the "phantom" empty last line if text ends in newline
            if glyphIndex == layoutManager.numberOfGlyphs && textView.string.hasSuffix("\n") {
                 let labelText = "\(lineNumber)" as NSString
                 let labelSize = labelText.size(withAttributes: lineNumberAttributes)
                 // Position it one line height below the last real line
                 let drawPoint = NSPoint(
                     x: self.ruleThickness - labelSize.width - 8,
                     y: viewRectY + lineRect.height + (lineRect.height - labelSize.height) / 2
                 )
                 labelText.draw(at: drawPoint, withAttributes: lineNumberAttributes)
            }
        }
    }
}
