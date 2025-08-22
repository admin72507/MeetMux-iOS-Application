//
//  VersionInfoScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 17-05-2025.
//

import SwiftUI

struct VersionInfoScene: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showCopiedMessage = false
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
    
    private var bundleID: String {
        Bundle.main.bundleIdentifier ?? "—"
    }
    
    private var lastUpdated: String {
        "May 23, 2025"
    }
    
    private var locale: String {
        Locale.current.identifier
    }
    
    private var device: String {
        UIDevice.current.model
    }
    
    private var osVersion: String {
        UIDevice.current.systemVersion
    }
    
    private var screenSize: String {
        let bounds = UIScreen.main.bounds
        return "\(Int(bounds.width))×\(Int(bounds.height))"
    }
    
    private var installDate: String {
        if let date = UserDefaults.standard.object(forKey: "installDate") as? Date {
            return formattedDate(date)
        }
        return "—"
    }
    
    private var lastLaunch: String {
        if let date = UserDefaults.standard.object(forKey: "lastLaunchDate") as? Date {
            return formattedDate(date)
        }
        return "—"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // MARK: App Logo
                Image(DeveloperConstants.LoginRegister.logoImageFull)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding()
                
                // MARK: Version Card
                VStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        .symbolEffect(.pulse, value: true)
                    
                    Text("App Version")
                        .fontStyle(size: 18, weight: .semibold)
                    
                    Button(action: {
                        let fullVersion = "v\(appVersion) (\(buildNumber))"
                        UIPasteboard.general.string = fullVersion
                        withAnimation { showCopiedMessage = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showCopiedMessage = false }
                        }
                    }) {
                        Text("v\(appVersion) (\(buildNumber))")
                            .fontStyle(size: 14, weight: .light)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .foregroundStyle(ThemeManager.staticPurpleColour)
                    }
                }
                .padding()
                .cornerRadius(20)
                .shadow(radius: 8)
                
                // MARK: Technical Details
                GroupBox(label: Label("Device & App Info \n", systemImage: "gear")) {
                    versionRow(title: "Bundle ID", value: bundleID)
                    versionRow(title: "Locale", value: locale)
                    versionRow(title: "Device", value: device)
                    versionRow(title: "iOS Version", value: osVersion)
                    versionRow(title: "Screen Size", value: screenSize)
                }
                .padding(.horizontal)
                
                // MARK: Build Details
                GroupBox(label: Label("Build Info \n", systemImage: "hammer.circle")) {
                    versionRow(title: "Build Type", value: isDebug() ? "Debug" : "Release", color: isDebug() ? .orange : .green)
                    versionRow(title: "Last Updated", value: lastUpdated)
                    versionRow(title: "Installed On", value: installDate)
                    versionRow(title: "Last Launched", value: lastLaunch)
                }
                .padding(.horizontal)
            
                Text("Made with ❤️❤️ by MeetMux Development Team")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
            }
            .overlay(
                Group {
                    if showCopiedMessage {
                        Text("Copied to clipboard")
                            .fontStyle(size: 12, weight: .semibold)
                            .padding(6)
                            .background(.ultraThickMaterial)
                            .cornerRadius(8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .offset(y: -40)
                    }
                }
            )
        }
        .onAppear {
            trackInstallAndLaunchDates()
        }
        .generalNavBarInControlRoom(
            title: "Version info",
            subtitle: "Check out version and device detailing",
            image: "info.circle.fill",
            onBacktapped: { dismiss() }
        )
    }
    
    // MARK: - Helper Views & Methods
    
    @ViewBuilder
    private func versionRow(title: String, value: String, color: Color = .primary) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(color)
        }
    }
    
    private func isDebug() -> Bool {
#if DEBUG
        return true
#else
        return false
#endif
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func trackInstallAndLaunchDates() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: DeveloperConstants.UserDefaultsInternal.appInstalledDate) == nil {
            defaults.set(Date(), forKey: DeveloperConstants.UserDefaultsInternal.appInstalledDate)
        }
        defaults.set(Date(), forKey: "lastLaunchDate")
    }
}
