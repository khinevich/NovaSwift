//
//  TextDocument.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 30.12.25.
//

import Foundation
import SwiftUI
internal import UniformTypeIdentifiers

/// A document type representing a plain text file.
///
/// `TextDocument` conforms to `FileDocument` to support file import/export operations
/// within the SwiftUI document architecture.
struct TextDocument: FileDocument {
    /// The string content of the document.
    var text: String

    /// A document initializer, needs to be public since we have custom ones below
    init(text: String = "") {
        self.text = text
    }
    // MARK: - FileDocument requirements
    
    /// tells the Open/Save dialogs which files extensions are allowed
    static var readableContentTypes: [UTType] {
        [.plainText, .swiftSource, UTType(filenameExtension: "kts")!]
    }

    /// Initializes (aka opens file) the document by reading from a file configuration.
    init(configuration: ReadConfiguration) throws {
        try self.init(fileWrapper: configuration.file)
    }
    // FileDocument protocol required function, System interface
    /// Cmd + S
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try createFileWrapper()
    }
    
    // MARK: - Testable Logic
    
    /// Logic for init(configuration) -> for testing purposes
    init(fileWrapper: FileWrapper) throws {
        guard let data = fileWrapper.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    /// logic for fileWrapper() -> for testing purposes
    func createFileWrapper() throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
