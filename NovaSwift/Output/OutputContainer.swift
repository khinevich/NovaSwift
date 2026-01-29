//
//  OutputContainer.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 31.12.25.
//

import SwiftUI
internal import UniformTypeIdentifiers

/// A container view responsible for displaying script output and handling export operations.
///
/// This view observes the `ScriptExecutor` to display real-time output. It also manages
/// the functionality to clear the console, save output to a file, and share it.
struct OutputContainer: View {
    // MARK: - Dependencies
    
    /// The shared view model managing the application state.
    @Bindable var model: ContentViewModel
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            PaneBar {
                Text("Output")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
                
                Spacer()
                
                ControlGroup {
                    Button(action: {
                        model.clearOutput()
                    }) {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(model.executor.output.isEmpty)
                    
                    Button(action: {
                        model.prepareOutputExport()
                    }) {
                        Label("Save", systemImage: "tray.and.arrow.down.fill")
                    }
                    .disabled(model.executor.isRunning || model.executor.output.isEmpty)
                }
                .controlSize(.large)
            }
        
            OutputConsoleView(text: model.executor.attributedOutput)
            
            // Input Field (Only when awaiting input)
            if model.executor.isRunning && model.executor.isWaitingForInput {
                HStack {
                    Text(">")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    TextField("Type input and press Enter to send it...", text: $model.outputInputText)
                        .font(.system(.body, design: .monospaced))
                        .textFieldStyle(.plain)
                        .onSubmit {
                            model.sendInputToExecutor()
                        }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor))
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color(nsColor: .separatorColor)), alignment: .top)
            }
        }
        .fileExporter(isPresented: $model.isOutputExporting, document: model.outputExportDocument, contentType: .plainText, defaultFilename: "Output.txt") { result in
            if case .failure(let error) = result {
                print("Export failed: \(error.localizedDescription)")
            }
        }
    }
}
