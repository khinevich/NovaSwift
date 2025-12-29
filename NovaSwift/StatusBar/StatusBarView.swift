//
//  StatusBarView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 29.12.25.
//

import SwiftUI

struct StatusBarView: View {
    let isRunning: Bool
    let exitCode: Int?
    
    var body: some View {
        HStack {
            // Running Indication
            if isRunning {
                ProgressView()
                    .controlSize(.small)
                Text("Running...")
                    .font(.caption)
                    .foregroundColor(.primary)
            } else {
                Text("Ready")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            if let code = exitCode {
                HStack(spacing: 4) {
                    Image(systemName: code == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    Text("Exit Code: \(code)")
                }
                .font(.caption)
                .foregroundColor(code == 0 ? .green : .red)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(.ultraThinMaterial)
    }
}
#Preview("Ready") {
    StatusBarView(isRunning: false, exitCode: 1)
}
#Preview("Running") {
    StatusBarView(isRunning: true, exitCode: 1)
}
