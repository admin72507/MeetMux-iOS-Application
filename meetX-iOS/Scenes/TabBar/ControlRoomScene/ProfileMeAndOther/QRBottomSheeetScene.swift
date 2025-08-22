//
//  QRBottomSheeetScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 14-05-2025.
//

import SwiftUI

struct QRBottomSheetView: View {
    let qrImage: Image
    let shareImage: UIImage?
    let deeplinkURL: String?
    let username: String
    var onClose: () -> Void
    
    @State private var animateGradient = false
    @State private var rotationAngle = Angle(degrees: 0)
    @State private var showShareSheet = false
    @State private var showCopyConfirmation = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    // Light Mode Colors
                    colorScheme == .dark ?
                    Color.blue.opacity(0.6) : ThemeManager.staticPinkColour.opacity(0.4),
                    colorScheme == .dark ?
                    Color.purple.opacity(0.6) : ThemeManager.staticPurpleColour.opacity(0.4),
                    colorScheme == .dark ?
                    Color.green.opacity(0.5) : ThemeManager.staticPinkColour.opacity(0.4),
                    // Add more colors that work well in dark mode
                    colorScheme == .dark ?
                    Color.orange.opacity(0.4) : Color.pink.opacity(0.4),
                    colorScheme == .dark ?
                    Color.cyan.opacity(0.6) : Color(red: 0.95, green: 0.85, blue: 0.88).opacity(0.6),
                    colorScheme == .dark ?
                    Color.indigo.opacity(0.5) : Color.red.opacity(0.3)
                ]),
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .animation(.linear(duration: 8).repeatForever(autoreverses: true), value: animateGradient)
            .onAppear {
                animateGradient = true
            }
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: DeveloperConstants.systemImage.closeXmark)
                            .font(.title)
                            .foregroundColor(ThemeManager.foregroundColor)
                            .padding(16)
                    }
                }
                
                Spacer()
                
                // 📷 QR Card
                VStack(spacing: 2) {
                    qrImage
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .padding(.bottom, 5)
                    
                    Text(username)
                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 1, y: 1)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .font(.custom("Courier New", size: 28))
                        .padding(.bottom, 5)
                }
                .frame(maxWidth: .infinity)
                .background(.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding(.horizontal)
                
                // 🔘 Action Buttons
                VStack(spacing: 14) {
                    // Share
                    Button {
                        showShareSheet = true
                    } label: {
                        Label {
                            Text(Constants.generalShare)
                                .fontStyle(size: 14, weight: .semibold)
                        } icon: {
                            Image(systemName: DeveloperConstants.systemImage.shareIcon)
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                        .applyCustomButtonStyle()
                    }
                    
                    // Copy Link
                    Button {
                        UIPasteboard.general.string = deeplinkURL
                        showCopyConfirmation = true
                    } label: {
                        Label {
                            Text(Constants.copyLink)
                                .fontStyle(size: 14, weight: .semibold)
                        } icon: {
                            Image(systemName: DeveloperConstants.systemImage.copyLink)
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                        .applyCustomButtonStyle()
                    }
                    
                    // Scan QR
                    Button {
                        // Add scan action
                    } label: {
                        Label {
                            Text(Constants.scanQRCode)
                                .fontStyle(size: 14, weight: .semibold)
                        } icon: {
                            Image(systemName: DeveloperConstants.systemImage.qrcodeLinkFinder)
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                        .applyCustomButtonStyle()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [
                    image,
                    Constants.shareYourProfile,
                    deeplinkURL ?? ""
                ])
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .overlay(
            Group {
                if showCopyConfirmation {
                    VStack {
                        Spacer()
                        Text(Constants.LinkCopiedToClipboard)
                            .font(.callout.bold())
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.75))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .padding(.bottom, 50)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        showCopyConfirmation = false
                                    }
                                }
                            }
                    }
                    .padding(.horizontal)
                }
            },
            alignment: .bottom
        )
    }
}
