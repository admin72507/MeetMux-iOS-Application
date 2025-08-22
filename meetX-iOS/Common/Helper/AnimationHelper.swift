//
//  AnimationHelper.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 29-12-2024.
//

import Foundation
import SwiftUI

final class AnimationHelper {
    
    static func bounce(repeating: Bool) -> SymbolEffectOptions {
        var options = SymbolEffectOptions.speed(1)
        options = repeating ? options.repeating : options.nonRepeating
        return options
    }
    
    struct PressEffect: ViewModifier {
        @State private var isPressed = false
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                )
        }
    }
}
