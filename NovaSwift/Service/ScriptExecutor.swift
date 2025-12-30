//
//  ScriptExecutor.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 29.12.25.
//

import Foundation

enum ProcessOutput {
    case stdout(String)
    case exitCode(Int32)
}

@Observable
class ScriptExecutor {
    private var process: Process?
    
    func execute(_ script: String) -> AsyncStream<ProcessOutput> {
        AsyncStream { continuation in
            // 1. Prepare the temporary file
            // Swift scripts need to be on disk to be executed by the compiler/interpreter
            let tempDirectory = FileManager.default.temporaryDirectory
            let scriptPath = tempDirectory.appending(path: "script.swift")
            
            do {
                try script.write(to: scriptPath, atomically: true, encoding: .utf8)
            } catch {
                continuation.yield(.stdout("Error: Could not write temporary file."))
                continuation.finish()
                return
            }
            
            // 2. Configure the Process
            // We use /usr/bin/env to locate the swift executable in the user's path
            self.process = Process()
            process?.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process?.arguments = ["swift", "\(scriptPath.path)"]
            
            // 3. Setup Pipes for capturing Output
            // A Pipe connects the process's stdout/stderr to our code
            let pipe = Pipe()
            process?.standardOutput = pipe
            process?.standardError = pipe
            
            // 4. Handle Live Output with Buffering
            // We maintain a buffer to handle cases where a multi-byte character (e.g., Emoji)
            // is split across two data chunks. Without this, split characters would decode incorrectly.
            var buffer = Data()
            
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                
                buffer.append(data)
                
                // Scan backwards to find the start of the last UTF-8 sequence
                // to determine if it is complete.
                var splitIndex = buffer.endIndex
                var i = 0
                
                // Walk back at most 4 bytes (max UTF-8 char length)
                while i < 4 && (buffer.endIndex - 1 - i) >= buffer.startIndex {
                    let index = buffer.endIndex - 1 - i
                    let byte = buffer[index]
                    
                    // Check if byte is a standard ASCII char (0xxxxxxx)
                    if (byte & 0x80) == 0 {
                        // ASCII is always complete in 1 byte.
                        // Everything before and including this is valid to print.
                        splitIndex = buffer.endIndex
                        break
                    }
                    // Check if byte is a Start Byte (11xxxxxx)
                    else if (byte & 0xC0) == 0xC0 {
                        // Determine required length for this character
                        let expectedLen: Int
                        if (byte & 0xE0) == 0xC0 { expectedLen = 2 }      // 110xxxxx
                        else if (byte & 0xF0) == 0xE0 { expectedLen = 3 } // 1110xxxx
                        else if (byte & 0xF8) == 0xF0 { expectedLen = 4 } // 11110xxx
                        else { expectedLen = 1 } // Fallback/Invalid
                        
                        let currentLen = i + 1
                        if currentLen < expectedLen {
                            // We don't have enough bytes for this char yet.
                            // Stop processing here and keep this sequence in the buffer.
                            splitIndex = index
                        } else {
                            // We have the full sequence.
                            splitIndex = buffer.endIndex
                        }
                        break
                    }
                    // If byte is a Continuation Byte (10xxxxxx), keep scanning back.
                    i += 1
                }
                
                // Extract the valid chunk to decode
                let validChunk = buffer[..<splitIndex]
                let leftover = buffer[splitIndex...]
                
                if !validChunk.isEmpty {
                    // Use decoding helper that replaces invalid sequences rather than returning nil
                    let output = String(decoding: validChunk, as: UTF8.self)
                    continuation.yield(.stdout(output))
                }
                
                // Save incomplete bytes for the next read
                buffer = Data(leftover)
            }
            
            // 5. Handle Termination
            // Called when the process finishes (successfully or crashes)
            process?.terminationHandler = { p in
                continuation.yield(.exitCode(p.terminationStatus))
                continuation.finish() // Closes the AsyncStream
            }
            
            // 6. Launch the Process
            do {
                try process?.run()
            } catch {
                continuation.yield(.stdout("Failed to run process: \(error.localizedDescription)"))
                continuation.finish()
            }
        }
    }
    
    func stop() {
        process?.terminate()
    }
}
