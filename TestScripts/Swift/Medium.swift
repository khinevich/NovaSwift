#!/usr/bin/env swift

import Foundation

print("--- Starting Medium Script (File & JSON) ---")

struct User: Codable {
    let name: String
    let role: String
}

let tempDir = FileManager.default.temporaryDirectory
let fileURL = tempDir.appendingPathComponent("novaswift_test.txt")

print("1. Writing to temporary file: \(fileURL.path)")
let content = "This is a test file created by NovaSwift script."
do {
    try content.write(to: fileURL, atomically: true, encoding: .utf8)
    print("   Success.")
} catch {
    print("   Error writing file: \(error)")
    exit(1)
}

print("2. Reading file back...")
do {
    let savedContent = try String(contentsOf: fileURL)
    print("   Read content: '\(savedContent)'")
} catch {
    print("   Error reading file: \(error)")
    exit(1)
}

print("3. JSON Encoding/Decoding...")
let user = User(name: "Tester", role: "Developer")
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

if let data = try? encoder.encode(user), let jsonString = String(data: data, encoding: .utf8) {
    print("   Encoded User: \n\(jsonString)")
}

print("--- Finished Medium Script ---")

