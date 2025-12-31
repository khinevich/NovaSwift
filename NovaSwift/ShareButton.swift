//
//  ShareButton.swift
//  NovaSwift
//
//  Created by NovaSwift AI on 30.12.25.
//

import SwiftUI
import AppKit

struct ShareButton: NSViewRepresentable {
    let title: String
    let systemImage: String
    let content: String // The text to share
    let isEnabled: Bool
    
    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(title: "", target: context.coordinator, action: #selector(Coordinator.share(_:)))
        button.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: title)
        button.bezelStyle = .texturedRounded // Better for toolbar-like contexts
        button.imagePosition = .imageOnly
        button.isBordered = false // Mimic .borderless behavior
        return button
    }
    
    func updateNSView(_ nsView: NSButton, context: Context) {
        nsView.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: title)
        nsView.isEnabled = isEnabled
        context.coordinator.content = content
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, NSSharingServicePickerDelegate {
        var content: String = ""
        
        @objc func share(_ sender: NSButton) {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("Output.txt")
            
            do {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Error writing temp file: \(error)")
                return
            }
            
            let picker = NSSharingServicePicker(items: [fileURL])
            picker.delegate = self
            // Anchor strictly to the button's bounds
            picker.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }
}
