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
/// It allows users to browse files and open them in the editor.
///
/// - Key Features:
///   - Displays a folder tree structure using a recursive `List`.
///   - Visualizes file types with specific icons (Folder, Swift, Kotlin).
///   - Handles file selection and loading content into the editor bindings.
///   - Provides an interface to open a new root folder.
struct SidebarView: View {
    // MARK: - Dependencies
    
    /// The project manager responsible for file system data.
    /// It holds the list of `FileSystemItem`s loaded from the root URL.
    @Bindable var projectManager: ProjectManager
    
    // MARK: - Bindings
    
    /// The text content of the currently selected file.
    /// When a file is clicked, its content is read into this binding.
    @Binding var selectedFileContent: String
    
    /// The name of the currently selected file.
    /// Used to highlight the active file in the list.
    @Binding var currentFileName: String?
    
    // MARK: - Local State
    
    /// Controls the presentation of the folder importer sheet.
    @State private var isImporterPresented: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header / Title
            PaneBar {
                Text("Explorer")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                
                // Open Folder Button
                ControlGroup {
                    Button(action: { isImporterPresented = true }) {
                        Label("Open", systemImage: "folder.badge.plus")
                    }
                }
                .controlSize(.large)
            }
            
            // File List
            if let _ = projectManager.rootURL {
                List(projectManager.items, children: \.children) { item in
                    HStack {
                        // Icon Selection Logic
                        if item.isDirectory {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                        } else if item.name.hasSuffix(".kts") {
                            // Use custom asset for Kotlin files
                            Image("Kotlin")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                        } else if item.name.hasSuffix(".swift") {
                            // Use system symbol for Swift files
                            Image(systemName: "swift")
                                .foregroundColor(.orange)
                        } else {
                            // Fallback for other file types
                            Image(systemName: "doc")
                                .foregroundColor(.gray)
                        }
                        
                        Text(item.name)
                            .foregroundColor(currentFileName == item.name ? .primary : .primary)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .background(
                        // Highlight selection
                        RoundedRectangle(cornerRadius: 4)
                            .fill(currentFileName == item.name ? Color.blue.opacity(0.2) : Color.clear)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !item.isDirectory {
                            openFile(item)
                        }
                    }
                }
                .listStyle(.sidebar)
            } else {
                // Empty State
                ContentUnavailableView {
                    Label("No Folder Opened", systemImage: "folder")
                } description: {
                    Text("Open a folder to browse files.")
                } actions: {
                    Button("Open Folder") {
                        isImporterPresented = true
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxHeight: .infinity)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    projectManager.openFolder(url)
                }
            case .failure(let error):
                print("Failed to open folder: \(error.localizedDescription)")
            }
        }
    }
    
    /// Opens a file and updates the editor state.
    ///
    /// - Parameter item: The `FileSystemItem` representing the file to open.
    private func openFile(_ item: FileSystemItem) {
        if let content = projectManager.readFile(item.url) {
            self.selectedFileContent = content
            self.currentFileName = item.name
        }
    }
}