//
//  ContentView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 29.12.25.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct ContentView: View {
    // MARK: - State Properties
    
    // Tracks execution status to toggle UI interactivity (e.g., disable Import while running).
    @State private var isRunning: Bool = false
    
    // The script content to be executed.
    @State private var editorText: String = ""
    
    // Accumulates stdout/stderr from the running process.
    @State private var consoleOutput: String = ""
    
    // Stores the exit code of the last run (0 for success, non-zero for error).
    @State private var lastExitCode: Int? = nil
    
    // Displayed in the window title to indicate the currently active file.
    @State private var fileName: String?
    
    // MARK: - File Management State
    @State private var isImporting: Bool = false
    @State private var isExporting: Bool = false
    @State private var exportDocument: TextDocument?
    
    private let executor = ScriptExecutor()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // HSplitView allows the user to resize the editor and output panes.
                HSplitView {
                    InputView(editorText: $editorText)
                        .frame(minWidth: 400, maxWidth: .infinity)
                    OutputView(output: consoleOutput)
                        .frame(minWidth: 200, maxWidth: .infinity)
                }
                .frame(minHeight: 300, maxHeight: .infinity)
                Divider()
                StatusBarView(isRunning: isRunning, exitCode: lastExitCode)
            }
            .navigationTitle(fileName ?? "NovaSwift")
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button(action: {
                        isImporting = true
                    }) {
                        Label("Import script", systemImage: "plus")
                    }
                    .disabled(isRunning)
                    Button(action: {
                        editorText = ""
                        fileName = nil
                    }) {
                        Label("Clear input", systemImage: "trash")
                    }
                    .disabled(editorText.isEmpty)
                }
                ToolbarItemGroup(placement: .secondaryAction) {
                    Button(action: {
                        runScript()
                    }) {
                        Label("Run", systemImage: "play.fill")
                            .tint(.green)
                    }
                    .disabled(editorText.isEmpty || isRunning)
                    .foregroundStyle(.green)
                    .help("Run Script (⌘R)")
                    Button(action: {
                        isRunning = false
                    }) {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .foregroundStyle(.red)
                    .disabled(!isRunning)
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: {
                        consoleOutput = ""
                    }) {
                        Label("Clear output", systemImage: "trash")
                    }
                    .disabled(consoleOutput.isEmpty)
                    
                    Button(action: {
                        exportDocument = TextDocument(text: consoleOutput)
                        isExporting = true
                    }) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(isRunning || consoleOutput.isEmpty)
                    .help("Export the output")
                }
            }
            // Presents the native file picker for importing Swift scripts.
            // Security Scoped Resource access is handled in the closure.
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.swiftSource, .plainText],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let selectedFile: URL = try result.get().first else { return }
                    // Crucial: Must start accessing the security-scoped resource to read files outside the sandbox.
                    if selectedFile.startAccessingSecurityScopedResource() {
                        defer { selectedFile.stopAccessingSecurityScopedResource() }
                        let fileContent = try String(contentsOf: selectedFile, encoding: .utf8)
                        
                        // Wrap the UI update in a Task because the fileImporter completion is synchronous,
                        // but updating @State must happen on the MainActor.
                        Task { @MainActor in
                            editorText = fileContent
                            fileName = selectedFile.lastPathComponent
                        }
                    }
                } catch {
                    print("Error reading file: \(error.localizedDescription)")
                }
            }
            // exports the current console output to a text file.
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .plainText,
                defaultFilename: "Output.txt"
            ) { result in
                if case .failure(let error) = result {
                    print("Error exporting file: \(error.localizedDescription)")
                }
            }
        }
    }
}

extension ContentView {
    /// Resets the console and initiates the script execution.
    /// Uses an async Task to consume the event stream without blocking the UI.
    private func runScript() {
        consoleOutput = ""
        isRunning = true
        lastExitCode = nil
        
        Task {
            // execute() returns an AsyncStream that yields output events in real-time.
            let stream = executor.execute(editorText)
            
            for await event in stream {
                switch event {
                case .stdout(let line):
                    await MainActor.run {
                        consoleOutput += line
                    }
                case .exitCode(let code):
                    await MainActor.run {
                        lastExitCode = Int(code)
                        isRunning = false
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

