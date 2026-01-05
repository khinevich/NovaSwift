//
//  ProjectManagerTests.swift
//  NovaSwiftTests
//
//  Created by Mikhail Khinevich on 02.01.26.
//

import Testing
import Foundation
@testable import NovaSwift

/// A test suite for the `ProjectManager` service.
///
/// This suite verifies the file system operations performed by the `ProjectManager`, including
/// listing directory contents, sorting files and folders, and reading file content.
/// It uses a temporary directory to simulate a project structure safely.
@Suite("ProjectManager Tests")
struct ProjectManagerTests {
    
    /// Verifies the logic for listing and sorting directory contents.
    ///
    /// **Scenario:**
    /// A temporary folder structure is created with mixed files and subdirectories:
    /// - `B_Folder/` (containing `fileInside.txt`)
    /// - `A_Folder/`
    /// - `file2.txt`
    /// - `file1.txt`
    ///
    /// **Expectation:**
    /// - The `items` array should contain all 4 entries from the root.
    /// - **Sorting:** Directories should appear before files. Within those groups, items should be sorted alphabetically.
    ///   - Order: `A_Folder`, `B_Folder`, `file1.txt`, `file2.txt`.
    /// - **Recursion:** `B_Folder` should correctly list its child `fileInside.txt`.
    @Test("File System Listing and Sorting")
    func testFileListing() async throws {
        let manager = await ProjectManager()
        let fileManager = FileManager.default
        // Create a unique temporary directory for this test run.
        let tempDir = fileManager.temporaryDirectory.appending(path: UUID().uuidString)
        
        // Setup the specific directory structure for testing sorting and hierarchy.
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: tempDir.appending(path: "B_Folder"), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: tempDir.appending(path: "A_Folder"), withIntermediateDirectories: true)
        
        try "content".write(to: tempDir.appending(path: "file2.txt"), atomically: true, encoding: .utf8)
        try "content".write(to: tempDir.appending(path: "file1.txt"), atomically: true, encoding: .utf8)
        try "inner".write(to: tempDir.appending(path: "B_Folder/fileInside.txt"), atomically: true, encoding: .utf8)
        
        // Ensure cleanup happens even if assertions fail.
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        // Action: Open the root folder.
        await manager.openFolder(tempDir)
        
        let items = await manager.items
        
        // Check total count at root.
        #expect(items.count == 4, "Expected 4 items in the root directory.")
        
        // Verify Sorting Order (Directories first, then alphabetical).
        
        // 1. A_Folder (Directory)
        #expect(items[0].name == "A_Folder")
        #expect(items[0].isDirectory == true)
        
        // 2. B_Folder (Directory)
        #expect(items[1].name == "B_Folder")
        #expect(items[1].isDirectory == true)
        
        // 3. file1.txt (File)
        #expect(items[2].name == "file1.txt")
        #expect(items[2].isDirectory == false)
        
        // 4. file2.txt (File)
        #expect(items[3].name == "file2.txt")
        #expect(items[3].isDirectory == false)
        
        // Verify Recursion/Children
        #expect(items[1].children?.count == 1, "B_Folder should contain one child item.")
        await #expect(items[1].children?.first?.name == "fileInside.txt", "The child of B_Folder should be 'fileInside.txt'.")
    }
    
    /// Verifies that the `ProjectManager` can correctly read the contents of a file.
    ///
    /// **Scenario:**
    /// A file named `test.txt` is created with known content ("Hello NovaSwift").
    ///
    /// **Expectation:**
    /// - `readFile(_:)` returns the exact string content of the file.
    @Test("File Reading")
    func testFileReading() async throws {
        let manager = await ProjectManager()
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appending(path: UUID().uuidString)
        
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileUrl = tempDir.appending(path: "test.txt")
        let content = "Hello NovaSwift"
        try content.write(to: fileUrl, atomically: true, encoding: .utf8)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        let readContent = await manager.readFile(fileUrl)
        #expect(readContent == content, "The read content should match the file content exactly.")
    }
}
