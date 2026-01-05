//
//  LineNumberRulerView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 30.12.25.
//

import AppKit

/// A custom `NSRulerView` subclass that renders line numbers for an `NSTextView`.
///
/// `LineNumberRulerView` is attached to the vertical ruler of the text editor's scroll view.
/// It efficiently calculates visible lines and draws their corresponding numbers, handling
/// font scaling and theme changes (dark/light mode).
class LineNumberRulerView: NSRulerView {
    
    /// The current theme, used to determine the text color of the line numbers.
    ///
    /// When changed, it triggers a redraw of the ruler.
    var theme: AppTheme = .dark {
        didSet {
            self.needsDisplay = true
        }
    }
    
    /// The font used for the line numbers.
    ///
    /// This uses a monospaced system font (size 10, regular weight) to ensure
    /// numbers align neatly. It is distinct from the editor's font size to keep the UI compact.
    var font: NSFont {
        return .monospacedSystemFont(ofSize: 10, weight: .regular)
    }
    
    /// Initializes a new line number ruler for the specified text view.
    ///
    /// - Parameter textView: The `NSTextView` that this ruler will serve.
    init(textView: NSTextView) {
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        self.clientView = textView
        // The width of the ruler bar
        self.ruleThickness = 40
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Draws the hash marks and labels (line numbers) in the ruler's view.
    ///
    /// This method overrides `NSRulerView`'s drawing logic to render custom line numbers.
    /// It performs the following steps for performance:
    /// 1.  Calculates the visible glyph range to avoid processing the entire document.
    /// 2.  Determines the starting line number by counting newlines up to the visible range.
    /// 3.  Iterates through the visible lines, calculating their vertical position.
    /// 4.  Draws the line number only if it falls within the visible rect.
    ///
    /// - Parameter rect: The dirty rectangle to redraw.
    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = self.clientView as? NSTextView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer
        else { return }
        
        // 1. Get Colors from your shared ThemeColors struct
        let colors = ThemeColors.forTheme(theme)
        
        // 2. Setup Drawing Attributes
        let lineNumberAttributes: [NSAttributedString.Key: Any] = [
            .font: self.font,
            .foregroundColor: colors.lineNumbers // Uses the specific color from your struct
        ]
        
        // 3. Calculate Layout
        // Get the origin of the text container relative to the text view
        let textContainerOrigin = textView.textContainerOrigin
        let visibleRect = scrollView?.documentVisibleRect ?? .zero
        
        // Find the range of glyphs currently visible on screen
        // We offset the visible rect to translate it into text container coordinates
        let visibleGlyphRange = layoutManager.glyphRange(
            forBoundingRect: visibleRect.offsetBy(dx: -textContainerOrigin.x, dy: -textContainerOrigin.y),
            in: textContainer
        )
        
        // 4. Count Lines
        // We need to know which line number the *first* visible character belongs to.
        let firstVisibleCharIndex = layoutManager.characterIndexForGlyph(at: visibleGlyphRange.location)
        let string = textView.string
        
        // Fast line counting: Count newlines up to the start of the view
        // Note: For very huge files (10k+ lines), this linear scan might need caching,
        // but for a script runner, it is perfectly fast.
        var lineNumber = 1
        if firstVisibleCharIndex > 0 {
            // Count occurrences of newline character up to the visible range
            lineNumber += string.utf8.prefix(firstVisibleCharIndex).filter { $0 == 10 }.count
        }
        
        // 5. Draw Loop
        var glyphIndex = visibleGlyphRange.location
        
        while glyphIndex < NSMaxRange(visibleGlyphRange) {
            let characterIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            let lineRange = (string as NSString).lineRange(for: NSRange(location: characterIndex, length: 0))
            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            
            // Calculate where to draw the number
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
            let viewRectY = lineRect.minY + textContainerOrigin.y
            
            // Only draw if it's actually within the visible bounds (plus a little buffer)
            if viewRectY >= visibleRect.minY - 20 && viewRectY <= visibleRect.maxY + 20 {
                let labelText = "\(lineNumber)" as NSString
                let labelSize = labelText.size(withAttributes: lineNumberAttributes)
                
                // Align right: ruleThickness - labelWidth - padding
                let drawPoint = NSPoint(
                    x: self.ruleThickness - labelSize.width - 8,
                    y: viewRectY + (lineRect.height - labelSize.height) / 2
                )
                
                labelText.draw(at: drawPoint, withAttributes: lineNumberAttributes)
            }
            
            lineNumber += 1
            glyphIndex = NSMaxRange(lineGlyphRange)
            
            // 6. Handle the "Empty Last Line"
            // If the text ends with a newline, the loop finishes before drawing the number for the new empty line.
            if glyphIndex == layoutManager.numberOfGlyphs && string.hasSuffix("\n") {
                 let labelText = "\(lineNumber)" as NSString
                 let labelSize = labelText.size(withAttributes: lineNumberAttributes)
                 
                 let drawPoint = NSPoint(
                     x: self.ruleThickness - labelSize.width - 8,
                     y: viewRectY + lineRect.height + (lineRect.height - labelSize.height) / 2
                 )
                 labelText.draw(at: drawPoint, withAttributes: lineNumberAttributes)
            }
        }
    }
}
