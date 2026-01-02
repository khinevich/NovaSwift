//
//  ProjectManager.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 31.12.25.
//

import Foundation
import SwiftUI

struct FileSystemItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    var children: [FileSystemItem]?
}

/// A service class responsible for managing file system interactions.
///
/// `ProjectManager` handles the loading of directory contents, reading files, and managing
/// the security-scoped resources required for accessing user-selected folders.
@Observable
class ProjectManager {
    /// The root URL of the currently opened folder.
    var rootURL: URL?
    
    /// The list of file system items (files and directories) in the root folder.
    var items: [FileSystemItem] = []
    
    /// Opens a folder and loads its contents.
    ///
    /// This method handles security-scoped resource access for the folder.
    ///
    /// - Parameter url: The URL of the folder to open.
    func openFolder(_ url: URL) {
        // Access security scoped resource if needed (for sandboxed apps)
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                // We don't stop accessing immediately if we want to read files later, 
                // but for listing we might need to keep it open or manage permissions carefully.
                // In a real app, we'd manage scope lifecycle more robustly.
                // For this listing implementation, we'll stop accessing after listing 
                // and re-access when reading a specific file.
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        self.rootURL = url
        self.items = loadContents(of: url)
    }
    
    private func loadContents(of url: URL) -> [FileSystemItem] {
        let fileManager = FileManager.default
        
        // Options: skip hidden files
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: options)
            
            var loadedItems: [FileSystemItem] = []
            
            for fileURL in contents {
                let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey])
                let isDirectory = resourceValues?.isDirectory ?? false
                
                var children: [FileSystemItem]? = nil
                if isDirectory {
                    children = loadContents(of: fileURL)
                }
                
                loadedItems.append(FileSystemItem(
                    name: fileURL.lastPathComponent,
                    url: fileURL,
                    isDirectory: isDirectory,
                    children: children
                ))
            }
            
            // Sort: Directories first, then files. Alphabetical within groups.
            return loadedItems.sorted {
                if $0.isDirectory != $1.isDirectory {
                    return $0.isDirectory
                }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            
        } catch {
            print("Error loading contents of \(url): \(error)")
            return []
        }
    }
    
    /// Reads the content of a file, handling security scope.
    func readFile(_ url: URL) -> String? {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("Failed to read file: \(error)")
            return nil
        }
    }
    
    /// Saves content to a file at the specified URL.
    ///
    /// - Parameters:
    ///   - url: The URL of the file to save.
    ///   - content: The string content to write.
    func saveFile(_ url: URL, content: String) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save file to \(url): \(error)")
        }
    }
    
    /// Creates a new file in the specified directory.
    ///
    /// - Parameters:
    ///   - directory: The directory URL where the file should be created.
    ///   - name: The name of the new file (including extension).
    ///   - content: The initial content of the file.
    /// - Returns: The URL of the created file.
    @discardableResult
    func createFile(at directory: URL, name: String, content: String = "") -> URL {
        let fileURL = directory.appendingPathComponent(name)
        saveFile(fileURL, content: content)
        
        // Refresh the file list if the created file is in the currently open folder
        if let root = rootURL, directory == root {
            self.items = loadContents(of: root)
        }
        return fileURL
    }
    
    /// Deletes the file or directory at the specified URL.
    ///
    /// - Parameter url: The URL of the item to delete.
    func deleteFile(at url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        
        do {
            try FileManager.default.removeItem(at: url)
            // Refresh list
            if let root = rootURL {
                self.items = loadContents(of: root)
            }
        } catch {
            print("Failed to delete item at \(url): \(error)")
        }
    }
    
    /// Renames a file or directory.
    ///
    /// - Parameters:
    ///   - url: The current URL of the item.
    ///   - newName: The new name (including extension).
    func renameFile(at url: URL, to newName: String) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        
        let directory = url.deletingLastPathComponent()
        let newURL = directory.appendingPathComponent(newName)
        
        do {
            try FileManager.default.moveItem(at: url, to: newURL)
            // Refresh list
            if let root = rootURL {
                self.items = loadContents(of: root)
            }
        } catch {
            print("Failed to rename item from \(url) to \(newURL): \(error)")
        }
    }
}
