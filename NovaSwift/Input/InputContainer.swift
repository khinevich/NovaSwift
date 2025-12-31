//
//  InputContainer.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 31.12.25.
//

import SwiftUI
internal import UniformTypeIdentifiers

/// A container view responsible for managing the input code, file operations, and execution controls.
///
/// This view holds the state for the source code (`editorText`), the current file name,
/// and handles file importing logic. It interacts with the `ScriptExecutor` to run the code.
struct InputContainer: View {
    // MARK: - Dependencies
    
    /// The shared script execution service.
    var executor: ScriptExecutor
    
    // MARK: - Local State
    
    /// The current source code text.
    @State private var editorText: String = ""
    
    /// The name of the currently loaded file, if any.
    @State private var fileName: String?
    
    /// Tracks the presentation of the file importer sheet.
    @State private var isImporting: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            PaneBar {
                Text("Input")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 8)
                
                // File Actions
                ControlGroup {
                    Button(action: { isImporting = true }) {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    .disabled(executor.isRunning)
                    
                    Button(action: {
                        editorText = ""
                        fileName = nil
                    }) {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(editorText.isEmpty)
                }
                .controlSize(.large)
                
                Spacer()
                
                // File Name Display
                Text(fileName ?? "Untitled")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 200)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                // Execution Control
                ControlGroup {
                    Button(action: {
                        executor.execute(editorText)
                    }) {
                        Label("Run", systemImage: "play.fill")
                            .foregroundStyle(.green)
                    }
                    .disabled(editorText.isEmpty || executor.isRunning)
                    .keyboardShortcut("r", modifiers: .command)
                    
                    Button(action: {
                        executor.stop()
                    }) {
                        Label("Stop", systemImage: "stop.fill")
                            .foregroundStyle(.red)
                    }
                    .disabled(!executor.isRunning)
                }
                .controlSize(.large)
            }
            
            Divider()
            
            // Editor Area
            InputEditorView(text: $editorText)
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.swiftSource, .plainText],
            allowsMultipleSelection: false
        ) { result in
            importFile(result: result)
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles the result of a file import operation.
    ///
    /// - Parameter result: The result from the file importer, containing selected URLs or an error.
    private func importFile(result: Result<[URL], Error>) {
        do {
            guard let selectedFile: URL = try result.get().first else { return }
            
            if selectedFile.startAccessingSecurityScopedResource() {
                defer { selectedFile.stopAccessingSecurityScopedResource() }
                
                let fileContent = try String(contentsOf: selectedFile, encoding: .utf8)
                
                Task { @MainActor in
                    editorText = fileContent
                    fileName = selectedFile.lastPathComponent
                }
            }
        } catch {
            print("Import failed: \(error.localizedDescription)")
        }
    }
}
