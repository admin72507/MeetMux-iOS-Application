//
//  ExploreItemView.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 03-04-2025.
//
import SwiftUI
import Kingfisher

struct CardView: View {
    let feedItem: PostItem
    var scale: CGFloat
    let onCardTapped: () -> Void
    
    @State private var videoThumbnail: UIImage?
    @State private var isPressed = false
    @State private var animatePulse = false
    @ObservedObject var viewModel: ExploreViewModel
    
    var body: some View {
        ZStack {
            mediaView()
                .frame(width: 300 + (scale * 40), height: 220 + (scale * 30))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .shadow(color: .black.opacity(0.25), radius: scale * 8, x: 0, y: scale * 4)
            
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.black.opacity(0.4), location: 0.0),
                    .init(color: Color.black.opacity(0.3), location: 0.2),
                    .init(color: Color.clear, location: 0.6),
                    .init(color: Color.black.opacity(0.7), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 300 + (scale * 40), height: 220 + (scale * 30))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            VStack(spacing: 0) {
                topBar
                Spacer()
                centerContent
                Spacer()
                bottomStats
            }
            .background(
                BlurView(style: .systemUltraThinMaterialDark)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .opacity(0.1)
            )
        }
        .scaleEffect(isPressed ? 0.95 : (0.85 + (scale * 0.15)))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scale)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                withAnimation(.easeInOut(duration: 0.4)) { onCardTapped() }
            }
        }
    }
    
    private var currentUserId: String {
        KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userID) ?? ""
    }
    
    @ViewBuilder
    private func mediaView() -> some View {
        if let media = feedItem.mediaFiles?.first {
            let type = DeveloperConstants.MediaType(rawValue: media.type ?? "unknown")
            switch type {
                case .image, .unknown:
                    KFImage(URL(string: media.url ?? ""))
                        .resizable()
                        .scaledToFill()
                    
                case .video:
                    ZStack {
                        if let thumbnail = videoThumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    }
                    .task {
                        await loadThumbnailIfNeeded(from: URL(string: media.url ?? ""))
                    }
            }
        } else {
            ZStack {
                Color.gray.opacity(0.2)
                Image(systemName: "photo")
                    .font(.system(size: 35, weight: .light))
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
    }
    
    private func loadThumbnailIfNeeded(from url: URL?) async {
        guard let url = url, videoThumbnail == nil else { return }
        do {
            videoThumbnail = try await UIImage.thumbnailImage(for: url)
        } catch {
            print("Thumbnail generation failed: \(error.localizedDescription)")
        }
    }
    
    private var topBar: some View {
        HStack(spacing: 12) {
            KFImage(URL(string: feedItem.user?.profilePicUrl ?? ""))
                .placeholder {
                    Circle().fill(Color.gray.opacity(0.3))
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .frame(width: 18, height: 18)
                }
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 2))
                .shadow(color: .black.opacity(0.3), radius: 2)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(feedItem.user?.userId == currentUserId ? "You" : (feedItem.user?.name ?? "Unknown"))
                    .fontStyle(size: 16, weight: .semibold)
                    .foregroundColor(.white)
                
                Text(feedItem.user?.username ?? "")
                    .fontStyle(size: 14, weight: .medium)
                    .foregroundColor(.white.opacity(0.9))
                
                if let location = feedItem.location {
                    Text(location)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .onTapGesture {
                viewModel.moveToUserProfileHome(for: feedItem)
            }
            
            Spacer()
        
            remainingLiveTime
            
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private var remainingLiveTime: some View {
        Group {
            if let result = HelperFunctions.convertUTCToISTAndCalculateDifference(utcString: feedItem.endDate ?? "") {
                VStack(spacing: 0) {
                    Text("Live End's in")
                        .fontStyle(size: 12, weight: .semibold)
                        .foregroundColor(.white)
                    
                    Text("\(String(format: "%.1f", result.hoursFromNow)) hrs")
                        .fontStyle(size: 12, weight: .semibold)
                        .foregroundStyle(.green)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.4))
                .cornerRadius(10)
                .scaleEffect(animatePulse ? 1.05 : 1.0)
                .opacity(animatePulse ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animatePulse)
                .onAppear {
                    animatePulse = true
                }
            }
        }
    }
    
    private var centerContent: some View {
        VStack(spacing: 8) {
            if let tag = feedItem.activityTags?.first?.subcategories?.first?.title {
                HStack(spacing: 6) {
                    Image(systemName: DeveloperConstants.systemImage.figureWalking)
                        .font(.system(size: 12, weight: .medium))
                    Text(tag)
                        .fontStyle(size: 12, weight: .semibold)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.3))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            }
            
            if let caption = feedItem.caption, !caption.isEmpty {
                Text(caption)
                    .fontStyle(size: 12, weight: .semibold)
                    .foregroundColor(.white.opacity(0.95))
                    .lineLimit(4)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
    }
    
    private var bottomStats: some View {
        HStack(spacing: 16) {
            if let result = HelperFunctions.convertUTCToISTAndCalculateDifference(utcString: feedItem.eventDate ?? "") {
                let eventStartedAt = result.date
                let eventStartTime = result.time.uppercased()
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.9))
                    
                    VStack(alignment: .center, spacing: 5) {
                        Text("Event started at - ")
                            .fontStyle(size: 12, weight: .light)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(eventStartedAt + " on ")
                            .fontStyle(size: 12, weight: .semibold)
                            .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        
                        Text(eventStartTime)
                            .fontStyle(size: 12, weight: .semibold)
                            .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                    }
                }
            }
            
            Spacer()
            
            if let totalLikes = feedItem.totalLikes {
                HStack(spacing: 4) {
                    Image(systemName: feedItem.userContext?.hasLiked ?? false ? "heart.fill" : "heart")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.8))
                    Text("\(totalLikes)")
                        .fontStyle(size: 12, weight: .light)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            
            if let totalComments = feedItem.totalComments {
                HStack(spacing: 4) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 11))
                    Text("\(totalComments)")
                        .fontStyle(size: 12, weight: .light)
                }
                .foregroundColor(.white.opacity(0.9))
            }
            
            if let joined = feedItem.totalJoinedUsers {
                HStack(spacing: 4) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 11))
                    Text("\(joined)")
                        .fontStyle(size: 12, weight: .light)
                }
                .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

