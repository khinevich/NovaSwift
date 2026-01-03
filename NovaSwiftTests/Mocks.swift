//
//  Mocks.swift
//  NovaSwiftTests
//
//  Created by Gemini on 03.01.26.
//

import Foundation
@testable import NovaSwift

// MARK: - Mock Script Executor

class MockScriptExecutor: ScriptExecutor {
    var executeCalled = false
    var lastExecutedScript: String?
    var lastExecutedFileURL: URL?
    var stopCalled = false
    var clearOutputCalled = false
    
    override func execute(_ script: String, fileURL: URL? = nil, language: Language = .swift) {
        executeCalled = true
        lastExecutedScript = script
        lastExecutedFileURL = fileURL
        // Simulate immediate finish or state change if needed
        self.isRunning = true
        self.output = "Mock Output"
    }
    
    override func stop() {
        stopCalled = true
        self.isRunning = false
    }
    
    override func clearOutput() {
        clearOutputCalled = true
        self.output = ""
        self.attributedOutput = ""
        self.exitCode = nil
    }
}

// MARK: - Mock Project Manager

class MockProjectManager: ProjectManager {
    var readFileCalled = false
    var lastReadURL: URL?
    var mockFileContent: [URL: String] = [:]
    
    var saveFileCalled = false
    var lastSavedURL: URL?
    var lastSavedContent: String?
    
    override func readFile(_ url: URL) -> String? {
        readFileCalled = true
        lastReadURL = url
        return mockFileContent[url]
    }
    
    override func saveFile(_ url: URL, content: String) {
        saveFileCalled = true
        lastSavedURL = url
        lastSavedContent = content
        mockFileContent[url] = content
    }
    
    // Helper to setup mock data
    func setMockContent(_ content: String, for url: URL) {
        mockFileContent[url] = content
    }
}

