//
//  SettingsView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 31.12.25.
//

import SwiftUI

import UserNotifications

/// A view that allows the user to configure application settings such as appearance, notifications, and executable paths.
struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    
    /// The view model managing settings logic.
    @State private var settingsModel = SettingsModel()
    
    /// The environment value for dismissing the current presentation.
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        @Bindable var settings = settings
        
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Appearance")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.secondary)
                    Toggle("Dark Mode", isOn: Binding(
                        get: { settings.theme == .dark },
                        set: { settings.theme = $0 ? .dark : .light }
                    ))
                    .toggleStyle(.switch)
                    .font(.system(size: 18))
                }
                .padding([.horizontal, .top], 24)
                .padding(.bottom, 16)
                
                Divider()
                
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
                .padding([.top, .bottom], 16)
                .onAppear {
                    settingsModel.checkNotificationStatus()
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Editor Text Size")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("\(Int(settings.fontSize)) pt")
                            .font(.system(size: 18, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        HStack(spacing: 0) {
                            Button(action: {
                                if settings.fontSize > 8 { settings.fontSize -= 1 }
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 18))
                                    .frame(width: 32, height: 32)
                            }
                            .keyboardShortcut("-", modifiers: .command)
                            
                            Divider()
                                .frame(height: 24)
                            
                            Button(action: {
                                if settings.fontSize < 48 { settings.fontSize += 1 }
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
                        TextField("/path/to/swift", text: $settings.swiftPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("Detected: \(settingsModel.resolvePath(for: "swift"))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kotlin Path")
                            .font(.callout)
                            .foregroundStyle(.primary)
                        TextField("/path/to/kotlinc", text: $settings.kotlinPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("Detected: \(settingsModel.resolvePath(for: "kotlinc"))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("To find the correct path, run:")
                        Text("`which swift`")
                            .foregroundStyle(.white)
                        Text("`which kotlinc`")
                            .foregroundStyle(.white)
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
        .environment(AppSettings.shared)
}
