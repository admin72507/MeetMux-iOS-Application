//
//  Untitled.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 07-02-2025.
//

import SwiftUI

// Using default font which is SF Pro Text

struct CustomFontModifier: ViewModifier {
    var size: CGFloat
    var weight: Font.Weight
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight, design: .rounded))
            .fontDesign(.default)
    }
}


extension View {
    
    func fontStyle(size: CGFloat, weight: Font.Weight) -> some View {
        self.modifier(CustomFontModifier(size: size, weight: weight))
    }
    
}
