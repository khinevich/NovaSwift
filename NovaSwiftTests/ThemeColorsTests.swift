//
//  ThemeColorsTests.swift
//  NovaSwiftTests
//
//  Created by Mikhail Khinevich on 02.01.26.
//

import Testing
import SwiftUI
import AppKit
@testable import NovaSwift

/// A test suite for the `ThemeColors` model.
///
/// This suite verifies that the `ThemeColors` structure correctly returns the defined color palettes
/// for the supported application themes (Dark and Light). It checks specific key colors to ensure
/// the theme configuration is loaded as expected.
@Suite("ThemeColors Tests")
struct ThemeColorsTests {
    
    /// Verifies the color palette for the Dark theme.
    ///
    /// **Expectation:**
    /// - `consoleBackground` should be black.
    /// - `text` should be white.
    /// - `keyword` color should match the Plum color (#DDA0DD) defined in the specifications.
    @Test("Dark Theme Colors")
    func testDarkTheme() {
        let colors = ThemeColors.forTheme(.dark)
        
        // Verify high-level UI colors
        #expect(colors.consoleBackground == .black, "Console background in Dark Mode should be black.")
        #expect(colors.text == .white, "Main text color in Dark Mode should be white.")
        
        // Verify a specific syntax highlighting color (Keyword).
        // Expected Color: #DDA0DD (Plum) -> RGB(0.87, 0.63, 0.87)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        colors.keyword.usingColorSpace(.sRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // We use an epsilon check for floating point color component comparison.
        #expect(abs(red - 0.87) < 0.01, "Keyword Red component mismatch.")
        #expect(abs(green - 0.63) < 0.01, "Keyword Green component mismatch.")
        #expect(abs(blue - 0.87) < 0.01, "Keyword Blue component mismatch.")
    }
    
    /// Verifies the color palette for the Light theme.
    ///
    /// **Expectation:**
    /// - `editorBackground` should be white.
    /// - `text` should be black.
    /// - `keyword` color should match the defined Purple color.
    @Test("Light Theme Colors")
    func testLightTheme() {
        let colors = ThemeColors.forTheme(.light)
        
        #expect(colors.editorBackground == .white, "Editor background in Light Mode should be white.")
        #expect(colors.text == .black, "Main text color in Light Mode should be black.")
        
        // Verify Keyword Color: Purple (0.6, 0.0, 0.6)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        colors.keyword.usingColorSpace(.sRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        #expect(abs(red - 0.6) < 0.01, "Keyword Red component mismatch.")
        #expect(abs(green - 0.0) < 0.01, "Keyword Green component mismatch.")
        #expect(abs(blue - 0.6) < 0.01, "Keyword Blue component mismatch.")
    }
}
