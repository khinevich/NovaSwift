//
//  ContentViewModelTests.swift
//  NovaSwiftTests
//
//  Created by Mikhail Khinevich on 03.01.26.
//

import Testing
import Foundation
@testable import NovaSwift

@Suite("ContentViewModel Tests")
@MainActor
struct ContentViewModelTests {
    
    // Helper to create a temporary file with content
    func createTempFile(content: String, name: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appending(path: name)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    // Helper to cleanup
    func removeTempFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    @Test("Open File")
    func testOpenFile() throws {
        let viewModel = ContentViewModel()
        
        let content = "print('Hello')"
        let fileURL = try createTempFile(content: content, name: "test_open_\(UUID().uuidString).swift")
        defer { removeTempFile(at: fileURL) }
        
        viewModel.openFile(at: fileURL)
        
        #expect(viewModel.editorText == content)
        #expect(viewModel.currentFile == fileURL)
        #expect(viewModel.selectedRange.location == 0)
    }
    
    @Test("Save File")
    func testSaveFile() throws {
        let viewModel = ContentViewModel()
        
        // Create an initial empty file
        let fileURL = try createTempFile(content: "", name: "test_save_\(UUID().uuidString).swift")
        defer { removeTempFile(at: fileURL) }
        
        viewModel.currentFile = fileURL
        viewModel.editorText = "Updated Content"
        
        viewModel.saveFile()
        
        let savedContent = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(savedContent == "Updated Content")
    }
    
    @Test("Clear Editor")
    func testClearEditor() {
        let viewModel = ContentViewModel()
        viewModel.editorText = "Some Text"
        viewModel.currentFile = URL(fileURLWithPath: "/test.swift")
        
        viewModel.clearEditor()
        
        #expect(viewModel.editorText.isEmpty)
        #expect(viewModel.currentFile == nil)
        #expect(viewModel.selectedRange.location == 0)
    }
    
    @Test("Handle Incoming URL - Jump to Line")
    func testHandleIncomingURL() async throws {
        let viewModel = ContentViewModel()
        
        // Setup file
        let fileContent = """
        Line 1
        Line 2
        Line 3
        """
        let fileURL = try createTempFile(content: fileContent, name: "test_jump_\(UUID().uuidString).swift")
        defer { removeTempFile(at: fileURL) }
        
        // Deep link: novaswift://jump?file=/path/to/file&line=3&col=1
        var components = URLComponents()
        components.scheme = "novaswift"
        components.host = "jump"
        components.queryItems = [
            URLQueryItem(name: "file", value: fileURL.path),
            URLQueryItem(name: "line", value: "3"),
            URLQueryItem(name: "col", value: "1")
        ]
        
        let url = components.url!
        
        viewModel.handleIncomingURL(url)
        
        // Check if file opened
        #expect(viewModel.currentFile == fileURL)
        #expect(viewModel.editorText == fileContent)
        
        // The scroll logic is async, so we wait
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        // Line 1: 6 chars + 1 newline = 7
        // Line 2: 6 chars + 1 newline = 7
        // Total before Line 3: 14
        // Line 3 col 1 (0-based) = 0 offset
        // Expected location: 14
        
        #expect(viewModel.selectedRange.location == 14)
    }
    
    @Test("Output Operations")
    func testOutputOperations() {
        let viewModel = ContentViewModel()
        
        // 1. Test Clear Output
        // Since we are using real executor, we modify the property directly for testing
        viewModel.executor.output = "Some Output"
        viewModel.clearOutput()
        #expect(viewModel.executor.output.isEmpty)
        
        // 2. Test Send Input
        // Note: Real ScriptExecutor needs a running process (and pipes) to send input.
        // We cannot easily mock the internal state to test `sendInput` safely here without
        // starting a real process which might be flaky.
        // We skip `sendInputToExecutor` test in this integration context or we'd need to spawn a real process.
        // For now, we'll verify it clears the input buffer if we simulate the call, but guarded.
        
        viewModel.outputInputText = "User Input"
        // We can't really call sendInputToExecutor() meaningfully because executor.isRunning is false,
        // so it will just return. But let's check that basic state logic holds if we were running.
        // Since we can't mock isRunning easily (it's a var but sendInput depends on private inputPipe),
        // we will omit testing sendInput side effects here to avoid crashes/complexity.
        
        // 3. Test Export Preparation
        viewModel.executor.output = "Export Me"
        viewModel.prepareOutputExport()
        #expect(viewModel.isOutputExporting)
        #expect(viewModel.outputExportDocument?.text == "Export Me")
    }
}
