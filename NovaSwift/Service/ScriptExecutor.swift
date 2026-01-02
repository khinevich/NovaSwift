//
//  ScriptExecutor.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 29.12.25.
//

import Foundation
import SwiftUI

/// A service class responsible for executing Swift scripts and managing their runtime state.
///
/// This class uses the `@Observable` macro to allow SwiftUI views to reactively update
/// based on the script's execution status and output.
@Observable
class ScriptExecutor {
    // MARK: - Published State
    
    /// The accumulated standard output and standard error from the running script.
    var output: String = ""
    
    /// The accumulated output with styling (e.g. error colors).
    var attributedOutput: AttributedString = ""
    
    /// A boolean indicating whether a script is currently executing.
    var isRunning: Bool = false
    
    /// A boolean indicating whether the script is likely waiting for user input (heuristic: output doesn't end with newline).
    var isWaitingForInput: Bool = false
    
    /// The exit code of the last executed script. `nil` if no script has run yet or if a script is currently running.
    var exitCode: Int?
    
    // MARK: - Private Properties
    
    /// The underlying process object handling the script execution.
    private var process: Process?
    
    /// The pipe used to send standard input to the running process.
    private var inputPipe: Pipe?
    
    /// A task handle to manage the asynchronous execution context.
    private var executionTask: Task<Void, Never>?
    
    /// The temporary file path used for the current/last execution.
    private var currentTempPath: String?
    
    /// The path to display in place of the temporary path (e.g., the original file path).
    private var currentDisplayPath: String?
    
    // MARK: - Public Methods
    
    /// Executes the provided source code string.
    ///
    /// - Parameters:
    ///   - script: The source code to execute.
    ///   - fileURL: The original URL of the file being executed, if any.
    ///   - language: The programming language of the script.
    func execute(_ script: String, fileURL: URL? = nil, language: Language = .swift) {
        // Cancel any previous execution
        stop()
        
        // Reset State
        output = ""
        attributedOutput = ""
        exitCode = nil
        isRunning = true
        isWaitingForInput = false
        
        // Setup Paths
        self.currentDisplayPath = fileURL?.path
        
        executionTask = Task {
            // 1. Write Script to Disk
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileName = "script-\(UUID().uuidString).\(language.fileExtension)"
            let scriptPath = tempDirectory.appending(path: fileName)
            
            // Store temp path for replacement logic
            self.currentTempPath = scriptPath.path
            
            do {
                try script.write(to: scriptPath, atomically: true, encoding: .utf8)
            } catch {
                appendOutput("Error: Could not write temporary file.\n", isError: true)
                finish(with: -1)
                return
            }
            
            // 2. Configure the Process
            guard let executableURL = ScriptExecutor.findExecutable(named: language.executableName) else {
                appendOutput("Error: Could not find executable for '\(language.executableName)'. Please ensure it is installed and in your PATH.\n", isError: true)
                finish(with: -1)
                return
            }
            
            let newProcess = Process()
            newProcess.executableURL = executableURL
            newProcess.arguments = language.executionArguments(for: scriptPath.path)
            newProcess.currentDirectoryURL = tempDirectory
            
            // Disable block buffering so prompts appear immediately
            var env = ProcessInfo.processInfo.environment
            env["NSUnbufferedIO"] = "YES"
            newProcess.environment = env
            
            // 3. Setup Pipes
            let outPipe = Pipe()
            let errPipe = Pipe()
            let inPipe = Pipe()
            
            newProcess.standardOutput = outPipe
            newProcess.standardError = errPipe
            newProcess.standardInput = inPipe
            
            self.process = newProcess
            self.inputPipe = inPipe
            
            // 4. Handle Live Output with Buffering
            // We need separate buffers for stdout and stderr
            var outBuffer = Data()
            var errBuffer = Data()
            
            outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                self?.handleData(handle.availableData, buffer: &outBuffer, isError: false)
            }
            
            errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                self?.handleData(handle.availableData, buffer: &errBuffer, isError: true)
            }
            
            // 5. Handle Termination
            newProcess.terminationHandler = { [weak self] p in
                Task { @MainActor [weak self] in
                    self?.exitCode = Int(p.terminationStatus)
                    self?.isRunning = false
                    self?.isWaitingForInput = false
                    self?.inputPipe = nil // Clean up input pipe
                    // Cleanup
                    try? FileManager.default.removeItem(at: scriptPath)
                }
            }
            
