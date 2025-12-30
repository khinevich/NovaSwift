#!/usr/bin/env swift

import Foundation

// URL of the image to download (Swift Logo)
let imageUrlString = "https://developer.apple.com/assets/elements/icons/swift/swift-96x96.png"

print("---" + " Starting File Download Demo" + "---")
print("Target URL: " + imageUrlString)

guard let url = URL(string: imageUrlString) else {
    print("❌ Invalid URL.")
    exit(1)
}

let semaphore = DispatchSemaphore(value: 0)

print("Starting download...")

let task = URLSession.shared.dataTask(with: url) { data, response, error in
    defer { semaphore.signal() }
    
    if let error = error {
        print("❌ Download failed with error: " + error.localizedDescription)
        return
    }
    
    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        print("❌ Server returned an error code.")
        return
    }
    
    guard let data = data else {
        print("❌ No data received.")
        return
    }
    
    print("✅ Download complete. Data size: " + String(data.count) + " bytes.")
    
    // Determine save path (User's Downloads Directory)
    let fileManager = FileManager.default
    guard let downloadsDir = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
        print("❌ Could not find Downloads directory.")
        return
    }
    
    let fileName = "DownloadedSwiftLogo.png"
    let destinationURL = downloadsDir.appendingPathComponent(fileName)
    
    do {
        try data.write(to: destinationURL)
        print("\n🎉 Success! Image saved to:")
        print("   👉 " + destinationURL.path)
        print("\n(Check your Finder/Downloads folder for 'DownloadedSwiftLogo.png')")
    } catch {
        print("❌ Failed to save file: " + error.localizedDescription)
    }
}

task.resume()

// Wait for the async task to complete
print("Waiting for network request...")
semaphore.wait()

print("--- End of Script ---")
