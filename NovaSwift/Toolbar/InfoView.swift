//
//  InfoView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 31.12.25.
//

import SwiftUI

/// A view that displays information about the application, including version, credits, and links.
struct InfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // constructor from AppKit, retrieves the high-resolution icon
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: appIcon)
                    .resizable()
                    .iconStyle()
            } else {
                Image(systemName: "swift")
                    .resizable()
                    .iconStyle()
            }
            
            VStack(spacing: 8) {
                Text("NovaSwift")
                    .font(.system(size: 40, weight: .bold))
                
                Text("Version 1.2")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 12) {
                Text("A lightweight Swift script runner and editor for macOS.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 24))
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("Created by Mikhail Khinevich")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 16) {
                    Link("LinkedIn", destination: URL(string: "https://www.linkedin.com/in/mikhail-khinevich-a56399219/")!)
                    Link("GitHub", destination: URL(string: "https://github.com/khinevich")!)
                }
                .font(.system(size: 18))
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button("Close") {
                dismiss()
            }
            .font(.title3)
            .keyboardShortcut(.defaultAction)
            .padding(.bottom, 20)
        }
        .frame(width: 450, height: 500)
    }
}

extension Image {
    /// Applies a standard icon style to the image.
    ///
    /// - Parameter size: The width and height of the icon. Defaults to 80.
    /// - Returns: A view modified with the icon style.
    func iconStyle(size: CGFloat = 80) -> some View {
        self.modifier(InfoViewModifier(size: size))
    }
}
#Preview {
    InfoView()
}
