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
    @State private var consoleOutput: String = ""
    @State private var lastExitCode: Int? = nil
    @State private var fileName: String?
    
    private let executor = ScriptExecutor()
    
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
                        runScript()
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

extension ContentView {
    private func runScript() {
        consoleOutput = ""
        isRunning = true
        lastExitCode = nil
        Task {
            let stream = executor.execute(editorText)
            
            for await event in stream {
                switch event {
                case .stdout(let line):
                    await MainActor.run {
                        consoleOutput += line
                    }
                case .exitCode(let code):
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
