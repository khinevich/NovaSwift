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

    init(text: String = "") {
        self.text = text
    }

    static var readableContentTypes: [UTType] { [.plainText] }

    /// Initializes the document by reading from a file configuration.
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
