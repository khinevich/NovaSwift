//
//  StatusBarView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 29.12.25.
//

import SwiftUI

/// A view displaying the current status of the application, including execution state and exit codes.
///
/// The status bar shows "Ready" when idle, "Running..." with a progress indicator during execution,
/// and the final exit code after a script terminates.
struct StatusBarView: View {
    // MARK: - Properties
    
    /// A boolean indicating whether a script is currently executing.
    let isRunning: Bool
    
    /// A boolean indicating if the script is waiting for user input.
    let isWaitingForInput: Bool
    
    /// The exit code of the last executed script. `nil` if no script has run yet or the status is cleared.
    let exitCode: Int?
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            // Running Indication
            if isRunning {
                ProgressView()
                    .controlSize(.regular)
                
                if isWaitingForInput {
                    Text("Awaiting for user input")
                        .font(.largeTitle)
                        .foregroundColor(.primary)
                } else {
                    Text("Running...")
                        .font(.largeTitle)
                        .foregroundColor(.primary)
                }
            } else {
                Text("Ready")
                    .font(.largeTitle)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            if let code = exitCode {
                HStack(spacing: 4) {
                    Image(systemName: code == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    Text("Exit Code: \(code)")
                }
                .font(.largeTitle)
                .foregroundColor(code == 0 ? .green : .red)
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 42)
        .background(.ultraThinMaterial)
    }
}
#Preview("Ready") {
    StatusBarView(isRunning: false, isWaitingForInput: false, exitCode: 0)
}
#Preview("Running") {
    StatusBarView(isRunning: true, isWaitingForInput: false, exitCode: 1)
}
#Preview("Waiting") {
    StatusBarView(isRunning: true, isWaitingForInput: true, exitCode: nil)
}
