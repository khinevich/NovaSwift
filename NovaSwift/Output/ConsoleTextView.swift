//
//  ConsoleTextView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 30.12.25.
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
    let attributedText: AttributedString
    
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
        textView.isRichText = true // Must be true for attributed string colors
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        // Initial Theme
        let colors = ThemeColors.forTheme(theme)
        textView.backgroundColor = colors.consoleBackground
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
        if textView.backgroundColor != colors.consoleBackground {
            textView.backgroundColor = colors.consoleBackground
        }
        // Basic textColor is fallback; attributed string overrides it
        
        // Update font if needed
        if textView.font?.pointSize != fontSize {
            textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
        
        context.coordinator.updateSettings(theme: theme, fontSize: fontSize)
        
        // Always update text logic
        context.coordinator.updateTextWithLinks(textView, attributedText: attributedText)
        
        if !attributedText.description.isEmpty { // Crude check, but we want auto-scroll
             textView.scrollToEndOfDocument(nil)
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
        func updateTextWithLinks(_ textView: NSTextView, attributedText: AttributedString) {
            // Convert SwiftUI AttributedString to NSAttributedString
            let nsAttrString = NSMutableAttributedString(attributedText)
            let string = nsAttrString.string
            let fullRange = NSRange(location: 0, length: nsAttrString.length)
            let colors = ThemeColors.forTheme(currentTheme)
            
            // 1. Apply Base Font (if not already set)
            nsAttrString.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: currentFontSize, weight: .regular), range: fullRange)
            
            // 2. Apply Default Text Color (only where no color is set)
            nsAttrString.enumerateAttribute(.foregroundColor, in: fullRange, options: []) { (value, range, stop) in
                if value == nil {
                    nsAttrString.addAttribute(.foregroundColor, value: colors.text, range: range)
                }
            }
            
            // 3. Detect and Apply Standard Web/File URLs
            if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
                detector.enumerateMatches(in: string, options: [], range: fullRange) { match, _, _ in
                    if let match = match, let url = match.url {
                        nsAttrString.addAttribute(.link, value: url, range: match.range)
                        nsAttrString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: match.range)
                    }
                }
            }
            
            // 4. Detect and Apply Custom Error Links (Custom Scheme)
            // Regex: ([^:\n]+\.(?:swift|kts)):(\d+):(\d+)
            let pattern = #"([^:\n]+\.(?:swift|kts)):(\d+):(\d+)"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                regex.enumerateMatches(in: string, options: [], range: fullRange) { match, _, _ in
                    guard let match = match, match.numberOfRanges == 4 else { return }
                    
                    let pathRange = match.range(at: 1)
                    let lineRange = match.range(at: 2)
                    let colRange = match.range(at: 3)
                    
                    let path = (string as NSString).substring(with: pathRange)
                    if let line = Int((string as NSString).substring(with: lineRange)),
                       let col = Int((string as NSString).substring(with: colRange)) {
                        
                        // Create a custom URL scheme for navigation
                        var components = URLComponents()
                        components.scheme = "novaswift"
                        components.host = "jump"
                        components.queryItems = [
                            URLQueryItem(name: "file", value: path),
                            URLQueryItem(name: "line", value: String(line)),
                            URLQueryItem(name: "col", value: String(col))
                        ]
                        
                        if let url = components.url {
                            // Only apply if not already linked by DataDetector (though DataDetector usually misses these specific file patterns)
                            nsAttrString.addAttribute(.link, value: url, range: match.range)
                            nsAttrString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: match.range)
                        }
                    }
                }
            }
            
            if textView.textStorage?.string != string || textView.textStorage?.length != nsAttrString.length {
                textView.textStorage?.setAttributedString(nsAttrString)
            } else {
                 textView.textStorage?.setAttributedString(nsAttrString)
            }
        }
        
        // MARK: - NSTextViewDelegate
        
        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            if let url = link as? URL {
                // If it's our custom scheme, we open it via NSWorkspace to trigger onOpenURL globally
                // This allows the app-wide URL handler to coordinate file opening and line scrolling.
                NSWorkspace.shared.open(url)
                return true
            }
            
            return false // Fallback
        }
    }
}
