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
/// This view acts as the controller for the code editing experience. It leverages `ContentViewModel`
/// for state management and interacts with the `ScriptExecutor` provided by the view model.
struct InputContainer: View {
    // MARK: - Dependencies
    
    /// The shared view model managing the application state.
    var viewModel: ContentViewModel
    
    // MARK: - Local State
    
    /// Tracks the presentation of the file importer sheet.
    @State private var isImporting: Bool = false
    
    /// Tracks the presentation of the file exporter (Save As) sheet.
    @State private var isExporting: Bool = false
    
    /// The document wrapper for exporting text.
    @State private var documentToExport: TextDocument?
    
    // MARK: - Computed Properties
    
    /// Determines the programming language based on the current file extension.
    private var currentLanguage: Language {
        guard let fileName = viewModel.currentFile?.lastPathComponent else { return .swift }
        return Language.from(fileName: fileName)
    }
    
    // MARK: - Body
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        VStack(spacing: 0) {
            // Top Bar: Contains title, file actions, and execution controls.
            PaneBar {
                Text("Input")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 8)
                
                // File Actions (Import, Clear, Save)
                ControlGroup {
                    Button(action: { isImporting = true }) {
                        Label("Import", systemImage: "arrow.up.right")
                    }
                    // Disable import while a script is running to prevent state conflicts.
                    .disabled(viewModel.executor.isRunning)
                    
                    Button(action: {
                        viewModel.clearEditor()
                    }) {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(viewModel.editorText.isEmpty)
                    
                    Button("Save As") {
                        documentToExport = TextDocument(text: viewModel.editorText)
                        isExporting = true
                    }
                    .disabled(viewModel.editorText.isEmpty)
                    .keyboardShortcut("S", modifiers: [.command, .shift]) // Shift+Cmd+S for Save As
                    
                    // Hidden action for standard Save (Cmd+S)
                    Button("Save") {
                        if viewModel.currentFile != nil {
                            viewModel.saveFile()
                        } else {
                            // If no file exists, redirect to Save As
                            documentToExport = TextDocument(text: viewModel.editorText)
                            isExporting = true
                        }
                    }
                    .opacity(0) // Hide from UI
                    .keyboardShortcut("s", modifiers: .command)
                }
                .controlSize(.large)
                
                Spacer()
                
                // File Name Display
                // Shows the current file name and the detected language context.
                Text(viewModel.currentFile?.lastPathComponent ?? "Untitled (\(currentLanguage.displayName))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 200)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                // Execution Control (Run, Stop)
                ControlGroup {
                    Button(action: {
                        viewModel.executor.execute(viewModel.editorText, fileURL: viewModel.currentFile, language: currentLanguage)
                    }) {
                        Label("Run", systemImage: "play.fill")
                            .foregroundStyle(.green)
                    }
                    // Disable run if text is empty or a script is already running.
                    .disabled(viewModel.editorText.isEmpty || viewModel.executor.isRunning)
                    .keyboardShortcut("r", modifiers: .command)
                    
                    Button(action: {
                        viewModel.executor.stop()
                    }) {
                        Label("Stop", systemImage: "stop.fill")
                            .foregroundStyle(.red)
                    }
                    .disabled(!viewModel.executor.isRunning)
                }
                .controlSize(.large)
            }
            
            // Editor Area
            // The main text editor, configured with the detected language.
            InputEditorView(text: $viewModel.editorText, selectedRange: $viewModel.selectedRange, language: currentLanguage)
        }
        // Configure the file importer to support all known languages + plain text.
        // For Kotlin, we explicitly add a UTType for .kts since it's not a standard system type.
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.swiftSource, .plainText, UTType(filenameExtension: "kts")!],
            allowsMultipleSelection: false
        ) { result in
            viewModel.handleFileImport(result: result)
        }
        .fileExporter(
            isPresented: $isExporting,
            document: documentToExport,
            contentType: .plainText, // Default type, user can select others if supported by the system dialog
            defaultFilename: viewModel.currentFile?.lastPathComponent ?? "Untitled"
        ) { result in
            switch result {
            case .success(let url):
                // Upon successful save, update the current file context to the new file.
                // The fileExporter handles the actual writing.
                viewModel.openFile(at: url)
            case .failure(let error):
                print("Save failed: \(error.localizedDescription)")
            }
        }
    }
}