            // 6. Launch
            do {
                try newProcess.run()
            } catch {
                appendOutput("Failed to run process: \(error.localizedDescription)\n", isError: true)
                finish(with: -1)
            }
        }
    }
    
    /// Sends input to the running process's standard input.
    ///
    /// - Parameter input: The string to send (newline will be added if not present, usually).
    /// Note: The caller is responsible for adding newlines if needed, but typically stdin input ends with a newline.
    @MainActor
    func sendInput(_ input: String) {
        guard isRunning, let pipe = inputPipe, let data = input.data(using: .utf8) else { return }
        
        // Reset waiting state immediately on input
        isWaitingForInput = false
        
        // Echo to console to show what was typed
        appendOutput(input, isError: false)
        
        do {
            try pipe.fileHandleForWriting.write(contentsOf: data)
        } catch {
            appendOutput("\nError writing to stdin: \(error.localizedDescription)\n", isError: true)
        }
    }
    
    private func handleData(_ data: Data, buffer: inout Data, isError: Bool) {
        guard !data.isEmpty else { return }
        
        buffer.append(data)
        
        var splitIndex = buffer.endIndex
        var i = 0
        
        // Walk back at most 4 bytes (UTF-8 max length)
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
                self?.appendOutput(textChunk, isError: isError)
                
                // Heuristic: Determine if the script is waiting for user input.
                // 1. If output doesn't end with a newline, it's likely an inline prompt (e.g., "Name: ").
                // 2. If the last line before a newline ends with a prompt character (:, ?, >, $), it's likely a prompt.
                // 3. We only check standard output, as errors (stderr) shouldn't trigger a waiting state.
                if let self = self, self.isRunning, !isError {
                    let lines = self.output.components(separatedBy: .newlines)
                    let lastLine = self.output.hasSuffix("\n") ? (lines.dropLast().last ?? "") : (lines.last ?? "")
                    let trimmedLastLine = lastLine.trimmingCharacters(in: .whitespaces)
                    
                    let promptSuffixes = [":", "?", ">", "$"]
                    let isPromptPattern = promptSuffixes.contains { trimmedLastLine.hasSuffix($0) }
                    
                    self.isWaitingForInput = !self.output.hasSuffix("\n") || isPromptPattern
                }
            }
        }
        
        buffer = Data(leftover)
    }
    
    public static func findExecutable(named name: String) -> URL? {
        // 0. Check User Preference
        let defaultsKey: String
        if name == "swift" {
            defaultsKey = "customSwiftPath"
        } else if name == "kotlinc" {
            defaultsKey = "customKotlinPath"
        } else {
            defaultsKey = "custom\(name)Path"
        }
        
        if let customPath = UserDefaults.standard.string(forKey: defaultsKey),
           !customPath.isEmpty,
           FileManager.default.fileExists(atPath: customPath) {
            return URL(fileURLWithPath: customPath)
        }

        // Common paths to search
        let paths = [
            "/usr/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/opt/homebrew/bin/\(name)",
            "/bin/\(name)"
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        
        // Fallback: try `which` command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                return URL(fileURLWithPath: path)
            }
        } catch {
            return nil
        }
        
        return nil
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
        attributedOutput = ""
        exitCode = nil
    }
    
    // MARK: - Private Helpers
    
    /// Appends text to the output on the Main Actor.
    /// - Parameter text: The string to append.
    @MainActor
    private func appendOutput(_ text: String, isError: Bool) {
        var processedText = text
        
        // Replace temp path with display path if available
        if let tempPath = currentTempPath, let displayPath = currentDisplayPath {
             processedText = processedText.replacingOccurrences(of: tempPath, with: displayPath)
        }
        
        self.output += processedText
        
        var container = AttributeContainer()
        if isError {
            container.foregroundColor = .gray
        }
        
        self.attributedOutput += AttributedString(processedText, attributes: container)
    }
    
    /// Finalizes the execution state on the Main Actor.
    /// - Parameter code: The exit code to set.
    @MainActor
    private func finish(with code: Int) {
        self.exitCode = code
        self.isRunning = false
    }
}
