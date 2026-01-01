//
//  InfoView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 31.12.25.
//

import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .padding(.top, 20)
            } else {
                Image(systemName: "swift")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.orange)
                    .padding(.top, 20)
            }
            
            VStack(spacing: 8) {
                Text("NovaSwift")
                    .font(.system(size: 40, weight: .bold)) // ~1.5x Title
                
                Text("Version 1.0.0")
                    .font(.system(size: 24)) // ~1.5x Body
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 12) {
                Text("A lightweight Swift script runner and editor for macOS.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 24)) // ~1.5x Body
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("Created by Mikhail Khinevich")
                    .font(.system(size: 18)) // ~1.5x Footnote
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 16) {
                    Link("LinkedIn", destination: URL(string: "https://www.linkedin.com/in/mikhail-khinevich-a56399219/")!)
                    Link("GitHub", destination: URL(string: "https://github.com/khinevich")!)
                }
                .font(.system(size: 18)) // ~1.5x Footnote
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

#Preview {
    InfoView()
}
