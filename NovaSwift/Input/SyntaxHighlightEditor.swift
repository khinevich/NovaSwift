//
//  SyntaxHighlightEditor.swift
//  NovaSwift
//
//  Created by NovaSwift AI on 30.12.25.
//

import SwiftUI
import AppKit

/// A SwiftUI wrapper around `NSTextView` that provides basic syntax highlighting for Swift and Kotlin code.
///
/// This view supports line numbers via a custom `NSRulerView` and applies color attributes
/// to keywords, types, strings, comments, and other language constructs.
struct SyntaxHighlightEditor: NSViewRepresentable {
    // MARK: - Bindings
    
    /// The source code text to be edited.
    @Binding var text: String
    
    // MARK: - Configuration
    
    /// The font size for the editor text.
    var fontSize: CGFloat
    
    /// The current application theme.
    var theme: AppTheme
    
    /// The programming language for syntax highlighting.
    var language: Language

    // MARK: - NSViewRepresentable
    
    /// Creates the `NSScrollView` containing the configured `NSTextView`.
    ///
    /// This method sets up the `NSTextView` with specific properties to support code editing:
    /// - Disables rich text.
    /// - Sets a monospaced font.
    /// - Enables line numbers via `LineNumberRulerView`.
    /// - Disables automatic text substitutions (quotes, dashes) which can break code syntax.
    func makeNSView(context: Context) -> NSScrollView {
        // We use a native NSScrollView + NSTextView backing because SwiftUI's TextEditor
        // currently lacks support for Attributed Strings (needed for syntax highlighting)
        // and advanced cursor control.
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        // Ensure clipping of subviews (like the ruler) by enabling the layer
        scrollView.wantsLayer = true
        
        // 1. Setup Ruler for Line Numbers
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        
        let textView = NSTextView()
        
        let rulerView = LineNumberRulerView(textView: textView)
        scrollView.verticalRulerView = rulerView
        
        textView.isRichText = false
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        // Apply initial theme
        let colors = ThemeColors.forTheme(theme)
        textView.backgroundColor = colors.editorBackground
        textView.textColor = colors.text
        textView.insertionPointColor = colors.insertionPoint
        
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

    /// Updates the view when SwiftUI state changes.
    ///
    /// This method is responsible for syncing the `NSTextView` appearance with the SwiftUI environment:
    /// - Updates background and text colors based on the theme.
    /// - Updates font size.
    /// - Updates the syntax highlighting language configuration.
    /// - Updates the text content if the binding changes externally.
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        let colors = ThemeColors.forTheme(theme)
        
        // Update basic appearance
        if textView.backgroundColor != colors.editorBackground {
            textView.backgroundColor = colors.editorBackground
        }
        if textView.insertionPointColor != colors.insertionPoint {
            textView.insertionPointColor = colors.insertionPoint
        }
        
        // Update font if needed
        if textView.font?.pointSize != fontSize {
            textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
        
        // Pass theme info to ruler
        if let ruler = nsView.verticalRulerView as? LineNumberRulerView {
            ruler.theme = theme
        }
        
        context.coordinator.updateConfiguration(theme: theme, fontSize: fontSize, language: language)
        
        if textView.string != text {
            // Preserve cursor position if possible
            let selectedRanges = textView.selectedRanges
            textView.string = text
            context.coordinator.highlightSyntax(in: textView)
            textView.selectedRanges = selectedRanges
            
            // Refresh ruler
            nsView.verticalRulerView?.needsDisplay = true
        } else {
            // Re-highlight if theme/font/language changed even if text is same
            context.coordinator.highlightSyntax(in: textView)
            nsView.verticalRulerView?.needsDisplay = true
        }
    }

    /// Creates the coordinator to handle text delegate methods.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator
    
    /// Coordinating class responsible for handling text changes and applying syntax highlighting.
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SyntaxHighlightEditor
        var currentTheme: AppTheme
        var currentFontSize: CGFloat
        var currentLanguage: Language

        init(_ parent: SyntaxHighlightEditor) {
            self.parent = parent
            self.currentTheme = parent.theme
            self.currentFontSize = parent.fontSize
            self.currentLanguage = parent.language
        }
        
        /// Updates the coordinator's configuration to match the parent view.
        func updateConfiguration(theme: AppTheme, fontSize: CGFloat, language: Language) {
            self.currentTheme = theme
            self.currentFontSize = fontSize
            self.currentLanguage = language
        }

        /// Called when the text in the `NSTextView` changes.
        ///
        /// This method syncs the changes back to the SwiftUI binding and re-applies syntax highlighting.
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // 1. Update the SwiftUI Binding
            parent.text = textView.string
            // 2. Apply Syntax Highlighting
            highlightSyntax(in: textView)
            
            // 3. Update Line Numbers
            textView.enclosingScrollView?.verticalRulerView?.needsDisplay = true
        }
        
