//
//  SettingsView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 31.12.25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("appTheme") private var currentTheme: AppTheme = .dark
    @AppStorage("editorFontSize") private var fontSize: Double = 14.0
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Appearance
            VStack(alignment: .leading, spacing: 12) {
                Text("Appearance")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.secondary)
                
                Toggle("Dark Mode", isOn: Binding(
                    get: { currentTheme == .dark },
                    set: { currentTheme = $0 ? .dark : .light }
                ))
                .toggleStyle(.switch)
                .font(.system(size: 18))
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider()
            
            // Editor Text Size
            VStack(alignment: .leading, spacing: 12) {
                Text("Editor Text Size")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text("\(Int(fontSize)) pt")
                        .font(.system(size: 18, design: .monospaced))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    HStack(spacing: 0) {
                        Button(action: {
                            if fontSize > 8 { fontSize -= 1 }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 18))
                                .frame(width: 32, height: 32)
                        }
                        .keyboardShortcut("-", modifiers: .command)
                        
                        Divider()
                            .frame(height: 24)
                        
                        Button(action: {
                            if fontSize < 48 { fontSize += 1 }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18))
                                .frame(width: 32, height: 32)
                        }
                        .keyboardShortcut("+", modifiers: .command)
                    }
                    .buttonStyle(.borderless)
                    .background(.background)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.tertiary, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .frame(width: 240)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
