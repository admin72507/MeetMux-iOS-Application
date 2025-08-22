//
//  ChatRoomTypingIndicatorScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 12-07-2025.
//

import SwiftUI

struct TypingIndicatorView: View {
    @State private var animationPhase = 0.0
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                typingBubble
                Text("typing...")
                    .fontStyle(size: 14, weight: .regular)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }

            Spacer(minLength: UIScreen.main.bounds.width * 0.25)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
        .animation(.easeInOut(duration: 0.3), value: animationPhase)
    }

    private var typingBubble: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(ThemeManager.gradientNewPinkBackground)
                    .frame(width: 6, height: 6)
                    .scaleEffect(
                        animationPhase == Double(index) ? 1.2 : 0.8
                    )
                    .opacity(
                        animationPhase == Double(index) ? 1.0 : 0.5
                    )
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: animationPhase
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(typingBubbleColor)
                .shadow(
                    color: shadowColor,
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    strokeColor,
                    lineWidth: 0.5
                )
        )
        .onAppear {
            withAnimation {
                animationPhase = 2.0
            }
        }
    }

    private var typingBubbleColor: Color {
        colorScheme == .dark
        ? Color(.systemGray6)
        : .white
    }

    private var strokeColor: Color {
        Color(.systemGray4).opacity(0.3)
    }

    private var shadowColor: Color {
        Color.black.opacity(
            colorScheme == .dark ? 0.3 : 0.15
        )
    }
}

// MARK: - Preview
struct TypingIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            TypingIndicatorView()
                .padding()
        }
        .background(Color(.systemBackground))
    }
}
