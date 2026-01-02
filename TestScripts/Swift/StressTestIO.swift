#!/usr/bin/env swift

import Foundation

print("--- Starting IO Stress Test ---")

let fileManager = FileManager.default
let tempDir = fileManager.temporaryDirectory
let stressDir = tempDir.appendingPathComponent("NovaSwift_StressTest")
let fileCount = 100

// Setup
do {
    if fileManager.fileExists(atPath: stressDir.path) {
        try fileManager.removeItem(at: stressDir)
    }
    try fileManager.createDirectory(at: stressDir, withIntermediateDirectories: true)
} catch {
    print("Failed to setup stress directory: \(error)")
    exit(1)
}

print("Preparing to create \(fileCount) files in \(stressDir.lastPathComponent)...")

let startTime = Date()

// Create Files
for i in 1...fileCount {
    let fileURL = stressDir.appendingPathComponent("file_\(i).txt")
    let content = "Data for file \(i) at \(Date())"
    do {
        try content.write(to: fileURL, atomically: false, encoding: .utf8)
    } catch {
        print("Error writing file \(i): \(error)")
    }
    
    if i % 20 == 0 {
        print(" -> Created \(i) files...")
    }
}

let creationTime = Date().timeIntervalSince(startTime)
print("✅ Created \(fileCount) files in \(String(format: "%.3f", creationTime)) seconds.")

// Verify Files (Simulate Read)
print("Verifying files...")
var readSuccessCount = 0
for i in 1...fileCount {
    let fileURL = stressDir.appendingPathComponent("file_\(i).txt")
    if fileManager.fileExists(atPath: fileURL.path) {
        readSuccessCount += 1
    }
}
print("✅ Verified \(readSuccessCount)/\(fileCount) files exist.")

// Cleanup
print("Cleaning up...")
let cleanupStart = Date()
do {
    try fileManager.removeItem(at: stressDir)
} catch {
    print("Error deleting directory: \(error)")
}
let cleanupTime = Date().timeIntervalSince(cleanupStart)

print("✅ Cleanup took \(String(format: "%.3f", cleanupTime)) seconds.")
print("--- Finished IO Stress Test ---")
