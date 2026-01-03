//
//  InfoViewModifier.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 03.01.26.
//

import Foundation
import SwiftUI

struct InfoViewModifier: ViewModifier {
    var size: CGFloat = 80
    
    func body(content: Content) -> some View {
        content
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .foregroundStyle(.orange)
            .padding(.top, 20)
    }
}
