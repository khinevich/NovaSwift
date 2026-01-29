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
    @Bindable var model: ContentViewModel
    
    // MARK: - Local State
    
    /// Tracks the presentation of the file importer sheet.
    @State private var isImporting: Bool = false
    
    /// Tracks the presentation of the file exporter (Save As) sheet.
    @State private var isExporting: Bool = false
    
    /// The document wrapper for exporting text.
    @State private var documentToExport: TextDocument?
    
    // MARK: - Computed Properties
    
    /// Determines the programming language based on the current file extension.
    /// Returns the user-selected language for untitled files.
    private var currentLanguage: Language {
        guard let fileName = model.currentFile?.lastPathComponent else { 
            return model.untitledLanguage 
        }
        return Language.from(fileName: fileName)
    }
    
    // MARK: - View
    
    var body: some View {
        VStack(spacing: 0) {
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
                    .disabled(model.executor.isRunning)
                    
                    Button(action: {
                        model.clearEditor()
                    }) {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(model.editorText.isEmpty)
                    
                    Button("Save As") {
                        documentToExport = TextDocument(text: model.editorText)
                        isExporting = true
                    }
                    .disabled(model.editorText.isEmpty)
                    .keyboardShortcut("S", modifiers: [.command, .shift])
                    
                    Button("Save") {
                        if model.currentFile != nil {
                            model.saveFile()
                        } else {
                            // If no file exists, redirect to Save As
                            documentToExport = TextDocument(text: model.editorText)
                            isExporting = true
                        }
                    }
                    .opacity(0)
                    .keyboardShortcut("s", modifiers: .command)
                }
                .controlSize(.large)
                
                Spacer()
                
                // File Name & Language Selection
                HStack(spacing: 8) {
                    if let file = model.currentFile {
                        Text(file.lastPathComponent)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Untitled")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        
                        Picker("", selection: $model.untitledLanguage) {
                            ForEach(Language.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .labelsHidden()
                        .fixedSize()
                    }
                }
                .frame(maxWidth: 200)
                
                Spacer()
                
                // Execution Control (Run, Stop)
                ControlGroup {
                    Button(action: {
                        model.executor.execute(model.editorText, fileURL: model.currentFile, language: currentLanguage)
                    }) {
                        Label("Run", systemImage: "play.fill")
                            .foregroundStyle(.green)
                    }
                    .disabled(model.editorText.isEmpty || model.executor.isRunning)
                    .keyboardShortcut("r", modifiers: .command)
                    
                    Button(action: {
                        model.executor.stop()
                    }) {
                        Label("Stop", systemImage: "stop.fill")
                            .foregroundStyle(.red)
                    }
                    .disabled(!model.executor.isRunning)
                }
                .controlSize(.large)
            }
            
            // The main text editor, configured with the detected language.
            InputEditorView(text: $model.editorText, selectedRange: $model.selectedRange, language: currentLanguage)
        }
        // configure the file importer to support all known languages + plain text
        // for Kotlin, explicitly add a UTType for .kts since it's not a standard system type.
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.swiftSource, .plainText, UTType(filenameExtension: "kts")!], allowsMultipleSelection: false) { result in
            model.handleFileImport(result: result)
        }
        .fileExporter(isPresented: $isExporting, document: documentToExport, contentType: .plainText, // Default type, user can select others if supported by the system dialog
            defaultFilename: model.currentFile?.lastPathComponent ?? "Untitled") { result in
            switch result {
            case .success(let url):
                // Upon successful save, update the current file context to the new file.
                model.openFile(at: url)
            case .failure(let error):
                print("Save failed: \(error.localizedDescription)")
            }
        }
    }
}
