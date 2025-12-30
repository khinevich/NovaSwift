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
