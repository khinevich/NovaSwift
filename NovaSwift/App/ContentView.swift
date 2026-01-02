//
//  ContentView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 29.12.25.
//

import SwiftUI

/// The root view of the application, orchestrating the main layout and shared state.
///
/// `ContentView` adopts a container/presentational pattern where it holds the
/// `ScriptExecutor` as the source of truth for execution state and coordinates
/// the layout between the `InputContainer` and `OutputContainer`.
struct ContentView: View {
    // MARK: - State Properties
    
    /// The central service managing script execution, shared across child views.
    @State private var executor = ScriptExecutor()
    
    /// The project manager handling file system operations.
    @State private var projectManager = ProjectManager()
    
    /// Controls the presentation of the settings sheet.
    @State private var isSettingsPresented = false
    
    /// Controls the presentation of the info sheet.
    @State private var isInfoPresented = false
    
    /// Controls the visibility of the sidebar.
    @State private var isSidebarVisible = false
    
    // MARK: - Editor State
    // Lifted from InputContainer to allow sharing with Sidebar
    @State private var editorText: String = ""
    @State private var currentFile: URL?
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HSplitView {
                    // Sidebar Pane
                    if isSidebarVisible {
                        SidebarView(
                            projectManager: projectManager,
                            selectedFileContent: $editorText,
                            currentFile: $currentFile
                        )
                        .frame(minWidth: 200, maxWidth: 300, maxHeight: .infinity)
                        .layoutPriority(0)
                    }
                    
                    // Main Split: Input & Output
                    HSplitView {
                        // Input Container
                        InputContainer(
                            executor: executor,
                            projectManager: projectManager,
                            editorText: $editorText,
                            currentFile: $currentFile,
                            selectedRange: $selectedRange
                        )
                        .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                        .layoutPriority(1)
                        
                        // Output Container
                        OutputContainer(executor: executor)
                            .frame(minWidth: 200, maxWidth: .infinity, maxHeight: .infinity)
                            .layoutPriority(1)
                    }
                    .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(minHeight: 300, maxHeight: .infinity)
                
                Divider()
                
                // Bottom Bar: Status
                StatusBarView(
                    isRunning: executor.isRunning,
                    isWaitingForInput: executor.isWaitingForInput,
                    exitCode: executor.exitCode
                )
            }
            .navigationTitle("NovaSwift")
            .onOpenURL { url in
                handleIncomingURL(url)
            }
            .toolbar {
                // Sidebar Toggle (Left side)
                ToolbarItem(placement: .navigation) {
                    Button(action: { isSidebarVisible.toggle() }) {
                        Label("Toggle Sidebar", systemImage: "sidebar.left")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ShareButton(
                        title: "Share",
                        systemImage: "square.and.arrow.up",
                        content: executor.output,
                        isEnabled: !executor.isRunning && !executor.output.isEmpty
                    )
                    .frame(width: 30, height: 30)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isSettingsPresented = true }) {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isInfoPresented = true }) {
                        Label("Info", systemImage: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
            .sheet(isPresented: $isInfoPresented) {
                InfoView()
            }
        }
    }
    func handleIncomingURL(_ url: URL) {
        guard url.scheme == "novaswift", url.host == "jump" else { return }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else { return }
        
        let line = queryItems.first(where: { $0.name == "line" })?.value.flatMap(Int.init)
        let col = queryItems.first(where: { $0.name == "col" })?.value.flatMap(Int.init)
        
        if let line = line {
            scrollToLocation(line: line, column: col ?? 1)
        }
    }
    
    func scrollToLocation(line: Int, column: Int) {
        // Convert line/column to character index
        // Lines are 1-based, columns are 1-based
        let lines = editorText.components(separatedBy: .newlines)
        
        guard line > 0 && line <= lines.count else { return }
        
        var location = 0
        // Sum up lengths of previous lines
        for i in 0..<(line - 1) {
            location += lines[i].utf16.count + 1 // +1 for newline
        }
        
        // Add column offset (1-based to 0-based)
        let targetLineLength = lines[line - 1].utf16.count
        let colIndex = max(0, min(column - 1, targetLineLength))
        location += colIndex
        
        self.selectedRange = NSRange(location: location, length: 0)
    }
}

#Preview {
    ContentView()
}

