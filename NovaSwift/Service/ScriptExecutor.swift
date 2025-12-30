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
    
    /// Executes the provided Swift script string in a subprocess.
    ///
    /// - Parameter script: The source code of the script to execute.
    /// - Returns: An `AsyncStream` that yields execution events (stdout/stderr output and the final exit code).
    func execute(_ script: String) -> AsyncStream<ProcessOutput> {
        AsyncStream { continuation in
            // 1. Write Script to Disk
            // The Swift compiler/interpreter expects a file path. We write the script content
            // to a temporary file in the user's temp directory.
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
            // We use /usr/bin/env to locate the `swift` executable, ensuring compatibility across different setups.
            self.process = Process()
            process?.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process?.arguments = ["swift", "\(scriptPath.path)"]
            
            // 3. Setup Pipes
            // A Pipe connects the process's standard output and error to our application.
            let pipe = Pipe()
            process?.standardOutput = pipe
            process?.standardError = pipe
            
            // 4. Handle Live Output with Buffering
            //
            // Crucial: We must handle cases where a multi-byte UTF-8 character (e.g., an Emoji or accented char)
            // is split across two separate data chunks read from the pipe.
            //
            // If we blindly decode `String(data: chunk)`, a split character would result in an invalid sequence
            // or replacement character ().
            //
            // To fix this, we maintain a persistent `buffer`. We only decode complete UTF-8 sequences
            // and keep any partial trailing bytes in the buffer for the next read operation.
            var buffer = Data()
            
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                
                buffer.append(data)
                
                // Scan backwards to find the last valid UTF-8 boundary.
                // A UTF-8 character can be 1-4 bytes. We check the last few bytes to see if
                // we have a partial sequence at the end of the buffer.
                var splitIndex = buffer.endIndex
                var i = 0
                
                // Walk back at most 4 bytes (max UTF-8 char length)
                while i < 4 && (buffer.endIndex - 1 - i) >= buffer.startIndex {
                    let index = buffer.endIndex - 1 - i
                    let byte = buffer[index]
                    
                    // Standard ASCII (0xxxxxxx) is always a complete unit.
                    if (byte & 0x80) == 0 {
                        splitIndex = buffer.endIndex
                        break
                    }
                    // Start Byte (11xxxxxx) indicates the beginning of a multi-byte sequence.
                    else if (byte & 0xC0) == 0xC0 {
                        // Determine the expected length based on the start byte prefix.
                        let expectedLen: Int
                        if (byte & 0xE0) == 0xC0 { expectedLen = 2 }      // 110xxxxx
                        else if (byte & 0xF0) == 0xE0 { expectedLen = 3 } // 1110xxxx
                        else if (byte & 0xF8) == 0xF0 { expectedLen = 4 } // 11110xxx
                        else { expectedLen = 1 } // Fallback for invalid byte
                        
                        let currentLen = i + 1
                        if currentLen < expectedLen {
                            // The sequence is incomplete (we have fewer bytes than expected).
                            // Stop processing at this start byte; it will be processed when the rest arrives.
                            splitIndex = index
                        } else {
                            // The sequence is complete.
                            splitIndex = buffer.endIndex
                        }
                        break
                    }
                    // Continuation Byte (10xxxxxx): keep scanning backwards to find the start byte.
                    i += 1
                }
                
                // Extract the valid, printable chunk
                let validChunk = buffer[..<splitIndex]
                let leftover = buffer[splitIndex...]
                
                if !validChunk.isEmpty {
                    // Decoding is now safe as we know `validChunk` ends on a character boundary.
                    let output = String(decoding: validChunk, as: UTF8.self)
                    continuation.yield(.stdout(output))
                }
                
                // Retain only the incomplete bytes for the next read
                buffer = Data(leftover)
            }
            
            // 5. Handle Termination
            // When the process finishes, we signal the end of the stream and pass the exit code.
            process?.terminationHandler = { p in
                continuation.yield(.exitCode(p.terminationStatus))
                continuation.finish()
            }
            
            // 6. Launch
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
