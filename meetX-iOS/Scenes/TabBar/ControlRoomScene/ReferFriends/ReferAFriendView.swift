//
//  InviteAFriendScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 15-05-2025.
//

import SwiftUI
import Combine

struct ReferAFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel = ControlRoomObservable()

    private let rows = 6

    var body: some View {
        VStack(alignment: .center) {

            Spacer()

            VStack(spacing: 15) {
                ForEach(0..<rows, id: \.self) { row in
                    ScrollingRowView(
                        imageNames: DeveloperConstants.imageNames,
                        rowIndex: row,
                        direction: row % 2 == 0 ? .left : .right
                    )
                }
            }
            .padding(.vertical, 30)

            Spacer()

            Text("We request access to your contacts to help you easily invite friends and connect with others on the app. Your privacy is important to us, and we only use this information for this purpose. You can manage your permissions at any time in your device settings.")
                .fontStyle(size: 14, weight: .light)
                .foregroundColor(.gray)
                .lineLimit(5)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .padding()

            Button(action: {
                let isDenied = viewModel.permissionHelper.isContactsDenied
                viewModel.referAFriendActionTriggerToSettings = isDenied

                if !isDenied {
                    viewModel.permissionHelper.requestContactPermission { granted in
                        DispatchQueue.main.async {
                            if granted {
                                viewModel.moveUserToContactList = true
                            }
                        }
                    }
                }
            }) {
                Text(viewModel.permissionHelper.isContactsDenied ? Constants.openSettingsText : Constants.allowContacts)
            }
            .applyCustomButtonStyle()
            .padding(.bottom, 40)
        }
        .onAppear() {
            // Check permission status when view appears
            checkPermissionAndNavigate()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Check permission status when app becomes active (user returns from Settings)
            checkPermissionAndNavigate()
        }
        .onChange(of: viewModel.referAFriendActionTriggerToSettings) { _, newValue in
            if newValue {
                DispatchQueue.main.async {
                    if let appSettingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(appSettingsUrl, options: [:], completionHandler: nil)
                    }
                    // Reset the trigger after opening settings
                    viewModel.referAFriendActionTriggerToSettings = false
                }
            }
        }
        .sheet(isPresented: $viewModel.moveUserToContactList) {
            ReferFriendView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .generalNavBarInControlRoom(
            title: "Refer a Friend",
            subtitle: "Invite friends and unlock the fun!",
            image: "person.line.dotted.person.fill",
            onBacktapped: {
                dismiss()
            })
        .background(Color(.systemBackground))
        .ignoresSafeArea(edges: .bottom)
    }

    private func checkPermissionAndNavigate() {
        if viewModel.permissionHelper.isContactAuthorized {
            viewModel.moveUserToContactList = true
        }
    }
}

enum ScrollDirection {
    case left, right
}

struct ScrollingRowView: View {
    let imageNames: [String]
    let rowIndex: Int
    let direction: ScrollDirection

    @State private var offsetX: CGFloat = 0
    @State private var timer: Timer?

    let iconWidth: CGFloat = 50
    let spacing: CGFloat = 20

    var body: some View {
        GeometryReader { geometry in
            let visibleWidth = geometry.size.width
            let content = imageNames + imageNames // Double for smooth loop
            let totalContentWidth = CGFloat(content.count) * (iconWidth + spacing)

            HStack(spacing: spacing) {
                ForEach(0..<content.count, id: \.self) { i in
                    let symbolIndex = (i + rowIndex * 3) % imageNames.count
                    Image(systemName: content[symbolIndex])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconWidth, height: iconWidth)
                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                }
            }
            .frame(width: totalContentWidth, alignment: .leading)
            .offset(x: offsetX)
            .onAppear {
                startAnimation(contentWidth: totalContentWidth, containerWidth: visibleWidth)
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
        .frame(height: 60)
        .clipped()
    }

    private func startAnimation(contentWidth: CGFloat, containerWidth: CGFloat) {
        let scrollDistance = contentWidth / 2
        let step: CGFloat = direction == .left ? -1 : 1
        let resetPoint: CGFloat = direction == .left ? -scrollDistance : 0
        let startPoint: CGFloat = direction == .left ? 0 : -scrollDistance
        let speed: TimeInterval = 0.01

        offsetX = startPoint

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { _ in
            DispatchQueue.main.async {
                offsetX += step
                if direction == .left, offsetX <= resetPoint {
                    offsetX = 0
                } else if direction == .right, offsetX >= 0 {
                    offsetX = -scrollDistance
                }
            }
        }
    }
}
