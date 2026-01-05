//
//  LanguageTests.swift
//  NovaSwiftTests
//
//  Created by Mikhail Khinevich on 03.01.26.
//

import Testing
import Foundation
@testable import NovaSwift

@Suite("Language Tests")
struct LanguageTests {
    
    @Test("Language Extensions")
    func testLanguageExtensions() {
        #expect(Language.swift.fileExtension == "swift")
        #expect(Language.kotlin.fileExtension == "kts")
    }
    
    @Test("Language Identification")
    func testLanguageIdentification() {
        let swiftURL = URL(fileURLWithPath: "main.swift")
        let kotlinURL = URL(fileURLWithPath: "script.kts")
        let unknownURL = URL(fileURLWithPath: "image.png")
        
        #expect(Language.from(fileName: swiftURL.lastPathComponent) == .swift)
        #expect(Language.from(fileName: kotlinURL.lastPathComponent) == .kotlin)
        // Current implementation defaults to .swift for unknown extensions
        #expect(Language.from(fileName: unknownURL.lastPathComponent) == .swift)
    }
    
    @Test("Execution Arguments")
    func testExecutionArguments() {
        let fileURL = URL(fileURLWithPath: "/path/to/script")
        
        // Swift
        let swiftArgs = Language.swift.executionArguments(for: fileURL.path)
        #expect(swiftArgs.first == fileURL.path, "Swift should just pass the file path")
        
        // Kotlin
        let kotlinArgs = Language.kotlin.executionArguments(for: fileURL.path)
        #expect(kotlinArgs.contains("-script"), "Kotlin must include -script flag")
        #expect(kotlinArgs.last == fileURL.path, "Kotlin file path should be last")
    }
}
