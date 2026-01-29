//
//  SidebarViewModel.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 02.01.26.
//

import SwiftUI
import Combine

/// A view model that manages the state and business logic for the SidebarView.
///
/// This class handles:
/// - Interaction with the `ProjectManager` for file system operations.
/// - Management of file renaming state (which item is being renamed and the temporary name).
/// - Logic for creating new files and handling deletions.
/// - Every property in this class runs on the Main Thread, since those states directly updating the UI
@MainActor
@Observable
class SidebarModel {
    // MARK: - Dependencies
    
    /// The project manager responsible for file system data.
    var projectManager: ProjectManager
    
    // MARK: - UI State
    
    /// The ID of the item currently being renamed. `nil` if no item is being renamed.
    var renamingItemId: UUID?
    
    /// The temporary name buffer for the item being edited.
    var editingName: String = ""
    
    /// Controls the presentation of the folder importer sheet.
    var isImporterPresented: Bool = false
    
    // MARK: - Initialization
    
    /// Initializes the view model with a project manager.
    /// - Parameter projectManager: The data source for the project's file structure.
    init(projectManager: ProjectManager) {
        self.projectManager = projectManager
    }
    
    // MARK: - File Operations
    
    /// Opens a folder at the specified URL.
    /// - Parameter url: The URL of the folder to open.
    func openFolder(_ url: URL) {
        projectManager.openFolder(url)
    }
    
    /// Creates a new "Untitled" file in the project's root directory and initiates the rename flow.
    ///
    /// This method ensures a unique name is generated (e.g., "Untitled 2") if a conflict exists.
    func createNewFile() {
        guard let root = projectManager.rootURL else { return }
        
        let baseName = "Untitled"
        var name = baseName
        var counter = 1
        
        // Find a unique name
        while FileManager.default.fileExists(atPath: root.appendingPathComponent(name).path) {
            name = "\(baseName) \(counter)"
            counter += 1
        }
        
        // Create the placeholder file
        let newFileURL = projectManager.createFile(at: root, name: name)
        
        // Find the new item in the list to start renaming.
        // compare standardized paths to ensure robustness against symlinks or path representation differences.
        if let newItem = projectManager.items.first(where: { $0.url.standardizedFileURL.path == newFileURL.standardizedFileURL.path }) {
            startRenaming(newItem)
        }
    }
    
    /// Deletes the specified file item.
    ///
    /// - Parameters:
    ///   - item: The item to delete.
    ///   - currentFile: The binding to the currently open file URL, effectively allowing the VM to clear selection if the open file is deleted.
    ///   - contentBinding: The binding to the editor content, to clear it if the open file is deleted.
    func deleteItem(_ item: FileSystemItem, currentFile: Binding<URL?>, contentBinding: Binding<String>) {
        projectManager.deleteFile(at: item.url)
        
        // If the deleted file was the one currently open, clear the editor state.
        // use standardized URLs to ensure reliable comparison.
        if let openURL = currentFile.wrappedValue, openURL.standardizedFileURL.path == item.url.standardizedFileURL.path {
            currentFile.wrappedValue = nil
            contentBinding.wrappedValue = ""
        }
    }
    
    /// Opens a file and updates the editor state via the bindings.
    ///
    /// - Parameters:
    ///   - item: The item representing the file to open.
    ///   - currentFile: Binding to the currently selected file URL.
    ///   - contentBinding: Binding to the text content of the editor.
    func openFile(_ item: FileSystemItem, currentFile: Binding<URL?>, contentBinding: Binding<String>) {
        if let content = projectManager.readFile(item.url) {
            contentBinding.wrappedValue = content
            currentFile.wrappedValue = item.url
        }
    }
    
    // MARK: - Renaming Logic
    
    /// Sets the state to begin renaming an item.
    /// - Parameter item: The item to rename.
    func startRenaming(_ item: FileSystemItem) {
        self.renamingItemId = item.id
        self.editingName = item.name
    }
    
    /// Commits the rename operation for the specified item using the `editingName`.
    /// - Parameter item: The item being renamed.
    func completeRename(item: FileSystemItem) {
        projectManager.renameFile(at: item.url, to: editingName)
        cancelRenaming()
    }
    
    /// Cancels the renaming operation and resets the state.
    func cancelRenaming() {
        renamingItemId = nil
        editingName = ""
    }
}
