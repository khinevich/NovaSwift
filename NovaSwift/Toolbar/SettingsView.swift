//
//  SettingsView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 31.12.25.
//

import SwiftUI

import UserNotifications

struct SettingsView: View {
    @AppStorage("appTheme") private var currentTheme: AppTheme = .dark
    @AppStorage("editorFontSize") private var fontSize: Double = 14.0
    @AppStorage("customSwiftPath") private var customSwiftPath: String = ""
    @AppStorage("customKotlinPath") private var customKotlinPath: String = ""
    
    @State private var settingsModel = SettingsModel()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
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
                
                // Notifications
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notifications")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Status")
                                .font(.system(size: 18))
                            Text(settingsModel.statusText)
                                .font(.caption)
                                .foregroundStyle(settingsModel.statusColor)
                        }
                        
                        Spacer()
                        
                        if settingsModel.notificationStatus == .notDetermined {
                            Button("Request Permission") {
                                settingsModel.requestPermission()
                            }
                            .buttonStyle(.borderedProminent)
                        } else if settingsModel.notificationStatus == .denied {
                            Button("Open Settings") {
                                settingsModel.openSystemSettings()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .onAppear {
                    settingsModel.checkNotificationStatus()
                }
                
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
                .padding([.top, .bottom], 16)
                
                Divider()
                
                // Executables Paths
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Executables")
                            .font(.title2.bold())
                            .foregroundStyle(.secondary)
                        
                        Text("Standard locations are used by default. If you want to specify custom paths, enter them below.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Swift Path")
                            .font(.callout)
                            .foregroundStyle(.primary)
                        TextField("/path/to/swift", text: $customSwiftPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("Detected: \(settingsModel.resolvePath(for: "swift"))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kotlin Path")
                            .font(.callout)
                            .foregroundStyle(.primary)
                        TextField("/path/to/kotlinc", text: $customKotlinPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("Detected: \(settingsModel.resolvePath(for: "kotlinc"))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("To find the correct path, run:")
                        Text("`which swift`")
                        Text("`which kotlinc`")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                }
                .padding([.horizontal, .bottom], 24)
                .padding(.top, 16)
            }
        }
        .frame(width: 350, height: 500)
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
