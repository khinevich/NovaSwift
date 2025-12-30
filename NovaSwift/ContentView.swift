//
//  ContentView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 29.12.25.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isRunning: Bool = false
    @State private var editorText: String = ""
    @State private var consoleOutput: String = ""
    @State private var lastExitCode: Int? = nil
    @State private var fileName: String?
    @State private var isImporting: Bool = false
    @State private var isExporting: Bool = false
    @State private var exportDocument: TextDocument?
    
    private let executor = ScriptExecutor()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.swiftSource, .plainText],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let selectedFile: URL = try result.get().first else { return }
                    if selectedFile.startAccessingSecurityScopedResource() {
                        defer { selectedFile.stopAccessingSecurityScopedResource() }
                        let fileContent = try String(contentsOf: selectedFile, encoding: .utf8)
                        
                        // async UI update
                        Task { @MainActor in
                            editorText = fileContent
                            fileName = selectedFile.lastPathComponent
                        }
                    }
                } catch {
                    print("Error reading file: \(error.localizedDescription)")
                }
            }
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
    private func runScript() {
        // 1. Reset UI state for a new run
        consoleOutput = ""
        isRunning = true
        lastExitCode = nil
        
        // 2. Start a background task to bridge the imperative Process world with SwiftUI
        Task {
            // 3. Call the executor which returns a stream of events (output chunks or exit code)
            let stream = executor.execute(editorText)
            
            // 4. Await events as they arrive in real-time
            for await event in stream {
                switch event {
                case .stdout(let line):
                    // 5. Update the UI on the Main Actor (UI Thread)
                    await MainActor.run {
                        consoleOutput += line
                    }
                case .exitCode(let code):
                    // 6. Handle process termination
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

