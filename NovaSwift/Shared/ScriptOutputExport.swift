//
//  ScriptOutputExport.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 04.01.26.
//

import Foundation
import SwiftUI
internal import UniformTypeIdentifiers

struct ScriptOutputExport: Transferable {
    let content: String
    
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
