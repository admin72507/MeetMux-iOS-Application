//
//  PrivacySettingsScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 18-05-2025.
//

import SwiftUI
import Observation

struct PrivacySettingsScene: View {
    @ObservedObject var viewModel: ControlRoomObservable = .init()
    @State private var saveEnabled = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Preferences")) {

                    Toggle(isOn: Binding<Bool>(
                        get: { viewModel.isProfilePublic },
                        set: { newValue in
                            viewModel.isProfilePublic = newValue
                            viewModel.profileVisibilityToggled(newValue)
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Who can view my profile")
                                .fontStyle(size: 16, weight: .regular)
                            Text("Control whether your profile is visible to everyone or just your connections.")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(viewModel.isProfilePublic ? "Public" : "Private")
                                .fontStyle(size: 14, weight: .light)
                                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        }
                    }
                    .tint(ThemeManager.staticPinkColour)
                }

                // NEW SECTION: Permission Preferences
                Section(header: Text("Permission Preferences")) {

                    // Location Permission Toggle
                    Toggle(isOn: Binding<Bool>(
                        get: { viewModel.locationPermissionGranted },
                        set: { newValue in
                            viewModel.locationPermissionToggled(newValue)
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Location Access")
                                .fontStyle(size: 16, weight: .regular)
                            Text("Allow location access to find events and meetups near you.")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(viewModel.locationPermissionGranted ? "Enabled" : "Disabled")
                                .fontStyle(size: 14, weight: .light)
                                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        }
                    }
                    .tint(ThemeManager.gradientNewPinkBackground)

                    // Notification Permission Toggle
                    Toggle(isOn: Binding<Bool>(
                        get: { viewModel.notificationPermissionGranted },
                        set: { newValue in
                            viewModel.notificationPermissionToggled(newValue)
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Push Notifications")
                                .fontStyle(size: 16, weight: .regular)
                            Text("Receive notifications for messages, friend requests, and updates.")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(viewModel.notificationPermissionGranted ? "Enabled" : "Disabled")
                                .fontStyle(size: 14, weight: .light)
                                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        }
                    }
                    .tint(ThemeManager.gradientNewPinkBackground)

                    // Tracking Permission Toggle
                    Toggle(isOn: Binding<Bool>(
                        get: { viewModel.trackingPermissionGranted },
                        set: { newValue in
                            viewModel.trackingPermissionToggled(newValue)
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Analytics & Tracking")
                                .fontStyle(size: 16, weight: .regular)
                            Text("Help us improve the app with anonymous usage data.")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(viewModel.trackingPermissionGranted ? "Enabled" : "Disabled")
                                .fontStyle(size: 14, weight: .light)
                                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        }
                    }
                    .tint(ThemeManager.gradientNewPinkBackground)
                }

                Section(header: Text("Video Preferences")) {
                    Toggle(isOn: Binding<Bool>(
                        get: { viewModel.isAutoPlayEnabled },
                        set: { newValue in
                            viewModel.isAutoPlayEnabled = newValue
                            viewModel.autoPlayToggled(newValue)
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AutoPlay for videos")
                                .fontStyle(size: 16, weight: .regular)
                            Text("Automatically play videos in your feed when scrolling.")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(viewModel.isAutoPlayEnabled ? "Enabled" : "Disabled")
                                .fontStyle(size: 14, weight: .light)
                                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        }
                    }
                    .tint(ThemeManager.gradientNewPinkBackground)
                }

                Section(header: Text("Chat Preferences")) {
                    Toggle(isOn: Binding<Bool>(
                        get: { viewModel.isChatLastSeenEnabled },
                        set: { newValue in
                            viewModel.isChatLastSeenEnabled = newValue
                            viewModel.chatOthersLastseenToggled(newValue)
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("See others last seen status")
                                .fontStyle(size: 16, weight: .regular)
                            Text("Check the status of other users in your conversations.")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(viewModel.isChatLastSeenEnabled ? "Enabled" : "Disabled")
                                .fontStyle(size: 14, weight: .light)
                                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        }
                    }
                    .tint(ThemeManager.gradientNewPinkBackground)
                }
            }
            .generalNavBarInControlRoomWithSaveAction(
                title: "Privacy Settings",
                subtitle: "Save your preferences",
                image: "lock.circle",
                isSaveEnabled: .constant(false),
                onBacktapped: { dismiss() },
                onSavetapped: {
                    saveEnabled = false
                }
            )
            .onAppear {
                // Initialize permission states when view appears
                viewModel.initializePermissionStates()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh permission states when returning from Settings
                viewModel.refreshPermissionStates()
            }
            .onReceive(viewModel.$hasChanges) { hasChanges in
                saveEnabled = hasChanges
            }
            .toast(isPresenting: $viewModel.showToast) {
                HelperFunctions().apiErrorToastCenter("Privacy Settings", viewModel.errorMessage ?? "Updated Successfully")
            }
            .alert(viewModel.permissionAlertTitle, isPresented: $viewModel.showPermissionAlert) {
                Button("Go to Settings") {
                    viewModel.openAppSettings()
                }
                Button("Cancel", role: .cancel) {
                    // Reset toggle to previous state
                    viewModel.resetToggleStates()
                }
            } message: {
                Text(viewModel.permissionAlertMessage)
            }
        }
    }
}
