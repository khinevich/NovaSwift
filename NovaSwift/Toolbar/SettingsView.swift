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
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $currentTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden() // Since we are in a Form section, the header explains it
            }
            
            Section("Editor Text Size") {
                HStack {
                    Text("\(Int(fontSize)) pt")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .leading)
                    
                    Spacer()
                    
                    Button(action: {
                        if fontSize > 8 { fontSize -= 1 }
                    }) {
                        Image(systemName: "minus")
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.borderless)
                    .keyboardShortcut("-", modifiers: .command)
                    
                    Button(action: {
                        if fontSize < 48 { fontSize += 1 }
                    }) {
                        Image(systemName: "plus")
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.borderless)
                    .keyboardShortcut("+", modifiers: .command)
                }
            }
        }
        .padding(20)
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
