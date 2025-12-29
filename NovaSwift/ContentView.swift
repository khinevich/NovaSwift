//
//  ContentView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 29.12.25.
//

import SwiftUI

struct ContentView: View {
    @State private var isRunning: Bool = false
    @State private var editorText: String = "// Write your Swift script here...\nprint(\"Hello, World!\")"
    @State private var consoleOutput: String = "Console output will appear here..."
    @State private var lastExitCode: Int? = nil
    @State private var fileName: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HSplitView {
                    EditorView(text: $editorText)
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
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        //
                    }) {
                        Label("Import script", systemImage: "plus")
                    }
                    .disabled(isRunning)
                }
                ToolbarItemGroup(placement: .secondaryAction) {
                    Button(action: {
                        isRunning = true
                    }) {
                        Label("Run", systemImage: "play.fill")
                            .tint(.green)
                    }
                    .disabled(isRunning)
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
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button(action: {
                        //
                    }) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(isRunning)
                    .help("Export the output")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
