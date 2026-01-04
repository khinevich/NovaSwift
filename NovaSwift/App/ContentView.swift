//
//  ContentView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 29.12.25.
//

import SwiftUI

/// The root view of the application, orchestrating the main layout and shared state.
///
/// `ContentView` adopts the MVVM pattern, delegating state management and business logic
/// to `ContentViewModel`. It coordinates the layout between the Sidebar, Input, and Output modules.
struct ContentView: View {
    // MARK: - View Model
    
    /// The central view model managing the application state and services.
    @State private var viewModel = ContentViewModel()
    
    // MARK: - Body
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        NavigationStack {
            VStack(spacing: 0) {
                HSplitView {
                    // Sidebar Pane
                    if viewModel.isSidebarVisible {
                        SidebarView(
                            projectManager: viewModel.projectManager,
                            selectedFileContent: $viewModel.editorText,
                            currentFile: $viewModel.currentFile
                        )
                        .frame(minWidth: 200, maxWidth: 300, maxHeight: .infinity)
                        .layoutPriority(0)
                    }
                    
                    // Main Split: Input & Output
                    HSplitView {
                        // Input Container
                        InputContainer(viewModel: viewModel)
                            .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                            .layoutPriority(1)
                        
                        // Output Container
                        OutputContainer(viewModel: viewModel)
                            .frame(minWidth: 200, maxWidth: .infinity, maxHeight: .infinity)
                            .layoutPriority(1)
                    }
                    .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(minHeight: 300, maxHeight: .infinity)
                
                Divider()
                
                // Bottom Bar: Status
                StatusBarView(
                    isRunning: viewModel.executor.isRunning,
                    isWaitingForInput: viewModel.executor.isWaitingForInput,
                    exitCode: viewModel.executor.exitCode
                )
            }
            .navigationTitle("NovaSwift")
            .onOpenURL { url in
                viewModel.handleIncomingURL(url)
            }
            .toolbar {
                // Sidebar Toggle (Left side)
                ToolbarItem(placement: .navigation) {
                    Button(action: { viewModel.isSidebarVisible.toggle() }) {
                        Label("Toggle Sidebar", systemImage: "sidebar.left")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    // This replaces your entire file
                    
                    ShareLink(item: ScriptOutputExport(content: viewModel.executor.output), preview: SharePreview("Output.txt", image: Image(systemName: "doc.text"))) {
                        Image(systemName: "square.and.arrow.up") // Standard macOS Share Icon
                    } // Lazy Creation: The file Output.txt is only created when the user clicks share
                    .disabled(viewModel.executor.isRunning || viewModel.executor.output.isEmpty)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { viewModel.isSettingsPresented = true }) {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { viewModel.isInfoPresented = true }) {
                        Label("Info", systemImage: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isSettingsPresented) {
                SettingsView()
            }
            .sheet(isPresented: $viewModel.isInfoPresented) {
                InfoView()
            }
        }
    }
}

#Preview {
    ContentView()
}
