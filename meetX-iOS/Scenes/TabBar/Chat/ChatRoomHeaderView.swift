//
//  ChatRoomHeaderView.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 10-07-2025.
//
import SwiftUI
import Kingfisher

struct ChatRoomHeaderView: View {
    let name: String
    let username: String
    let profilePicUrl: String?
    let onBack: () -> Void
    let lastSeenText: String

    @State private var imageLoadFailed = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { onBack() }) {
                Image(systemName: DeveloperConstants.systemImage.backButtonImage)
                    .font(.title2)
                    .foregroundColor(.primary)
            }

            if imageLoadFailed {
                fallbackInitialCircle(for: name)
            } else {
                KFImage(URL(string: profilePicUrl ?? ""))
                    .placeholder {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                            .frame(width: 40, height: 40)
                    }
                    .onFailure { _ in
                        imageLoadFailed = true
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .fontStyle(size: 16, weight: .semibold)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text(username)
                        .fontStyle(size: 12, weight: .light)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(lastSeenText)
                        .fontStyle(size: 12, weight: .light)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    // Fallback Initials Circle
    private func fallbackInitialCircle(for name: String) -> some View {
        let initials = name.split(separator: " ").compactMap { $0.first }.prefix(2)
        let initialsText = initials.map(String.init).joined()

        return Text(initialsText)
            .font(.headline)
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(Circle().fill(Color.gray))
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

