//
//  SidebarView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 31.12.25.
//

import SwiftUI
internal import UniformTypeIdentifiers

/// A view representing the project's file explorer sidebar.
///
/// This view displays the file system hierarchy rooted at the selected folder.
/// It delegates business logic and state management to `SidebarViewModel`.
///
/// - Key Features:
///   - Displays a folder tree structure using a recursive `List`.
///   - Visualizes file types with specific icons.
///   - Handles file selection, creation, renaming, and deletion.
struct SidebarView: View {
    // MARK: - View Model
    
    /// The view model managing the sidebar's state and logic.
    @State private var viewModel: SidebarModel
    
    // MARK: - Bindings
    
    /// The text content of the currently selected file.
    @Binding var selectedFileContent: String
    
    /// The URL of the currently selected file.
    @Binding var currentFile: URL?
    
    // MARK: - Local State
    
    /// Focus state for the rename text field.
    @FocusState private var isRenaming: Bool
    
    // MARK: - Initialization
    
    init(projectManager: ProjectManager, selectedFileContent: Binding<String>, currentFile: Binding<URL?>) {
        self._viewModel = State(initialValue: SidebarModel(projectManager: projectManager))
        self._selectedFileContent = selectedFileContent
        self._currentFile = currentFile
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header / Title
            PaneBar {
                Text("Explorer")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                
                // Toolbar Actions
                ControlGroup {
                    Button(action: {
                        viewModel.createNewFile()
                        // Automatically focus the new item's text field if renaming starts
                        isRenaming = true
                    }) {
                        Label("Add", systemImage: "plus")
                    }
                    .disabled(viewModel.projectManager.rootURL == nil)
                    
                    Button(action: { viewModel.isImporterPresented = true }) {
                        Label("Open", systemImage: "folder.badge.plus")
                    }
                }
                .controlSize(.large)
            }
            
            // File List
            if let _ = viewModel.projectManager.rootURL {
                List(viewModel.projectManager.items, children: \.children) { item in
                    HStack {
                        // Icon Selection
                        if item.isDirectory {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                        } else if item.name.hasSuffix(".kts") {
                            Image("Kotlin")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                        } else if item.name.hasSuffix(".swift") {
                            Image(systemName: "swift")
                                .foregroundColor(.orange)
                        } else {
                            Image(systemName: "doc")
                                .foregroundColor(.gray)
                        }
                
                        // Inline Renaming vs Text Display
                        if viewModel.renamingItemId == item.id {
                            TextField("Name", text: $viewModel.editingName)
                                .focused($isRenaming)
                                .onSubmit {
                                    viewModel.completeRename(item: item)
                                    isRenaming = false
                                }
                                .onChange(of: isRenaming, perform: { newValue in
                                    if !newValue && viewModel.renamingItemId == item.id {
                                        viewModel.completeRename(item: item)
                                    }
                                })
                                .onExitCommand {
                                    viewModel.renamingItemId = nil // Cancel without saving
                                    isRenaming = false
                                }
                                .textFieldStyle(.plain)
                                .padding(2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)
                        } else {
                            Text(item.name)
                                .foregroundColor(currentFile == item.url ? .primary : .secondary)
                                .contentShape(Rectangle()) // Makes the whole row clickable, not just the text
                                .onTapGesture { // Selection (Click)
                                    if viewModel.renamingItemId == nil {
                                        if !item.isDirectory {
                                            viewModel.openFile(item, currentFile: $currentFile, contentBinding: $selectedFileContent)
                                        }
                                    }
                                }
                                .background { // "Enter to Rename" (Keyboard)
                                    // "Ghost" Button: Only exists if this row is selected
                                    if currentFile == item.url {
                                        Button("RenameShortcut") {
                                            viewModel.startRenaming(item)
                                            isRenaming = true // trigger focus immediately
                                        }
                                        .keyboardShortcut(.return, modifiers: []) // ↵ Key
                                        .opacity(0)
                                    }
                                }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(currentFile == item.url && viewModel.renamingItemId != item.id ? Color.blue.opacity(0.2) : Color.clear)
                    )
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button("Rename") {
                            viewModel.startRenaming(item)
                            isRenaming = true
                        }
                        
                        Button("Show in Finder") {
                            // standard, built-in AppKit API, to open Finder
                            NSWorkspace.shared.activateFileViewerSelecting([item.url])
                        }
                        
                        Divider()
                        
                        Button("Delete", role: .destructive) {
                            viewModel.deleteItem(item, currentFile: $currentFile, contentBinding: $selectedFileContent)
                        }
                    }
                    .onTapGesture {
                        if viewModel.renamingItemId == nil {
                            if !item.isDirectory {
                                viewModel.openFile(item, currentFile: $currentFile, contentBinding: $selectedFileContent)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            } else {
                ContentUnavailableView {
                    Label("No Folder Opened", systemImage: "folder")
                } description: {
                    Text("Open a folder to browse files.")
                } actions: {
                    Button("Open Folder") {
                        viewModel.isImporterPresented = true
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxHeight: .infinity)
        .fileImporter(isPresented: $viewModel.isImporterPresented, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.openFolder(url)
                }
            case .failure(let error):
                print("Failed to open folder: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedFileContent: String = "test.swift"
    @Previewable @State var currentFile: URL? = nil
    SidebarView(projectManager: ProjectManager(), selectedFileContent: $selectedFileContent, currentFile: $currentFile)
}
