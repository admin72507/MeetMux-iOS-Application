//
//  OldLoginDetectionScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 26-04-2025.
//

import SwiftUI
import Kingfisher

struct OldLoginDetectionView: View {
    @StateObject private var viewModel = OldLoginDetectionViewModel()
    @State private var imageLoadFailed = false
    
    var body: some View {
        VStack(spacing: 5) {
            Spacer()
            
            if imageLoadFailed {
                fallbackInitialCircle(for: viewModel.userDisplayName)
            } else {
                KFImage(URL(string: viewModel.userProfilePicture))
                    .placeholder {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                            .frame(width: 250, height: 250)
                    }
                    .onFailure { _ in
                        imageLoadFailed = true
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 250, height: 250)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding(.vertical, 16)
            }
            
            VStack(spacing: 8) {
                Text(Constants.previousLoginDetected + viewModel.userDisplayName)
                    .fontStyle(size: 20, weight: .bold)
                
                Text(Constants.previoudLoginSubtitle)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .fontStyle(size: 15, weight: .regular)
                    .padding(.horizontal)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    viewModel.continuePreviousLogin()
                }) {
                    Text(Constants.primaryButtonText + viewModel.cleanMobileNumberWithCountryCode(viewModel.mobileNumber))
                        .applyCustomButtonStyle()
                }
                .shadow(radius: 2)
                .pressEffect()
                
                Button(action: {
                    viewModel.loginOrSignup()
                }) {
                    Text(Constants.secondaryButtonText)
                        .applyCustomButtonStyle()
                }
                .shadow(radius: 2)
                .pressEffect()
                
                NeedHelpView {
                    viewModel.needHelpTapped = true
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $viewModel.needHelpTapped) {
            NeedSupportScene(retrivedMobileNumber: "")
                .presentationDragIndicator(.visible)
        }
        .environmentObject(viewModel)
    }
    
    // MARK: - Fallback View for Failed Image
    @ViewBuilder
    func fallbackInitialCircle(for name: String) -> some View {
        let firstLetter = String(name.prefix(1)).uppercased()
        
        ZStack {
            Circle()
                .fill(ThemeManager.gradientNewPinkBackground)
            
            Text(firstLetter)
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 250, height: 250)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.vertical, 16)
    }
}
