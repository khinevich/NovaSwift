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
    
    /// Controls the presentation of the settings sheet.
    @State private var isSettingsPresented = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HSplitView {
                    // Left Pane: Input Container
                    // Manages the code editor and file importing.
                    InputContainer(executor: executor)
                        .frame(minWidth: 400, maxWidth: .infinity)
                        .layoutPriority(1)
                    
                    // Right Pane: Output Container
                    // Manages the console output display and file exporting.
                    OutputContainer(executor: executor)
                        .frame(minWidth: 200, maxWidth: .infinity)
                        .layoutPriority(1)
                }
                .frame(minHeight: 300, maxHeight: .infinity)
                
                Divider()
                
                // Bottom Bar: Status
                StatusBarView(isRunning: executor.isRunning, exitCode: executor.exitCode)
            }
            .navigationTitle("NovaSwift")
            .toolbar {
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
                    Button(action: {}) {
                        Label("Info", systemImage: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
}

