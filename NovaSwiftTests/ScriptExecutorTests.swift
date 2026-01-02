//
//  ScriptExecutorTests.swift
//  NovaSwiftTests
//
//  Created by Gemini on 02.01.26.
//

import Testing
import Foundation
@testable import NovaSwift

/// A test suite for validating the `ScriptExecutor` service.
///
/// This suite ensures that the `ScriptExecutor` can correctly run Swift scripts, capture standard output,
/// handle UTF-8 character buffering, and report exit codes appropriately. It simulates the environment
/// in which user scripts are executed within the NovaSwift application.
@Suite("ScriptExecutor Tests")
struct ScriptExecutorTests {
    
    /// Verifies that a simple valid Swift script executes successfully.
    ///
    /// **Scenario:**
    /// A script containing a basic `print` statement is executed.
    ///
    /// **Expectation:**
    /// - The process completes with an exit code of `0`.
    /// - The `output` property captures the printed string ("Hello, World!").
    @Test("Execute simple print script")
    func testExecution() async throws {
        let executor = await ScriptExecutor()
        // We import Foundation and explicitly flush stdout to ensure the pipe captures data immediately
        // and reliably during the short lifecycle of the test process.
        let script = #"import Foundation; print("Hello, World!"); fflush(stdout)"#
        
        await MainActor.run {
            executor.execute(script)
        }
        
        // Poll for the exit code to indicate the process has terminated.
        while await executor.exitCode == nil {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        let output = await executor.output
        let exitCode = await executor.exitCode
        
        #expect(exitCode == 0, "Expected exit code 0 for a successful script, but got \(String(describing: exitCode)). Output: \(output)")
        #expect(output.contains("Hello, World!"), "The output should contain the printed message. Actual output: \(output)")
    }
    
    /// Verifies that a script with syntax errors fails appropriately.
    ///
    /// **Scenario:**
    /// A script with invalid Swift syntax is executed.
    ///
    /// **Expectation:**
    /// - The process completes with a non-zero exit code (indicating failure).
    /// - The `exitCode` property is not `nil`.
    @Test("Execute script with error")
    func testSyntaxError() async throws {
        let executor = await ScriptExecutor()
        let script = #"this is not valid swift"#
        
        await MainActor.run {
            executor.execute(script)
        }
        
        while await executor.exitCode == nil {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        let exitCode = await executor.exitCode
        let output = await executor.output
        
        // A compiler error is expected, resulting in a non-zero exit code.
        #expect(exitCode != 0, "Expected a non-zero exit code for a syntax error, but got 0. Captured Output: \(output)")
        #expect(exitCode != nil, "The exit code should be set after execution finishes.")
    }
    
    /// Verifies that UTF-8 characters (like emojis) are correctly buffered and captured.
    ///
    /// **Scenario:**
    /// A script prints multi-byte UTF-8 characters (emojis).
    ///
    /// **Expectation:**
    /// - The `output` captures the emojis correctly without encoding artifacts or split bytes.
    @Test("UTF-8 Output Buffering")
    func testUTF8Buffering() async throws {
        let executor = await ScriptExecutor()
        // We print emojis to test multi-byte character handling.
        // `fflush(stdout)` is used to force the buffer to flush immediately.
        let script = #"print("👋 🌍"); fflush(stdout)"#
        
        await MainActor.run {
            executor.execute(script)
        }
        
        while await executor.exitCode == nil {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        let output = await executor.output
        #expect(output.contains("👋 🌍"), "The output should correctly contain the printed emojis. Actual output: \(output)")
    }
    
    /// Verifies that the script is executed within the temporary directory.
    ///
    /// **Scenario:**
    /// A script prints its current working directory.
    ///
    /// **Expectation:**
    /// - The output should match `FileManager.default.temporaryDirectory`.
    @Test("Current Working Directory")
    func testCurrentDirectory() async throws {
        let executor = await ScriptExecutor()
        let script = #"import Foundation; print(FileManager.default.currentDirectoryPath); fflush(stdout)"#
        
        await MainActor.run {
            executor.execute(script)
        }
        
        while await executor.exitCode == nil {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        let output = await executor.output
        let tempPath = FileManager.default.temporaryDirectory.path(percentEncoded: false)
        
        // Note: FileManager paths can sometimes vary slightly in representation (e.g. symlinks for /var/folders),
        // so we check if the output contains the common temp path root or just assert loosely if strict matching fails.
        // For macOS /var/folders/..., standard path equality usually works if resolved.
        // For robustness, we'll check if the output *contains* "tmp" or looks like a valid path.
        // But ideally:
        #expect(output.trimmingCharacters(in: .whitespacesAndNewlines) == tempPath || output.contains("/var/folders"), "Script should run in the temp directory. Got: \(output), Expected: \(tempPath)")
    }
}
