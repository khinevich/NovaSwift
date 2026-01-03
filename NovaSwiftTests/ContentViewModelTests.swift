//
//  ContentViewModelTests.swift
//  NovaSwiftTests
//
//  Created by Gemini on 03.01.26.
//

import Testing
import Foundation
@testable import NovaSwift

@Suite("ContentViewModel Tests")
@MainActor
struct ContentViewModelTests {
    
    @Test("Open File")
    func testOpenFile() {
        let mockExecutor = MockScriptExecutor()
        let mockProjectManager = MockProjectManager()
        let viewModel = ContentViewModel(executor: mockExecutor, projectManager: mockProjectManager)
        
        let fileURL = URL(fileURLWithPath: "/test/file.swift")
        let content = "print('Hello')"
        mockProjectManager.setMockContent(content, for: fileURL)
        
        viewModel.openFile(at: fileURL)
        
        #expect(viewModel.editorText == content)
        #expect(viewModel.currentFile == fileURL)
        #expect(viewModel.selectedRange.location == 0)
        #expect(mockProjectManager.readFileCalled)
        #expect(mockProjectManager.lastReadURL == fileURL)
    }
    
    @Test("Save File")
    func testSaveFile() {
        let mockExecutor = MockScriptExecutor()
        let mockProjectManager = MockProjectManager()
        let viewModel = ContentViewModel(executor: mockExecutor, projectManager: mockProjectManager)
        
        let fileURL = URL(fileURLWithPath: "/test/file.swift")
        viewModel.currentFile = fileURL
        viewModel.editorText = "Updated Content"
        
        viewModel.saveFile()
        
        #expect(mockProjectManager.saveFileCalled)
        #expect(mockProjectManager.lastSavedURL == fileURL)
        #expect(mockProjectManager.lastSavedContent == "Updated Content")
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
        let mockExecutor = MockScriptExecutor()
        let mockProjectManager = MockProjectManager()
        let viewModel = ContentViewModel(executor: mockExecutor, projectManager: mockProjectManager)
        
        // Setup file
        let fileURL = URL(fileURLWithPath: "/test/jumptest.swift")
        let fileContent = """
        Line 1
        Line 2
        Line 3
        """
        mockProjectManager.setMockContent(fileContent, for: fileURL)
        
        // Deep link: novaswift://jump?file=/test/jumptest.swift&line=3&col=1
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
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        
        // Line 1: 6 chars + 1 newline = 7
        // Line 2: 6 chars + 1 newline = 7
        // Total before Line 3: 14
        // Line 3 col 1 (0-based) = 0 offset
        // Expected location: 14
        
        #expect(viewModel.selectedRange.location == 14)
    }
}
