//
//  SidebarView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 31.12.25.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct SidebarView: View {
    @Bindable var projectManager: ProjectManager
    @Binding var selectedFileContent: String
    @Binding var currentFileName: String?
    
    @State private var isImporterPresented: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header / Title
            PaneBar {
                Text("Explorer")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                
                Button(action: { isImporterPresented = true }) {
                    Label("Open", systemImage: "folder.badge.plus")
                }
            }
            
            if let _ = projectManager.rootURL {
                List(projectManager.items, children: \.children) { item in
                    HStack {
                        Image(systemName: item.isDirectory ? "folder.fill" : "doc.text")
                            .foregroundColor(item.isDirectory ? .blue : .secondary)
                        Text(item.name)
                    }
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
