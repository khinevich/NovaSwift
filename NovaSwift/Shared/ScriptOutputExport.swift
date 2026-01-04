//
//  ScriptOutputExport.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 04.01.26.
//

import Foundation
import SwiftUI
internal import UniformTypeIdentifiers

/// A wrapper that enables script output to be shared as a file.
///
/// `ScriptOutputExport` takes a standard string and prepares it for system sharing (AirDrop, Mail, etc.)
/// by treating it as a distinct text document (e.g., `Output.txt`).
///
/// This is used primarily by `ShareLink` to ensure the content is attached as a file rather than
/// copied as plain text.
struct ScriptOutputExport: Transferable {
    /// The text content to be exported.
    let content: String
    
    /// The configuration for converting the content to a file representation.
    static var transferRepresentation: some TransferRepresentation {
        // when sharing, treat as a plain text file
        FileRepresentation(contentType: .plainText) { exportedData in
            // temp URL
            let tempDir = FileManager.default.temporaryDirectory
            let url = tempDir.appendingPathComponent("Output.txt")
            
            // write the content to it
            try exportedData.content.write(to: url, atomically: true, encoding: .utf8)
            
            // return the file for AirDrop/Mail/etc.
            return SentTransferredFile(url)
        } importing: { received in
            // Required by the compiler to complete the protocol.
            // We just read the text back from the file.
            let text = try String(contentsOf: received.file, encoding: .utf8)
            return ScriptOutputExport(content: text)
        }
    }
}
