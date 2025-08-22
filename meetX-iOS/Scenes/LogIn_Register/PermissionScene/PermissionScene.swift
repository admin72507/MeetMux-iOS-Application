//
//  PermissionScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 15-02-2025.
//

import SwiftUI
import CoreLocation
import UserNotifications

struct PermissionView: View {
    @StateObject private var viewModel = PermissionViewModel()

    var body: some View {
        VStack {
            HStack {
                Spacer()

                Button(action: {
                    viewModel.routeManager.navigate(to: LoginRegister())
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ThemeManager.foregroundColor)
                        .padding()
                        .padding(.leading, 16)
                }
                .hidden()
            }
            Spacer()

            permissionIcon
            permissionTitle
            permissionSubtitle

            // Add detailed explanation section
            explanationSection

            Spacer()

            actionButtons

            NeedHelpView {
                viewModel.isNeedHelpTapped = true
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $viewModel.isNeedHelpTapped) {
            NeedSupportScene(retrivedMobileNumber: "")
                .presentationDragIndicator(.visible)
        }
        .onChange(of: viewModel.shouldNavigateToHome) { _, shouldNavigate in
            if shouldNavigate {
                navigateToHome()
            }
        }
        .onChange(of: viewModel.shouldOpenSettings) { _, shouldOpen in
            if shouldOpen {
                openSettings()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.handleAppReturnFromSettings()
        }
    }
}

// MARK: - View Components
private extension PermissionView {
    var permissionIcon: some View {
        Image(systemName: viewModel.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 150, height: 150)
            .padding()
            .foregroundStyle(ThemeManager.gradientNewPinkBackground)
    }

    var permissionTitle: some View {
        Text(viewModel.titleText)
            .fontStyle(size: 18, weight: .bold)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.top)
    }

    var permissionSubtitle: some View {
        Text(viewModel.subTitleText)
            .fontStyle(size: 14, weight: .medium)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.top, 8)
    }

    // NEW: Detailed explanation section
    var explanationSection: some View {
        VStack(spacing: 12) {
            if !viewModel.detailedExplanation.isEmpty {
                Text(viewModel.detailedExplanation)
                    .fontStyle(size: 13, weight: .regular)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            if !viewModel.privacyNote.isEmpty {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))

                    Text(viewModel.privacyNote)
                        .fontStyle(size: 12, weight: .regular)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 16)
    }

    var actionButtons: some View {
     //   VStack(spacing: 10) {
            mainActionButton
          //  goToHomeButton
        //}
      //  .padding(.horizontal, 20)
    }

    var mainActionButton: some View {
        Button(action: {
            viewModel.handlePermission()
        }) {
            Text(viewModel.buttonText)
                .applyCustomButtonStyle()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .cornerRadius(12)
        }
    }

    var goToHomeButton: some View {
        Button(action: {
            navigateToHome()
        }) {
            HStack {
                Text("Go Home")
                    .fontStyle(size: 14, weight: .medium)
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                Image(systemName: "arrow.right")
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                    .font(.system(size: 16))
            }
            .frame(maxHeight: 44)
            .padding(.horizontal, 12)
        }
    }
}

// MARK: - Navigation Helpers
private extension PermissionView {
    func navigateToHome() {
        viewModel.routeManager.navigate(to: HomePageRoute())
    }

    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}
