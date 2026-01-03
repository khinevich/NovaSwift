//
//  LanguageTests.swift
//  NovaSwiftTests
//
//  Created by Gemini on 03.01.26.
//

import Testing
import Foundation
@testable import NovaSwift

@Suite("Language Tests")
struct LanguageTests {
    
    @Test("Language Extensions")
    func testLanguageExtensions() {
        #expect(Language.swift.extension == "swift")
        #expect(Language.kotlin.extension == "kts")
    }
    
    @Test("Language Identification")
    func testLanguageIdentification() {
        let swiftURL = URL(fileURLWithPath: "main.swift")
        let kotlinURL = URL(fileURLWithPath: "script.kts")
        let unknownURL = URL(fileURLWithPath: "image.png")
        
        #expect(Language.identify(from: swiftURL) == .swift)
        #expect(Language.identify(from: kotlinURL) == .kotlin)
        #expect(Language.identify(from: unknownURL) == nil)
    }
    
    @Test("Execution Arguments")
    func testExecutionArguments() {
        let fileURL = URL(fileURLWithPath: "/path/to/script")
        
        // Swift
        let swiftArgs = Language.swift.executionArguments(for: fileURL)
        #expect(swiftArgs.first == fileURL.path, "Swift should just pass the file path")
        
        // Kotlin
        let kotlinArgs = Language.kotlin.executionArguments(for: fileURL)
        #expect(kotlinArgs.contains("-script"), "Kotlin must include -script flag")
        #expect(kotlinArgs.last == fileURL.path, "Kotlin file path should be last")
    }
}
