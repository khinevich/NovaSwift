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
///   - Displays a folder tree structure.
///   - Handles file selection and loading content into the editor.
///   - Provides an interface to open a new root folder.
struct SidebarView: View {
    // MARK: - Dependencies
    
    /// The project manager responsible for file system data.
    @Bindable var projectManager: ProjectManager
    
    // MARK: - Bindings
    
    /// The text content of the currently selected file.
    @Binding var selectedFileContent: String
    
    /// The name of the currently selected file.
    @Binding var currentFileName: String?
    
    // MARK: - Local State
    
    /// Controls the presentation of the folder importer.
    @State private var isImporterPresented: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header / Title
            PaneBar {
                Text("Explorer")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                
                ControlGroup {
                    Button(action: { isImporterPresented = true }) {
                        Label("Open", systemImage: "folder.badge.plus")
                    }
                }
                .controlSize(.large)
            }
            
            if let _ = projectManager.rootURL {
                List(projectManager.items, children: \.children) { item in
                    HStack {
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
                        
                        Text(item.name)
                            .foregroundColor(currentFileName == item.name ? .primary : .primary)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .background(
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
    
    private func openFile(_ item: FileSystemItem) {
        if let content = projectManager.readFile(item.url) {
            self.selectedFileContent = content
            self.currentFileName = item.name
        }
    }
}
