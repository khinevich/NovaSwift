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
    
    // MARK: - Content State
    @State private var editorText: String = ""
    @State private var consoleOutput: String = ""
    @State private var lastExitCode: Int?
    @State private var fileName: String?
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    
    // MARK: - File Management State
    @State private var isImporting: Bool = false
    @State private var isExporting: Bool = false // Restored
    @State private var exportDocument: TextDocument? // Restored
    
    private let executor = ScriptExecutor()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HSplitView {
                    // Left Pane: Input
                    InputView(editorText: $editorText)
                        .frame(minWidth: 400, maxWidth: .infinity)
                        .layoutPriority(1) // Encourage taking more space (2:1 ratio attempt)
                        .safeAreaInset(edge: .top, spacing: 0) {
                            PaneBar {
                                Text("Input")
                                    .font(.headline) // Bigger font
                                    .foregroundStyle(.secondary)
                                    .padding(.trailing, 8)
                                
                                // File Actions (Now next to Input label)
                                ControlGroup {
                                    Button(action: { isImporting = true }) {
                                        Label("Import", systemImage: "square.and.arrow.down")
                                    }
                                    .disabled(isRunning)
                                    
                                    Button(action: {
                                        editorText = ""
                                        fileName = nil
                                    }) {
                                        Label("Clear", systemImage: "trash")
                                    }
                                    .disabled(editorText.isEmpty)
                                }
                                .controlSize(.large) // Bigger buttons
                                
                                Spacer()
                                
                                // File Name Display
                                Text(fileName ?? "Untitled")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: 200)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                
                                Spacer()
                                
                                // Execution Control (Right side)
                                ControlGroup {
                                    Button(action: runScript) {
                                        Label("Run", systemImage: "play.fill")
                                            .foregroundStyle(.green) // Explicit color
                                    }
                                    .disabled(editorText.isEmpty || isRunning)
                                    .keyboardShortcut("r", modifiers: .command)
                                    
                                    Button(action: {
                                        isRunning = false
                                        executor.stop()
                                    }) {
                                        Label("Stop", systemImage: "stop.fill")
                                            .foregroundStyle(.red) // Explicit color
                                    }
                                    .disabled(!isRunning)
                                }
                                .controlSize(.large) // Bigger buttons
                            }
                        }
                    
                    // Right Pane: Output
                    OutputView(output: consoleOutput)
                        .frame(minWidth: 200, maxWidth: .infinity)
                        .layoutPriority(1)
                        .safeAreaInset(edge: .top, spacing: 0) {
                            PaneBar {
                                Text("Output")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 4)
                                
                                Spacer()
                                
                                ControlGroup {
                                    // 1. Clear
                                    Button(action: { consoleOutput = "" }) {
                                        Label("Clear", systemImage: "trash")
                                    }
                                    .disabled(consoleOutput.isEmpty)
                                    
                                    // 2. Save to File
                                    Button(action: {
                                        exportDocument = TextDocument(text: consoleOutput)
                                        isExporting = true
                                    }) {
                                        Label("Save", systemImage: "doc.fill")
                                    }
                                    .disabled(isRunning || consoleOutput.isEmpty)
                                }
                                .controlSize(.large)
                                
                                // 3. Native Share (Outside ControlGroup for visibility)
                                ShareButton(
                                    title: "Share",
                                    systemImage: "square.and.arrow.up",
                                    content: consoleOutput,
                                    isEnabled: !isRunning && !consoleOutput.isEmpty
                                )
                                .frame(width: 28, height: 28) // Explicit size for the icon
                                .padding(.leading, 8)
                            }
                        }
                }
                .frame(minHeight: 300, maxHeight: .infinity)
                
                Divider()
                
                StatusBarView(isRunning: isRunning, exitCode: lastExitCode)
            }
            .navigationTitle("NovaSwift")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: {}) {
                        Label("Settings", systemImage: "gearshape")
                    }
                    Button(action: {}) {
                        Label("Info", systemImage: "info.circle")
                    }
                }
            }
            
            // MARK: - File Handling Modifiers
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.swiftSource, .plainText],
                allowsMultipleSelection: false
            ) { result in
                importFile(result: result)
            }
            // Restored File Exporter
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .plainText,
                defaultFilename: "Output.txt"
            ) { result in
                if case .failure(let error) = result {
                    print("Export failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Components

/// A styled header bar for panes (Input/Output).
struct PaneBar<Content: View>: View {
    @ViewBuilder var content: Content
    
    var body: some View {
        HStack(spacing: 12) {
            content
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .buttonStyle(.borderless) // Matches standard Toolbar button appearance
    }
}

// MARK: - Logic Extensions

extension ContentView {
    /// Reads the selected file securely and updates the editor content.
    private func importFile(result: Result<[URL], Error>) {
        do {
            guard let selectedFile: URL = try result.get().first else { return }
            
            // Required for App Store sandboxed apps to access user-selected files.
            if selectedFile.startAccessingSecurityScopedResource() {
                defer { selectedFile.stopAccessingSecurityScopedResource() }
                
                let fileContent = try String(contentsOf: selectedFile, encoding: .utf8)
                
                // UI updates must happen on the Main Actor.
                // We wrap this in a Task because fileImporter expects a synchronous closure.
                Task { @MainActor in
                    editorText = fileContent
                    fileName = selectedFile.lastPathComponent
                }
            }
        } catch {
            print("Import failed: \(error.localizedDescription)")
        }
    }

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
    
    /// Calculates the character index (NSRange) for a given line and column
    /// and updates the editor's cursor position.
    private func jumpToLocation(line: Int, col: Int) {
        let lines = editorText.components(separatedBy: .newlines)
        guard line > 0, line <= lines.count else { return }
        
        var location = 0
        for i in 0..<(line - 1) {
            // +1 for the newline character that components(separatedBy:) removes
            location += lines[i].utf16.count + 1
        }
        
        // Add column offset (clamping to the line length to prevent crashes)
        let lineLength = lines[line - 1].utf16.count
        // Swift errors are 1-based, index is 0-based.
        let columnOffset = min(max(0, col - 1), lineLength)
        location += columnOffset
        
        selectedRange = NSRange(location: location, length: 0)
    }
    
    /// Presents the native macOS Share Sheet (NSSharingServicePicker)
    /// using a temporary file to ensure broad compatibility (AirDrop, etc).
    private func showShareSheet() {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Output.txt")
        
        do {
            try consoleOutput.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to write temp file for sharing: \(error)")
            return
        }
        
        // Find the active window content view to anchor the picker
        guard let contentView = NSApp.keyWindow?.contentView else { return }
        
        let picker = NSSharingServicePicker(items: [fileURL])
        // Anchor to the approximate location of the export button (bottom right of the split, top bar)
        // Since we can't easily get the exact button frame from here without GeometryReader,
        // we center it or anchor it to the mouse event, but for simplicity/reliability in SwiftUI:
        // We will display it relative to the view's bounds or simply center it.
        // Better: Anchor to the mouse location if possible, or just the view center.
        
        // Using a rect in the top-right quadrant of the window as a heuristic anchor
        let anchorRect = NSRect(x: contentView.bounds.width - 100, y: contentView.bounds.height - 100, width: 1, height: 1)
        
        picker.show(relativeTo: anchorRect, of: contentView, preferredEdge: .minY)
    }
}

#Preview {
    ContentView()
}

