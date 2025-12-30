#!/usr/bin/env swift

import Foundation

print("--- Starting File Manager Demo ---")

let fileManager = FileManager.default
let tempDir = fileManager.temporaryDirectory
let workingDir = tempDir.appendingPathComponent("NovaSwift_FileDemo_\(UUID().uuidString)")

print("1. Creating working directory: \(workingDir.path)")

do {
    try fileManager.createDirectory(at: workingDir, withIntermediateDirectories: true, attributes: nil)
    print("   ✅ Directory created.")
} catch {
    print("   ❌ Failed to create directory: \(error)")
    exit(1)
}

// Test 2: Create a file with special characters
let fileName = "test_🚀_data.txt"
let fileURL = workingDir.appendingPathComponent(fileName)
let content = "Hello from NovaSwift! 🌌\nThis file has a unicode name."

print("\n2. Writing to file: \(fileName)")
do {
    try content.write(to: fileURL, atomically: true, encoding: .utf8)
    print("   ✅ File written successfully.")
} catch {
    print("   ❌ Failed to write file: \(error)")
}

// Test 3: Check existence and Attributes
print("\n3. Checking file attributes...")
if fileManager.fileExists(atPath: fileURL.path) {
    do {
        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        let size = attributes[.size] as? Int64 ?? 0
        let creationDate = attributes[.creationDate] as? Date ?? Date()
        print("   ✅ File exists. Size: \(size) bytes. Created: \(creationDate)")
    } catch {
        print("   ❌ Failed to read attributes: \(error)")
    }
} else {
    print("   ❌ File not found!")
}

// Test 4: Rename/Move File
let newFileName = "renamed_data.txt"
let newFileURL = workingDir.appendingPathComponent(newFileName)

print("\n4. Renaming file to: \(newFileName)")
do {
    try fileManager.moveItem(at: fileURL, to: newFileURL)
    print("   ✅ File renamed.")
} catch {
    print("   ❌ Failed to move file: \(error)")
}

// Test 5: List Directory Contents
print("\n5. Listing directory contents:")
do {
    let items = try fileManager.contentsOfDirectory(atPath: workingDir.path)
    for item in items {
        print("   - \(item)")
    }
} catch {
    print("   ❌ Failed to list directory: \(error)")
}

// Test 6: Cleanup
print("\n6. Cleaning up...")
do {
    try fileManager.removeItem(at: workingDir)
    print("   ✅ Working directory deleted.")
} catch {
    print("   ❌ Failed to delete directory: \(error)")
}

print("\n--- Finished File Manager Demo ---")
