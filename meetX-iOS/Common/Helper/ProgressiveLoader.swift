//
//  ProgressiveLoader.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 10-02-2025.
//

import SwiftUI

struct ProgressiveLoader: ViewModifier {
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .opacity(isLoading ? 0.5 : 1.0)
            
            if isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: ThemeManager.staticPurpleColour))
                    .scaleEffect(1.5)
            }
        }
    }
}
