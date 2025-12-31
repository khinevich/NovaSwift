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
    
    /// The exit code of the last executed script. `nil` if no script has run yet or the status is cleared.
    let exitCode: Int?
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            // Running Indication
            if isRunning {
                ProgressView()
                    .controlSize(.regular)
                Text("Running...")
                    .font(.largeTitle)
                    .foregroundColor(.primary)
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
    StatusBarView(isRunning: false, exitCode: 0)
}
#Preview("Running") {
    StatusBarView(isRunning: true, exitCode: 1)
}
