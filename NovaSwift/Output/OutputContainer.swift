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
    var model: ContentViewModel
    
    // MARK: - Body
    
    var body: some View {
        @Bindable var viewModel = model
        
        VStack(spacing: 0) {
            // Top Bar
            PaneBar {
                Text("Output")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
                
                Spacer()
                
                ControlGroup {
                    // Clear Button
                    Button(action: {
                        viewModel.clearOutput()
                    }) {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(viewModel.executor.output.isEmpty)
                    
                    // Save Button
                    Button(action: {
                        viewModel.prepareOutputExport()
                    }) {
                        Label("Save", systemImage: "tray.and.arrow.down.fill")
                    }
                    .disabled(viewModel.executor.isRunning || viewModel.executor.output.isEmpty)
                }
                .controlSize(.large)
            }
            
            // Output Display
            OutputConsoleView(text: viewModel.executor.attributedOutput)
            
            // Input Field (Only when awaiting input)
            if viewModel.executor.isRunning && viewModel.executor.isWaitingForInput {
                HStack {
                    Text(">")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    TextField("Type input and press Enter to send it...", text: $viewModel.outputInputText)
                        .font(.system(.body, design: .monospaced))
                        .textFieldStyle(.plain)
                        .onSubmit {
                            viewModel.sendInputToExecutor()
                        }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor))
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color(nsColor: .separatorColor)), alignment: .top)
            }
        }
        .fileExporter(
            isPresented: $viewModel.isOutputExporting,
            document: viewModel.outputExportDocument,
            contentType: .plainText,
            defaultFilename: "Output.txt"
        ) { result in
            if case .failure(let error) = result {
                print("Export failed: \(error.localizedDescription)")
            }
        }
    }
}
