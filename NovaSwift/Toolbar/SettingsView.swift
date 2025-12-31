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
            VStack(alignment: .leading, spacing: 8) {
                Text("Appearance")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Toggle("Dark Mode", isOn: Binding(
                    get: { currentTheme == .dark },
                    set: { currentTheme = $0 ? .dark : .light }
                ))
                .toggleStyle(.switch)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            Divider()
            
            // Editor Text Size
            VStack(alignment: .leading, spacing: 8) {
                Text("Editor Text Size")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text("\(Int(fontSize)) pt")
                        .monospacedDigit()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.tertiary)
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    HStack(spacing: 0) {
                        Button(action: {
                            if fontSize > 8 { fontSize -= 1 }
                        }) {
                            Image(systemName: "minus")
                                .frame(width: 24, height: 24)
                        }
                        .keyboardShortcut("-", modifiers: .command)
                        
                        Divider()
                            .frame(height: 20)
                        
                        Button(action: {
                            if fontSize < 48 { fontSize += 1 }
                        }) {
                            Image(systemName: "plus")
                                .frame(width: 24, height: 24)
                        }
                        .keyboardShortcut("+", modifiers: .command)
                    }
                    .buttonStyle(.borderless)
                    .background(.background)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.tertiary, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .frame(width: 300)
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
