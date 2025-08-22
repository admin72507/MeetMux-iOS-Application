//
//  SuccessPostScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 30-05-2025.
//

import SwiftUI

struct SuccessPageView: View {
    @State private var animateRings = false
    @State private var animateCheckmark = false
    @State private var animateContent = false
    @Environment(\.colorScheme) var colorScheme
    let okAction: () -> Void
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated Success Icon with Rings
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            Color.purple.opacity(colorScheme == .dark ? 0.4 : 0.2),
                            lineWidth: 3
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(animateRings ? 1.2 : 1.0)
                        .opacity(animateRings ? 0.0 : (colorScheme == .dark ? 0.6 : 0.4))
                        .animation(
                            Animation.easeOut(duration: 2.0)
                                .repeatForever(autoreverses: false),
                            value: animateRings
                        )
                    
                    // Middle ring
                    Circle()
                        .stroke(
                            Color.purple.opacity(colorScheme == .dark ? 0.5 : 0.3),
                            lineWidth: 4
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(animateRings ? 1.1 : 1.0)
                        .opacity(animateRings ? 0.0 : (colorScheme == .dark ? 0.7 : 0.5))
                        .animation(
                            Animation.easeOut(duration: 1.8)
                                .repeatForever(autoreverses: false)
                                .delay(0.2),
                            value: animateRings
                        )
                    
                    // Inner ring
                    Circle()
                        .stroke(
                            Color.purple.opacity(colorScheme == .dark ? 0.6 : 0.4),
                            lineWidth: 5
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateRings ? 1.05 : 1.0)
                        .opacity(animateRings ? 0.0 : (colorScheme == .dark ? 0.8 : 0.6))
                        .animation(
                            Animation.easeOut(duration: 1.6)
                                .repeatForever(autoreverses: false)
                                .delay(0.4),
                            value: animateRings
                        )
                    
                    // Success Circle with Checkmark
                    ZStack {
                        // Circle background
                        Circle()
                            .fill(
                                ThemeManager.gradientNewPinkBackground
                            )
                            .frame(width: 80, height: 80)
                            .scaleEffect(animateCheckmark ? 1.0 : 0.0)
                            .animation(
                                Animation.spring(response: 0.6, dampingFraction: 0.6)
                                    .delay(0.3),
                                value: animateCheckmark
                            )
                        
                        // Checkmark
                        Image(systemName: "checkmark")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(animateCheckmark ? 1.0 : 0.0)
                            .animation(
                                Animation.spring(response: 0.6, dampingFraction: 0.6)
                                    .delay(0.5),
                                value: animateCheckmark
                            )
                    }
                }
                
                // Success Content
                VStack(alignment: .center, spacing: 16) {
                    Text("Your post has been shared with your followers and connections")
                        .fontStyle(size: 32, weight: .semibold)
                        .foregroundColor(ThemeManager.foregroundColor)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(
                            Animation.easeOut(duration: 0.8)
                                .delay(0.8),
                            value: animateContent
                        )
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Text("Whenever you’re ready, please create a new post....")
                        .fontStyle(size: 18, weight: .light)
                        .foregroundColor(.gray)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(
                            Animation.easeOut(duration: 0.8)
                                .delay(1.0),
                            value: animateContent
                        )
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // OK Button
                Button(action: {
                    // Handle OK button tap
                    okAction()
                }) {
                    Text("Ok")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            ThemeManager.gradientNewPinkBackground
                        )
                        .cornerRadius(28)
                        .padding(.horizontal, 32)
                }
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(
                    Animation.easeOut(duration: 0.8)
                        .delay(1.2),
                    value: animateContent
                )
                .padding(.horizontal, 16)
                
                Spacer().frame(height: 45)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Start ring animations immediately
        animateRings = true
        
        // Start checkmark animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            animateCheckmark = true
        }
        
        // Start content animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            animateContent = true
        }
    }
}

// MARK: - Preview
struct SuccessPageView_Previews: PreviewProvider {
    static var previews: some View {
        SuccessPageView( okAction: {
            
        })
    }
}

// MARK: - Usage Example
struct ContentView: View {
    @State private var showSuccessPage = false
    
    var body: some View {
        NavigationView {
            VStack {
                Button("Show Success Page") {
                    showSuccessPage = true
                }
                .padding()
            }
            .fullScreenCover(isPresented: $showSuccessPage) {
                SuccessPageView( okAction: {
                    
                })
            }
        }
    }
}
