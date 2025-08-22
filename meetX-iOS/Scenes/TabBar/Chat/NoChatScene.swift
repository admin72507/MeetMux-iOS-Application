//
//  NoChatView.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 11-07-2025.
//


import SwiftUI
import DotLottie

struct NoChatView: View {
    @EnvironmentObject private var themeManager: AppThemeManager

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Spacer()

                // Lottie Animation
                LottieLoaderLocalFileView(
                    animationName: DeveloperConstants.noChatAnimations
                        .randomElement() ?? "Dancecat"
                )
                .frame(maxWidth: 300, maxHeight: 300) // optional constraint
                .padding(.top, 40)

                // Title
                Text(Constants.noChatMessages)
                    .fontStyle(size: 24, weight: .semibold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ThemeManager.foregroundColor)
                    .padding(.horizontal, 16)
                    .padding(.top, 0)

                // Description
                Text(Constants.noChatMessagesSubText)
                    .fontStyle(size: 18, weight: .light)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ThemeManager.backgroundColor)
        .ignoresSafeArea(.all)
    }
}


// MARK: - Preview
struct NoChatView_Previews: PreviewProvider {
    static var previews: some View {
        NoChatView()
            .environmentObject(AppThemeManager())
    }
}