        /// Applies syntax highlighting attributes to the entire text view content.
        ///
        /// This method resets all text attributes to the plain style and then iteratively applies
        /// regex-based highlighting rules. It handles nested structures like string interpolation
        /// by re-applying code rules within the interpolation delimiters.
        ///
        /// - Parameter textView: The `NSTextView` to highlight.
        func highlightSyntax(in textView: NSTextView) {
            guard let textStorage = textView.textStorage else { return }
            let fullRange = NSRange(location: 0, length: textStorage.length)
            let string = textStorage.string
            
            let colors = ThemeColors.forTheme(currentTheme)
            
            // --- Helper: Apply Regex ---
            /// Applies a given regex pattern with a specific color and optional font trait.
            func apply(_ pattern: String, color: NSColor, fontTrait: NSFontDescriptor.SymbolicTraits? = nil, range: NSRange) {
                guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
                regex.enumerateMatches(in: string, options: [], range: range) { match, _, _ in
                    if let matchRange = match?.range {
                        textStorage.addAttribute(.foregroundColor, value: color, range: matchRange)
                        if let trait = fontTrait, trait.contains(.bold) {
                            textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: currentFontSize, weight: .bold), range: matchRange)
                        }
                    }
                }
            }
            
            // --- Helper: Apply All Code Rules (Keywords, Types, etc.) ---
            /// Applies all standard language syntax rules (keywords, types, numbers, etc.) within a given range.
            func applyCodeRules(in searchRange: NSRange) {
                // 1. Keywords
                let keywords = currentLanguage.keywords
                let keywordPattern = "\\b(" + keywords.joined(separator: "|") + ")\\b"
                apply(keywordPattern, color: colors.keyword, fontTrait: .bold, range: searchRange)
                
                // 2. Built-in Types
                let types = currentLanguage.types
                let typePattern = "\\b(" + types.joined(separator: "|") + ")\\b"
                apply(typePattern, color: colors.type, range: searchRange)
                
                // 3. Numbers
                apply(#"\b\d+(\.\d+)?\b"#, color: colors.number, range: searchRange)
                
                // 4. Attributes
                apply(#"@\w+"#, color: colors.attribute, range: searchRange)
                
                // 5. Function Calls (Word followed by '(')
                if let regex = try? NSRegularExpression(pattern: "\\b(\\w+)(?=\\()", options: []) {
                    regex.enumerateMatches(in: string, options: [], range: searchRange) { match, _, _ in
                        if let matchRange = match?.range(at: 1) {
                            textStorage.addAttribute(.foregroundColor, value: colors.call, range: matchRange)
                        }
                    }
                }
            }
            
            // --- Execution ---
            
            // 1. Reset to plain text (Default Color)
            // It is crucial to clear existing attributes to avoid color bleeding when text is deleted or modified.
            textStorage.removeAttribute(.foregroundColor, range: fullRange)
            textStorage.addAttribute(.foregroundColor, value: colors.plain, range: fullRange)
            textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: currentFontSize, weight: .regular), range: fullRange)
            
            // 2. Apply Code Rules to the full text
            applyCodeRules(in: fullRange)
            
            // 3. Apply Strings (Overwrites code rules inside strings)
            let stringPattern = ##""(?:\\.|[^\"])*""##
            apply(stringPattern, color: colors.string, range: fullRange)
            
            // 4. Handle String Interpolation: \( ... )
            // Only applicable for Swift currently. Kotlin uses $variable or ${expression}
            if currentLanguage == .swift {
                let interpolationPattern = ##"\\((?:[^()]|\([^()]*\))*)"##
                
                if let regex = try? NSRegularExpression(pattern: interpolationPattern, options: []) {
                    regex.enumerateMatches(in: string, options: [], range: fullRange) { match, _, _ in
                        if let matchRange = match?.range {
                            // Reset color to default (Plain) for the interpolation block
                            textStorage.addAttribute(.foregroundColor, value: colors.plain, range: matchRange)
                            textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: currentFontSize, weight: .regular), range: matchRange)
                            
                            // Re-apply code highlighting INSIDE the interpolation
                            applyCodeRules(in: matchRange)
                        }
                    }
                }
            } else if currentLanguage == .kotlin {
                // Kotlin String Interpolation: ${...}
                let kotlinInterpolation = ##"\$\{[^}]+\}"##
                if let regex = try? NSRegularExpression(pattern: kotlinInterpolation, options: []) {
                    regex.enumerateMatches(in: string, options: [], range: fullRange) { match, _, _ in
                        if let matchRange = match?.range {
                            textStorage.addAttribute(.foregroundColor, value: colors.plain, range: matchRange)
                            applyCodeRules(in: matchRange)
                        }
                    }
                }
                // Simple variable interpolation $var is harder to safely regex without parsing, skipping for now or treating as plain/var color
            }
            
            // 5. Comments (Last)
            // Comments should override everything else (strings, keywords, etc.) if they appear last in the logic.
            let commentPattern = ##"//.*"##
            apply(commentPattern, color: colors.comment, range: fullRange)
        }
    }
}

// MARK: - Line Number Ruler

/// A custom `NSRulerView` that draws line numbers corresponding to the text layout.
class LineNumberRulerView: NSRulerView {
    /// The current theme to use for drawing.
    var theme: AppTheme = .dark
    
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
    
    /// Draws the line numbers in the ruler view.
    ///
    /// This method is called by the system when the ruler needs to be redrawn.
    /// It efficiently calculates which lines are currently visible and draws
    /// the corresponding line numbers.
    ///
    /// - Parameter rect: The dirty rectangle to redraw.
    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = self.clientView as? NSTextView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer
        else { return }
        
        let colors = ThemeColors.forTheme(theme)
        
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
        let visibleCharIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
        let string = textView.string
        
        // Optimized newline counting using UTF8 view to avoid string allocation
        // This is O(N) relative to the scroll position, which is unavoidable without a line cache,
        // but significantly faster than String(substring).
        if visibleCharIndex > 0 {
            lineNumber += string.utf8.prefix(visibleCharIndex).filter { $0 == 10 }.count // 10 is '\n'
        }
        
        let lineNumberAttributes: [NSAttributedString.Key: Any] = [
            .font: self.font,
            .foregroundColor: colors.lineNumbers
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
