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
    
    /// The shared script execution service, observed for output updates.
    @Bindable var executor: ScriptExecutor
    
    // MARK: - Local State
    
    /// Tracks the presentation of the file exporter sheet.
    @State private var isExporting: Bool = false
    
    /// The document wrapper for exporting text.
    @State private var exportDocument: TextDocument?
    
    // MARK: - Body
    
    var body: some View {
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
                        executor.clearOutput()
                    }) {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(executor.output.isEmpty)
                    
                    // Save Button
                    Button(action: {
                        exportDocument = TextDocument(text: executor.output)
                        isExporting = true
                    }) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .disabled(executor.isRunning || executor.output.isEmpty)
                }
                .controlSize(.large)
            }
            
            // Output Display
            OutputConsoleView(text: executor.output)
        }
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
