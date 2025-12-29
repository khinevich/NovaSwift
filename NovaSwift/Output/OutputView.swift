//
//  OutputView.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 29.12.25.
//

import SwiftUI

struct OutputView: View {
    let output: String
        
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(output)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .background(Color.black.opacity(0.03))
    }
}

#Preview {
    OutputView(output: "Preview Output")
}
