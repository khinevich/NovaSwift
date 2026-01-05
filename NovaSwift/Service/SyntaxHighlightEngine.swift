//
//  SyntaxHighlightEngine.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 04.01.26.
//

import AppKit

class SyntaxHighlightEngine {
    
    /// Highlights the text storage using the exact palette from ThemeColors.
    func highlight(_ textStorage: NSTextStorage, theme: AppTheme, language: Language, fontSize: CGFloat) {
        let string = textStorage.string
        let fullRange = NSRange(location: 0, length: string.utf16.count)
        let colors = ThemeColors.forTheme(theme)
        
        // 1. Reset to Plain Text (colors.plain)
        textStorage.removeAttribute(.foregroundColor, range: fullRange)
        textStorage.removeAttribute(.font, range: fullRange)
        
        textStorage.addAttributes([
            .foregroundColor: colors.plain,
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        ], range: fullRange)
        
        // Track indices that are "taken" by higher priority rules to prevent overwriting.
        let occupiedIndices = NSMutableIndexSet()
        
        // --- Helper: Apply Regex ---
        // We added a `addToOccupied` flag. If true, matched ranges are marked as "taken".
        func apply(_ pattern: String, color: NSColor, fontTrait: NSFontDescriptor.SymbolicTraits? = nil, addToOccupied: Bool = true) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
            
            regex.enumerateMatches(in: string, options: [], range: fullRange) { match, _, _ in
                guard let matchRange = match?.range else { return }
                
                // If this range matches something already highlighted, skip it.
                if occupiedIndices.intersects(in: matchRange) {
                    return
                }
                
                // Apply attributes
                textStorage.addAttribute(.foregroundColor, value: color, range: matchRange)
                if let trait = fontTrait, trait.contains(.bold) {
                    textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold), range: matchRange)
                }
                
                // Mark as occupied so lower-priority rules (like generic Function Calls) don't overwrite it
                if addToOccupied {
                    occupiedIndices.add(in: matchRange)
                }
            }
        }
        
        // =========================================================================
        // PRIORITY 1: CONTAINERS (Strings & Comments)
        // These MUST be identified first so code inside them is ignored.
        // =========================================================================
        
        // A. Strings (colors.string)
        // Matches " ... " allowing for escaped quotes \"
        let stringPattern = "\"(?:\\\\.|[^\\\\\"])*\""
        apply(stringPattern, color: colors.string)
        
        // B. Comments (colors.comment)
        // We look for // ... but we check if it overlaps with an existing String.
        let commentPattern = "//.*"
        if let regex = try? NSRegularExpression(pattern: commentPattern, options: []) {
            regex.enumerateMatches(in: string, options: [], range: fullRange) { match, _, _ in
                guard let matchRange = match?.range else { return }
                
                // If the comment start is inside a string (already occupied), ignore it.
                // e.g. var x = "// this is a string, not a comment"
                if occupiedIndices.intersects(in: matchRange) {
                    return
                }
                
                textStorage.addAttribute(.foregroundColor, value: colors.comment, range: matchRange)
                occupiedIndices.add(in: matchRange)
            }
        }
        
        // =========================================================================
        // PRIORITY 2: SPECIFIC SYNTAX (Keywords, Types, Attributes, Numbers)
        // =========================================================================
        
        // C. Keywords (colors.keyword)
        // e.g. func, var, let, if, return
        let keywordPattern = "\\b(" + language.keywords.joined(separator: "|") + ")\\b"
        apply(keywordPattern, color: colors.keyword, fontTrait: .bold)
        
        // D. Types (colors.type)
        // e.g. String, Int, Bool, Data
        let typePattern = "\\b(" + language.types.joined(separator: "|") + ")\\b"
        apply(typePattern, color: colors.type)
        
        // E. Attributes (colors.attribute)
        // e.g. @State, @Binding, @main
        // Matches '@' followed by word characters
        apply(#"@\w+"#, color: colors.attribute)

        // F. Numbers (colors.number)
        // Matches integers and decimals
        apply(#"\b\d+(\.\d+)?\b"#, color: colors.number)

        // =========================================================================
        // PRIORITY 3: GENERIC PATTERNS (Function Calls)
        // =========================================================================

        // G. Function Calls (colors.call)
        // Matches a word followed immediately by '('. e.g. print(...) or myFunc(...)
        // Since we run this LAST, and we check `occupiedIndices`, it won't highlight "if" in "if(...)"
        // because "if" was already claimed by the Keyword rule above.
        let functionCallPattern = "\\b(\\w+)(?=\\()"
        if let regex = try? NSRegularExpression(pattern: functionCallPattern, options: []) {
            regex.enumerateMatches(in: string, options: [], range: fullRange) { match, _, _ in
                // The capture group 1 is the function name
                guard let matchRange = match?.range(at: 1) else { return }
                
                // Ensure we don't overwrite a keyword (like 'if', 'switch', 'for')
                if occupiedIndices.intersects(in: matchRange) {
                    return
                }
                
                textStorage.addAttribute(.foregroundColor, value: colors.call, range: matchRange)
                occupiedIndices.add(in: matchRange)
            }
        }
        
        // =========================================================================
        // SPECIAL: Interpolation (Swift only)
        // =========================================================================
        
        // Swift Interpolation: \( ... )
        // This is tricky. We need to find `\(` inside strings and effectively "un-occupy" them
        // so they look like code again.
        if language == .swift {
             let interpolationPattern = ##"\\((?:[^()]|\([^()]*\))*)"##
             
             if let regex = try? NSRegularExpression(pattern: interpolationPattern, options: []) {
                 regex.enumerateMatches(in: string, options: [], range: fullRange) { match, _, _ in
                     guard let matchRange = match?.range else { return }
                     
                     // 1. Color the delimiter \() as an Attribute (or Keyword)
                     textStorage.addAttribute(.foregroundColor, value: colors.attribute, range: matchRange)
                     
                     // 2. Identify inner range (remove `\(` and `)`)
                     if matchRange.length > 3 {
                         let innerRange = NSRange(location: matchRange.location + 2, length: matchRange.length - 3)
                         
                         // 3. Reset Inner Range to Plain
                         textStorage.addAttribute(.foregroundColor, value: colors.plain, range: innerRange)
                         textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular), range: innerRange)
                         
                         // 4. Recursively apply rules to inner range?
                         // For simplicity, we just un-occupy it and re-run keywords/numbers manually for this small chunk
                         // (A full recursion is expensive, so we just do a quick pass for common values)
                         
                         // Re-apply numbers inside interpolation
                         let numRegex = try? NSRegularExpression(pattern: #"\b\d+\b"#, options: [])
                         numRegex?.enumerateMatches(in: string, options: [], range: innerRange) { m, _, _ in
                             if let r = m?.range { textStorage.addAttribute(.foregroundColor, value: colors.number, range: r) }
                         }
                         
                         // Re-apply variables/plain text is already set
                     }
                 }
             }
        }
    }
}
