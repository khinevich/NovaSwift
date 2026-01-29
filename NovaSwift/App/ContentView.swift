//
//  ContentView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 29.12.25.
//

import SwiftUI

/// The root view of the application, orchestrating the main layout and shared state.
///
/// `ContentView` adopts the MV pattern, delegating state management and business logic
/// to `ContentViewModel`. It coordinates the layout between the Sidebar, Input, and Output modules.
struct ContentView: View {
    // MARK: - View Model
    
    /// The central view model managing the application state and services.
    @State private var model = ContentViewModel()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main horizontal split view dividing Sidebar and Content
                HSplitView {
                    // Sidebar Pane: Displays the file explorer
                    if model.isSidebarVisible {
                        SidebarView(
                            viewModel: model.sidebarModel,
                            selectedFileContent: $model.editorText,
                            currentFile: $model.currentFile
                        )
                        .frame(minWidth: 200, maxWidth: 300, maxHeight: .infinity)
                        .layoutPriority(0)
                    }
                    
                    // Content Split: Input Editor & Output Console
                    HSplitView {
                        // Input Area: Code editor
                        InputContainer(model: model)
                            .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                            .layoutPriority(1)
                        
                        // Output Area: Console logs and script output
                        OutputContainer(model: model)
                            .frame(minWidth: 200, maxWidth: .infinity, maxHeight: .infinity)
                            .layoutPriority(1)
                    }
                    .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(minHeight: 300, maxHeight: .infinity)
                
                Divider()
                
                // Bottom Status Bar: Shows execution state
                StatusBarView(
                    isRunning: model.executor.isRunning,
                    isWaitingForInput: model.executor.isWaitingForInput,
                    exitCode: model.executor.exitCode
                )
            }
            .navigationTitle("NovaSwift")
            // Handle deep links for file navigation
            .onOpenURL { url in
                model.handleIncomingURL(url)
            }
            .toolbar {
                // Sidebar Toggle (Left side)
                ToolbarItem(placement: .navigation) {
                    Button(action: { model.isSidebarVisible.toggle() }) {
                        Label("Toggle Sidebar", systemImage: "sidebar.left")
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    // This replaces your entire file
                    ShareLink(item: ScriptOutputExport(content: model.executor.output), preview: SharePreview("Output.txt", image: Image(systemName: "doc.text"))) {
                        Image(systemName: "square.and.arrow.up")
                    } // Lazy Creation: The file Output.txt is only created when the user clicks share
                    .disabled(model.executor.isRunning || model.executor.output.isEmpty)
                    
                    Button(action: { model.isSettingsPresented = true }) {
                        Label("Settings", systemImage: "gearshape")
                    }
                    Button(action: { model.isInfoPresented = true }) {
                        Label("Info", systemImage: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $model.isSettingsPresented) {
                SettingsView()
            }
            .sheet(isPresented: $model.isInfoPresented) {
                InfoView()
            }
        }
    }
}

#Preview {
    ContentView()
}
