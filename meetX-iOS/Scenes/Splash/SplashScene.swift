//
//  SplashScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-12-2024.
//
import SwiftUI

struct SplashScene: View {
    @State private var rotation: Double = 0
    @State private var showAlternateImage = false
    let onAnimationCompleted: () -> Void
    
    var body: some View {
        VStack {
            Image(showAlternateImage ? DeveloperConstants.LoginRegister.logoImageFull : DeveloperConstants.LoginRegister.logoOnlyImage)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
                .animation(.easeInOut(duration: 1.5), value: rotation)
        }
        .onAppear {
            // Trigger animation to 360°
            withAnimation {
                rotation = 360
            }
            
            // Change image at halfway (180°)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                showAlternateImage = true
            }
            
            // After full animation, move to next screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                onAnimationCompleted()
            }
        }
    }
}
