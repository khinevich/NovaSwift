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
                            currentFile: $currentFile
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
                StatusBarView(isRunning: executor.isRunning, exitCode: executor.exitCode)
            }
            .navigationTitle("NovaSwift")
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
}

#Preview {
    ContentView()
}

