//
//  ReachabilityScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 08-07-2025.
//

import SwiftUI
import DotLottie

struct ReachabilityScene: View {
    @EnvironmentObject private var networkViewModel: NetworkViewModel
    @EnvironmentObject private var themeManager: AppThemeManager
    @State private var isRetrying = false
    @State private var animateIcon = false

    let lottieFiles = DeveloperConstants.noNetworkArray
        .randomElement() ?? "person"

    var body: some View {
        ZStack {

            VStack(spacing: 24) {
                Spacer()
                // Lottie Animation
                LottieLoaderLocalFileView(
                    animationName: lottieFiles
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 40)

                // Title
                Text(DeveloperConstants.noInternetTitle.randomElement() ?? "")
                    .fontStyle(size: 24, weight: .semibold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ThemeManager.foregroundColor)
                    .padding(.horizontal,16)

                // Description
                Text(DeveloperConstants.noInternetDescriptions.randomElement() ?? "")
                    .fontStyle(size: 18, weight: .light)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal,16)

                Spacer()
                // Retry Button
                Button(action: {
                    retryConnection()
                }) {
                    HStack {
                        if isRetrying {
                            ProgressView()
                                .progressViewStyle(
                                    CircularProgressViewStyle(
                                        tint: ThemeManager
                                            .foregroundColor)
                                )
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                        }

                        Text(isRetrying ? "Checking..." : "Retry")
                            .fontStyle(size: 14, weight: .light)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                    }
                    .applyCustomButtonStyle()
                    .padding(.bottom)
                }
                .disabled(isRetrying)
                .opacity(isRetrying ? 0.6 : 1.0)
            }
        }
        .background(ThemeManager.backgroundColor)
        .ignoresSafeArea(.all)
    }

    private func retryConnection() {
        isRetrying = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRetrying = false
            // Network monitor handles reconnection
        }
    }
}

// MARK: - Preview
struct NoInternetView_Previews: PreviewProvider {
    static var previews: some View {
        ReachabilityScene()
            .environmentObject(NetworkViewModel())
            .environmentObject(AppThemeManager())
    }
}
