//
//  TextDocumentTests.swift
//  NovaSwiftTests
//
//  Created by Gemini on 02.01.26.
//

import Testing
import SwiftUI
import UniformTypeIdentifiers
@testable import NovaSwift

/// A test suite for the `TextDocument` model.
///
/// This suite validates the `TextDocument` struct, which is responsible for representing
/// text files in the application. It ensures that the document correctly initializes with text,
/// reads content from a `FileWrapper` (import), and writes content back to a `FileWrapper` (export).
@Suite("TextDocument Tests")
struct TextDocumentTests {
    
    /// Verifies the basic initialization of a `TextDocument`.
    ///
    /// **Scenario:**
    /// A `TextDocument` is initialized with a specific string.
    ///
    /// **Expectation:**
    /// - The `text` property holds the value provided during initialization.
    @Test("Initialization with text")
    func testInit() {
        let doc = TextDocument(text: "Initial text")
        #expect(doc.text == "Initial text", "The document should retain the text provided at initialization.")
    }
    
    /// Verifies that `TextDocument` correctly reads data from a `FileWrapper`.
    ///
    /// **Scenario:**
    /// A `FileWrapper` is created containing UTF-8 encoded string data ("File content").
    /// The `TextDocument` is initialized using this wrapper.
    ///
    /// **Expectation:**
    /// - The document successfully decodes the data and sets its `text` property to "File content".
    @Test("Read from FileWrapper")
    func testReadFromFileWrapper() throws {
        let content = "File content"
        guard let data = content.data(using: .utf8) else {
            throw NSError(domain: "Test", code: 1, userInfo: nil)
        }
        
        let fileWrapper = FileWrapper(regularFileWithContents: data)
        
        // Initialize the document using the testable initializer
        let doc = try TextDocument(fileWrapper: fileWrapper)
        
        #expect(doc.text == content, "The document text should match the content of the FileWrapper.")
    }
    
    /// Verifies that `TextDocument` correctly serializes its content to a `FileWrapper`.
    ///
    /// **Scenario:**
    /// A `TextDocument` containing "Content to save" is asked to create a `FileWrapper`.
    ///
    /// **Expectation:**
    /// - A valid `FileWrapper` is returned.
    /// - The `regularFileContents` of the wrapper can be decoded back into the original string.
    @Test("Write to FileWrapper")
    func testWriteToFileWrapper() throws {
        let content = "Content to save"
        let doc = TextDocument(text: content)
        
        // Generate the FileWrapper
        let wrapper = try doc.createFileWrapper()
        
        guard let data = wrapper.regularFileContents,
              let savedString = String(data: data, encoding: .utf8)
        else {
            #expect(Bool(false), "Failed to retrieve valid UTF-8 data from the generated FileWrapper")
            return
        }
        
        #expect(savedString == content, "The data in the FileWrapper should match the document's text.")
    }
}