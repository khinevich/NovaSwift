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
/// This view acts as the controller for the code editing experience. It holds the state for the
/// source code (`editorText`), tracks the current file context (`fileName`), and handles actions
/// like importing files and triggering script execution via the `ScriptExecutor`.
struct InputContainer: View {
    // MARK: - Dependencies
    
    /// The shared script execution service.
    /// Used to run the code currently present in the editor.
    var executor: ScriptExecutor
    
    /// The project manager handling file system operations.
    /// Used for reading file content during import.
    var projectManager: ProjectManager
    
    // MARK: - Bindings
    
    /// The current source code text (bound to parent state).
    @Binding var editorText: String
    
    /// The currently loaded file URL (bound to parent state).
    /// If `nil`, the editor is in an "Untitled" state.
    @Binding var currentFile: URL?
    
    /// The selected range of the text (cursor position).
    @Binding var selectedRange: NSRange
    
    // MARK: - Local State
    
    /// Tracks the presentation of the file importer sheet.
    @State private var isImporting: Bool = false
    
    // MARK: - Computed Properties
    
    /// Determines the programming language based on the current file extension.
    ///
    /// If `currentFile` is `nil` or has an unknown extension, this defaults to `.swift`.
    /// This property is used to configure the syntax highlighter and the script executor.
    private var currentLanguage: Language {
        guard let fileName = currentFile?.lastPathComponent else { return .swift }
        return Language.from(fileName: fileName)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar: Contains title, file actions, and execution controls.
            PaneBar {
                Text("Input")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 8)
                
                // File Actions (Import, Clear)
                ControlGroup {
                    Button(action: { isImporting = true }) {
                        Label("Import", systemImage: "arrow.up.right")
                    }
                    // Disable import while a script is running to prevent state conflicts.
                    .disabled(executor.isRunning)
                    
                    Button(action: {
                        editorText = ""
                        currentFile = nil
                    }) {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(editorText.isEmpty)
                    
                    Button(action: {
                        if let url = currentFile {
                            projectManager.saveFile(url, content: editorText)
                        }
                    }) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .disabled(currentFile == nil)
                    .keyboardShortcut("s", modifiers: .command)
                }
                .controlSize(.large)
                
                Spacer()
                
                // File Name Display
                // Shows the current file name and the detected language context.
                Text(currentFile?.lastPathComponent ?? "Untitled (\(currentLanguage.displayName))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 200)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                // Execution Control (Run, Stop)
                ControlGroup {
                    Button(action: {
                        executor.execute(editorText, fileURL: currentFile, language: currentLanguage)
                    }) {
                        Label("Run", systemImage: "play.fill")
                            .foregroundStyle(.green)
                    }
                    // Disable run if text is empty or a script is already running.
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
            
            // Editor Area
            // The main text editor, configured with the detected language.
            InputEditorView(text: $editorText, selectedRange: $selectedRange, language: currentLanguage)
        }
        // Configure the file importer to support all known languages + plain text.
        // For Kotlin, we explicitly add a UTType for .kts since it's not a standard system type.
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.swiftSource, .plainText, UTType(filenameExtension: "kts")!],
            allowsMultipleSelection: false
        ) { result in
            importFile(result: result)
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles the result of a file import operation.
    ///
    /// Reads the content of the selected file using `ProjectManager` and updates the
    /// editor state (`editorText` and `currentFile`) on the main thread.
    ///
    /// - Parameter result: The result from the file importer, containing selected URLs or an error.
    private func importFile(result: Result<[URL], Error>) {
        do {
            guard let selectedFile: URL = try result.get().first else { return }
            
            if let fileContent = projectManager.readFile(selectedFile) {
                Task { @MainActor in
                    editorText = fileContent
                    currentFile = selectedFile
                }
            }
        } catch {
            print("Import failed: \(error.localizedDescription)")
        }
    }
}
