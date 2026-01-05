//
//  ContentViewModel.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 03.01.26.
//

import SwiftUI
import Combine

/// The primary view model for the application, managing global state and coordination.
///
/// `ContentViewModel` serves as the source of truth for the `ContentView` and coordinates
/// interactions between the Sidebar, Input, and Output modules. It holds the shared services
/// (`ScriptExecutor`, `ProjectManager`) and manages the state of the editor.
@MainActor
@Observable
class ContentViewModel {
    // MARK: - Services
    
    /// The central service managing script execution.
    var executor: ScriptExecutor
    
    /// The project manager handling file system operations.
    var projectManager: ProjectManager
    
    // MARK: - Editor State
    
    /// The current text content of the editor.
    var editorText: String = ""
    
    /// The URL of the currently open file. `nil` represents an untitled document.
    var currentFile: URL?
    
    /// The language selected by the user for the current untitled file.
    var untitledLanguage: Language = .swift
    
    /// The selected range within the editor text.
    var selectedRange: NSRange = NSRange(location: 0, length: 0)
    
    // MARK: - UI State
    
    /// Controls the presentation of the settings sheet.
    var isSettingsPresented = false
    
    /// Controls the presentation of the info sheet.
    var isInfoPresented = false
    
    /// Controls the visibility of the sidebar.
    var isSidebarVisible = false
    
    // MARK: - Output State
    
    /// Tracks whether the output export sheet is presented.
    var isOutputExporting = false
    
    /// The document wrapper for exporting output text.
    var outputExportDocument: TextDocument?
    
    /// Buffer for user input to stdin.
    var outputInputText: String = ""
    
    // MARK: - Initialization
    
    /// Initializes the view model with injected dependencies.
    ///
    /// - Parameters:
    ///   - executor: The script executor service. Defaults to a new instance.
    ///   - projectManager: The project manager service. Defaults to a new instance.
    init(executor: ScriptExecutor = ScriptExecutor(), projectManager: ProjectManager = ProjectManager()) {
        self.executor = executor
        self.projectManager = projectManager
    }
    
    // MARK: - Actions
    
    /// Opens a file from the given URL and updates the editor state.
    ///
    /// - Parameter url: The URL of the file to open.
    func openFile(at url: URL) {
        if let content = projectManager.readFile(url) {
            editorText = content
            currentFile = url
            // Reset selection when opening a new file
            selectedRange = NSRange(location: 0, length: 0)
        }
    }
    
    /// Saves the current editor content to the file at `currentFile`.
    /// If `currentFile` is `nil`, this method does nothing (Save As flow is handled by View).
    func saveFile() {
        if let url = currentFile {
            projectManager.saveFile(url, content: editorText)
        }
    }
    
    /// Clears the editor content and resets the file state to "Untitled".
    func clearEditor() {
        editorText = ""
        currentFile = nil
        selectedRange = NSRange(location: 0, length: 0)
    }
    
    /// Handles the result of a file import operation.
    ///
    /// - Parameter result: The result from the file importer.
    func handleFileImport(result: Result<[URL], Error>) {
        do {
            guard let selectedFile: URL = try result.get().first else { return }
            openFile(at: selectedFile)
        } catch {
            print("Import failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Output Actions
    
    /// Prepares the output content for export by creating a `TextDocument`.
    func prepareOutputExport() {
        outputExportDocument = TextDocument(text: executor.output)
        isOutputExporting = true
    }
    
    /// Sends the current input text to the running script's standard input.
    func sendInputToExecutor() {
        executor.sendInput(outputInputText + "\n")
        outputInputText = ""
    }
    
    /// Clears the console output.
    func clearOutput() {
        executor.clearOutput()
    }

    // MARK: - URL Handling
    
    /// Handles incoming URLs (e.g., from deep links) to navigate to specific files and lines.
    ///
    /// - Parameter url: The incoming URL with scheme `novaswift`.
    func handleIncomingURL(_ url: URL) {
        guard url.scheme == "novaswift", url.host == "jump" else { return }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else { return }
        
        let filePath = queryItems.first(where: { $0.name == "file" })?.value
        let line = queryItems.first(where: { $0.name == "line" })?.value.flatMap(Int.init)
        let col = queryItems.first(where: { $0.name == "col" })?.value.flatMap(Int.init)
        
        if let path = filePath {
            let fileURL = URL(fileURLWithPath: path)
            // If it's a different file, open it first
            if currentFile != fileURL {
                openFile(at: fileURL)
            }
        }
        
        if let line = line {
            // Give a small delay to ensure the editor has loaded the new text if needed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.scrollToLocation(line: line, column: col ?? 1)
            }
        }
    }
    
    /// Calculates the character index for a given line and column and updates `selectedRange`.
    ///
    /// - Parameters:
    ///   - line: The 1-based line number.
    ///   - column: The 1-based column number.
    private func scrollToLocation(line: Int, column: Int) {
        let lines = editorText.components(separatedBy: .newlines)
        
        guard line > 0 && line <= lines.count else { return }
        
        var location = 0
        // Sum up lengths of previous lines
        for i in 0..<(line - 1) {
            location += lines[i].utf16.count + 1 // +1 for newline
        }
        
        // Add column offset (1-based to 0-based)
        let targetLineLength = lines[line - 1].utf16.count
        let colIndex = max(0, min(column - 1, targetLineLength))
        location += colIndex
        
        // Setting selectedRange triggers the jump in InputContainer/Editor
        self.selectedRange = NSRange(location: location, length: 0)
    }
}
