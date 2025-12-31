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
        ConsoleTextView(text: output)
    }
}

#Preview {
    OutputView(output: "Preview Output")
}
