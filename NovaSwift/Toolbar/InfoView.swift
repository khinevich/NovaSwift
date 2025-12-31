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
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 12) {
                Text("A lightweight Swift script runner and editor for macOS.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("Created by Mikhail Khinevich")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 16) {
                    Link("LinkedIn", destination: URL(string: "https://www.linkedin.com/in/mikhail-khinevich-a56399219/")!)
                    Link("GitHub", destination: URL(string: "https://github.com/khinevich")!)
                }
                .font(.footnote)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .padding(.bottom, 20)
        }
        .frame(width: 350, height: 400)
    }
}

#Preview {
    InfoView()
}
