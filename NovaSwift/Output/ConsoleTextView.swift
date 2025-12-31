//
//  ConsoleTextView.swift
//  NovaSwift
//
//  Created by NovaSwift AI on 30.12.25.
//

import SwiftUI
import AppKit

/// A SwiftUI wrapper around `NSTextView` designed for displaying read-only console output.
///
/// This view configures the text view with a dark theme, monospaced font, and automatic
/// link detection for file paths (e.g., `script.swift:10:5`).
struct ConsoleTextView: NSViewRepresentable {
    // MARK: - Properties
    
    /// The read-only text content to display.
    let text: String
    
    /// The font size for the console text.
    var fontSize: CGFloat
    
    /// The current application theme.
    var theme: AppTheme
    
    // MARK: - NSViewRepresentable
    
    /// Creates the `NSScrollView` containing the read-only `NSTextView`.
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
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        // Initial Theme
        let colors = ThemeColors.forTheme(theme)
        textView.backgroundColor = colors.background
        textView.textColor = colors.text
        
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
    
    /// Updates the view when SwiftUI state changes.
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        let colors = ThemeColors.forTheme(theme)
        
        // Update colors if changed
        if textView.backgroundColor != colors.background {
            textView.backgroundColor = colors.background
        }
        if textView.textColor != colors.text {
            textView.textColor = colors.text
        }
        
        // Update font if needed
        if textView.font?.pointSize != fontSize {
            textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
        
        context.coordinator.updateSettings(theme: theme, fontSize: fontSize)
        
        // Update only if content changed to avoid unnecessary redraws/scroll jumps.
        // Or if theme changed, we might need to re-apply attributes to ensure text color is correct
        // because we use NSAttributedString which locks in colors.
        
        if textView.string != text {
            // Content changed
            context.coordinator.updateTextWithLinks(textView, text: text)
             // Auto-scroll logic:
             if !text.isEmpty {
                  textView.scrollToEndOfDocument(nil)
             }
        } else {
             // Text same, but theme/font might have changed. Re-apply attributes.
             context.coordinator.updateTextWithLinks(textView, text: text)
        }
    }
    
    /// Creates the coordinator to handle text delegate methods.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    /// Coordinating class responsible for handling text updates and link interactions.
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ConsoleTextView
        var currentTheme: AppTheme
        var currentFontSize: CGFloat
        
        init(_ parent: ConsoleTextView) {
            self.parent = parent
            self.currentTheme = parent.theme
            self.currentFontSize = parent.fontSize
        }
        
        func updateSettings(theme: AppTheme, fontSize: CGFloat) {
            self.currentTheme = theme
            self.currentFontSize = fontSize
        }
        
        /// Updates the text view's storage with attributed text, detecting and linking file locations.
        ///
        /// - Parameters:
        ///   - textView: The `NSTextView` to update.
        ///   - text: The raw string content.
        func updateTextWithLinks(_ textView: NSTextView, text: String) {
            let attributedString = NSMutableAttributedString(string: text)
            let fullRange = NSRange(location: 0, length: text.utf16.count)
            let colors = ThemeColors.forTheme(currentTheme)
            
            // Default styling
            attributedString.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: currentFontSize, weight: .regular), range: fullRange)
            attributedString.addAttribute(.foregroundColor, value: colors.text, range: fullRange)
            
            // Detect patterns: /path/to/script.swift:LINE:COL
            // Regex: [^:]+\.swift:(\d+):(\d+)
            let pattern = #"[^:]+\.swift:(\d+):(\d+)"#
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
                            // Ensure link color is readable against background (standard link blue is usually fine, but let's stick to system default for links)
                        }
                    }
                }
            }
            
            // Preserve selection if possible? No, console is usually read-only auto-scroll.
            textView.textStorage?.setAttributedString(attributedString)
        }
    }
}
