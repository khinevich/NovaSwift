//
//  SidebarViewModelTests.swift
//  NovaSwiftTests
//
//  Created by Gemini on 02.01.26.
//

import Testing
import SwiftUI
import Combine
@testable import NovaSwift

/// A test suite for the `SidebarViewModel`.
///
/// This suite verifies the business logic of the sidebar, including file creation, renaming, and deletion.
/// It ensures that the view model correctly interacts with the `ProjectManager` and updates its state.
@Suite("SidebarViewModel Tests")
struct SidebarViewModelTests {
    
    /// Verifies that creating a new file correctly updates the state and creates the file on disk.
    @Test("Create New File")
    func testCreateNewFile() async throws {
        // Setup
        let projectManager = await ProjectManager()
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appending(path: UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer { try? fileManager.removeItem(at: tempDir) }
        
        await projectManager.openFolder(tempDir)
        let viewModel = await SidebarModel(projectManager: projectManager)
        
        // Action
        await viewModel.createNewFile()
        
        // Assertions - Run on MainActor to access observable properties safely
        await MainActor.run {
            let items = projectManager.items
            
            // 1. File should be created
            #expect(items.count == 1, "A new file should be added to the items list.")
            let newItem = items.first
            #expect(newItem?.name == "Untitled", "The default name should be 'Untitled'.")
            
            // 2. Renaming state should be active
            let renamingId = viewModel.renamingItemId
            let editingName = viewModel.editingName
            
            #expect(renamingId != nil, "Renaming mode should be active after creation.")
            #expect(renamingId == newItem?.id, "The renaming ID should match the new item's ID.")
            #expect(editingName == "Untitled", "The editing name buffer should be initialized.")
        }
    }
    
    /// Verifies that creating a second file handles naming conflicts correctly.
    @Test("Create New File Collision")
    func testCreateNewFileCollision() async throws {
        let projectManager = await ProjectManager()
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appending(path: UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }
        
        await projectManager.openFolder(tempDir)
        let viewModel = await SidebarModel(projectManager: projectManager)
        
        // Create first "Untitled"
        await viewModel.createNewFile()
        // Cancel renaming to reset state
        await viewModel.cancelRenaming()
        
        // Create second "Untitled" -> "Untitled 1"
        await viewModel.createNewFile()
        
        await MainActor.run {
            let items = projectManager.items
            #expect(items.count == 2)
            #expect(items.contains(where: { $0.name == "Untitled 1" }), "Should create 'Untitled 1' to avoid collision.")
        }
    }
    
    /// Verifies the full rename workflow.
    @Test("Rename File")
    func testRenameFile() async throws {
        let projectManager = await ProjectManager()
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appending(path: UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }
        
        // Setup existing file
        let fileURL = tempDir.appending(path: "old.txt")
        try "content".write(to: fileURL, atomically: true, encoding: .utf8)
        
        await projectManager.openFolder(tempDir)
        let viewModel = await SidebarModel(projectManager: projectManager)
        
        // Get the item
        let item = await MainActor.run {
            return projectManager.items.first
        }
        
        guard let targetItem = item else {
            #expect(Bool(false), "Setup failed: no item found")
            return
        }
        
        // 1. Start Renaming
        await viewModel.startRenaming(targetItem)
        
        await MainActor.run {
            let renamingId = viewModel.renamingItemId
            let editingName = viewModel.editingName
            
            #expect(renamingId == targetItem.id)
            #expect(editingName == "old.txt")
            
            // 2. Change Name
            viewModel.editingName = "new.txt"
        }
        
        // 3. Complete Rename
        await viewModel.completeRename(item: targetItem)
        
        await MainActor.run {
            let renamingId = viewModel.renamingItemId
            #expect(renamingId == nil, "Renaming state should be cleared.")
            
            // Check ProjectManager state update
            let updatedItems = projectManager.items
            #expect(updatedItems.first?.name == "new.txt")
        }
        
        // Check File System
        let newURL = tempDir.appending(path: "new.txt")
        #expect(fileManager.fileExists(atPath: newURL.path))
        #expect(!fileManager.fileExists(atPath: fileURL.path))
    }
    
    /// Verifies file deletion and editor state clearing.
    @Test("Delete File")
    func testDeleteFile() async throws {
        // Helper class to manage binding state on MainActor
        @MainActor
        class TestState {
            var currentFile: URL?
            var content: String = "content"
        }
        
        let projectManager = await ProjectManager()
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appending(path: UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }
        
        let fileURL = tempDir.appending(path: "todelete.txt")
        try "content".write(to: fileURL, atomically: true, encoding: .utf8)
        
        await projectManager.openFolder(tempDir)
        let viewModel = await SidebarModel(projectManager: projectManager)
        
        // Run interaction on MainActor
        await MainActor.run {
            guard let item = projectManager.items.first else {
                #expect(Bool(false), "Setup failed")
                return
            }
            
            let state = TestState()
            // Use the actual item's URL to ensure exact match with the deletion logic
            state.currentFile = item.url
            
            let currentFileBinding = Binding(
                get: { state.currentFile },
                set: { state.currentFile = $0 }
            )
            let contentBinding = Binding(
                get: { state.content },
                set: { state.content = $0 }
            )
            
            // Action: Delete
            viewModel.deleteItem(item, currentFile: currentFileBinding, contentBinding: contentBinding)
            
            // Assertions
            #expect(!fileManager.fileExists(atPath: item.url.path), "File should be deleted from disk.")
            #expect(projectManager.items.isEmpty, "Item should be removed from the list.")
            
            // Check binding clearing
            #expect(state.currentFile == nil, "Current file selection should be cleared.")
            #expect(state.content == "", "Editor content should be cleared.")
        }
    }
    
    /// Verifies that opening a file correctly updates the bindings.
    @Test("Open File")
    func testOpenFile() async throws {
        @MainActor
        class TestState {
            var currentFile: URL?
            var content: String = ""
        }
        
        let projectManager = await ProjectManager()
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appending(path: UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }
        
        let fileURL = tempDir.appending(path: "test.txt")
        let expectedContent = "Hello World"
        try expectedContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        await projectManager.openFolder(tempDir)
        let viewModel = await SidebarModel(projectManager: projectManager)
        
        await MainActor.run {
            guard let item = projectManager.items.first else {
                #expect(Bool(false), "Setup failed")
                return
            }
            
            let state = TestState()
            let currentFileBinding = Binding(
                get: { state.currentFile },
                set: { state.currentFile = $0 }
            )
            let contentBinding = Binding(
                get: { state.content },
                set: { state.content = $0 }
            )
            
            // Action
            viewModel.openFile(item, currentFile: currentFileBinding, contentBinding: contentBinding)
            
            // Assertions
            #expect(state.currentFile == item.url, "Current file URL should be updated.")
            #expect(state.content == expectedContent, "Editor content should match the file content.")
        }
    }
}
