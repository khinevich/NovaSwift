//
//  InfoViewModifier.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 03.01.26.
//

import Foundation
import SwiftUI

/// A view modifier that applies a specific style to the info view icon.
struct InfoViewModifier: ViewModifier {
    /// The size of the icon (width and height). Defaults to 80.
    var size: CGFloat = 80
    
    /// Applies the modifier to the content.
    ///
    /// - Parameter content: The content to modify.
    /// - Returns: The modified view with aspect ratio, frame, foreground style, and padding applied.
    func body(content: Content) -> some View {
        content
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .foregroundStyle(.orange)
            .padding(.top, 20)
    }
}
