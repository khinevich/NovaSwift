//
//  ScriptExecutor.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 29.12.25.
//

import Foundation

/// A service class responsible for executing Swift scripts and managing their runtime state.
///
/// This class uses the `@Observable` macro to allow SwiftUI views to reactively update
/// based on the script's execution status and output.
@Observable
class ScriptExecutor {
    // MARK: - Published State
    
    /// The accumulated standard output and standard error from the running script.
    var output: String = ""
    
    /// A boolean indicating whether a script is currently executing.
    var isRunning: Bool = false
    
    /// The exit code of the last executed script. `nil` if no script has run yet or if a script is currently running.
    var exitCode: Int?
    
    // MARK: - Private Properties
    
    /// The underlying process object handling the script execution.
    private var process: Process?
    
    /// A task handle to manage the asynchronous execution context.
    private var executionTask: Task<Void, Never>?
    
    // MARK: - Public Methods
    
    /// Executes the provided Swift source code string.
    /// 
    /// This method performs the following steps:
    /// 1. Resets the current state (`output`, `exitCode`, `isRunning`).
    /// 2. Writes the script to a temporary file.
    /// 3. Spawns a subprocess using `/usr/bin/env swift`.
    /// 4. Captures stdout and stderr in real-time, handling UTF-8 buffering.
    /// 5. Updates the `output` property on the Main Actor as data arrives.
    /// 
    /// - Parameter script: The Swift source code to execute.
    func execute(_ script: String) {
        // Cancel any previous execution
        stop()
        
        // Reset State
        output = ""
        exitCode = nil
        isRunning = true
        
        executionTask = Task {
            // 1. Write Script to Disk
            let tempDirectory = FileManager.default.temporaryDirectory
            let scriptPath = tempDirectory.appending(path: "script.swift")
            
            do {
                try script.write(to: scriptPath, atomically: true, encoding: .utf8)
            } catch {
                appendOutput("Error: Could not write temporary file.\n")
                finish(with: -1)
                return
            }
            
            // 2. Configure the Process
            let newProcess = Process()
            newProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            newProcess.arguments = ["swift", "\(scriptPath.path)"]
            
            // 3. Setup Pipes
            let pipe = Pipe()
            newProcess.standardOutput = pipe
            newProcess.standardError = pipe
            
            self.process = newProcess
            
            // 4. Handle Live Output with Buffering
            var buffer = Data()
            
            pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                
                // Process buffering logic to handle split UTF-8 characters
                buffer.append(data)
                
                var splitIndex = buffer.endIndex
                var i = 0
                
                // Walk back at most 4 bytes
                while i < 4 && (buffer.endIndex - 1 - i) >= buffer.startIndex {
                    let index = buffer.endIndex - 1 - i
                    let byte = buffer[index]
                    
                    if (byte & 0x80) == 0 { // ASCII
                        splitIndex = buffer.endIndex
                        break
                    } else if (byte & 0xC0) == 0xC0 { // Start Byte
                        let expectedLen: Int
                        if (byte & 0xE0) == 0xC0 { expectedLen = 2 }
                        else if (byte & 0xF0) == 0xE0 { expectedLen = 3 }
                        else if (byte & 0xF8) == 0xF0 { expectedLen = 4 }
                        else { expectedLen = 1 }
                        
                        if (i + 1) < expectedLen {
                            splitIndex = index // Incomplete
                        } else {
                            splitIndex = buffer.endIndex // Complete
                        }
                        break
                    }
                    i += 1
                }
                
                let validChunk = buffer[..<splitIndex]
                let leftover = buffer[splitIndex...]
                
                if !validChunk.isEmpty {
                    let textChunk = String(decoding: validChunk, as: UTF8.self)
                    Task { @MainActor [weak self] in
                        self?.output += textChunk
                    }
                }
                
                buffer = Data(leftover)
            }
            
            // 5. Handle Termination
            newProcess.terminationHandler = { [weak self] p in
                Task { @MainActor [weak self] in
                    self?.exitCode = Int(p.terminationStatus)
                    self?.isRunning = false
                }
            }
            
            // 6. Launch
            do {
                try newProcess.run()
            } catch {
                appendOutput("Failed to run process: \(error.localizedDescription)\n")
                finish(with: -1)
            }
        }
    }
    
    /// Stops the currently running script, if any.
    /// 
    /// This method terminates the subprocess and resets the `isRunning` state.
    func stop() {
        process?.terminate()
        executionTask?.cancel()
        executionTask = nil
        isRunning = false
    }
    
    /// Clears the console output and exit code.
    func clearOutput() {
        output = ""
        exitCode = nil
    }
    
    // MARK: - Private Helpers
    
    /// Appends text to the output on the Main Actor.
    /// - Parameter text: The string to append.
    @MainActor
    private func appendOutput(_ text: String) {
        self.output += text
    }
    
    /// Finalizes the execution state on the Main Actor.
    /// - Parameter code: The exit code to set.
    @MainActor
    private func finish(with code: Int) {
        self.exitCode = code
        self.isRunning = false
    }
}
