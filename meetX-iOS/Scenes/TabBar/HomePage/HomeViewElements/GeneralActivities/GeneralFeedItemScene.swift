//
//  LiveActivityFeedItem.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 30-03-2025.
//

import SwiftUI
import Combine
import Kingfisher

struct GeneralFeedItemScene: View {
    @ObservedObject var viewModel: HomeObservable
    @Binding var isLiveAnimating: Bool
    @Binding var showBottomViewWithDescription: Bool
    @State private var localIndex = 0
    let postId: String
    var viewHeight: CGFloat
    
    private var postItem: PostItem? {
        viewModel.feedItemsObjects?.posts?.first { $0.postID == postId }
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                if postItem?.mediaFiles?.count ?? 0 > 0 {
                    mediaTabView()
                }
                
                if let postItem = postItem {
                    HeaderView(
                        viewModel: viewModel,
                        isLiveAnimating: $isLiveAnimating,
                        postItem: postItem
                    )
                    
                    BottomView(
                        viewModel: viewModel,
                        localIndex: $localIndex,
                        showBootomView: $showBottomViewWithDescription, feedItem: postItem,
                        viewHeight: max(viewHeight, 300),
                        likesCount: "\(postItem.totalLikes ?? 0)",
                        commentsCount: "\(postItem.totalComments ?? 0)",
                        postId: postItem.postID ?? "")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: postItem?.mediaFiles?.count ?? 0 > 0
               ? DeveloperConstants.mainContentSizesPost.generalWithImagePost
               : calculatedMinHeight
        )
        .onAppear {
            if let postItem = postItem {
                print(postItem)
                localIndex = postItem.mediaFiles?.startIndex ?? 0
            }
        }
    }
    
    private var calculatedMinHeight: CGFloat {
        let captionLength = postItem?.caption?.count ?? 0
        let baseHeight: CGFloat = 250
        
        // Rough estimate: ~50 characters per line, ~20 points per line
        let estimatedLines = max(1, captionLength / 50)
        let additionalHeight = CGFloat(estimatedLines - 1) * 20
        
        return max(baseHeight + additionalHeight, 300)
    }
    
    private func mediaTabView() -> some View {
        TabView(selection: $localIndex) {
            if let mediaFiles = postItem?.mediaFiles {
                ForEach(Array(mediaFiles.enumerated()), id: \.0) { index, media in
                    let mediaType = DeveloperConstants.MediaType(rawValue: media.type ?? "unknown")
                    mediaView(for: mediaType, at: index)
                        .tag(index)
                }
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: DeveloperConstants.mainContentSizesPost.generalWithImagePost)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 5)
    }
    
    private func mediaView(for mediaType: DeveloperConstants.MediaType, at index: Int) -> some View {
        Group {
            switch mediaType {
                case .image:
                    if let urlString = postItem?.mediaFiles?[index].url, let url = URL(string: urlString) {
                        KFImage(url)
                            .resizable()
                            .placeholder {
                                ProgressView().scaleEffect(1.5)
                            }
                            .retry(maxCount: 3, interval: .seconds(3))
                            .scaledToFill()
                    } else {
                        Color.gray
                    }
                case .video:
                    if let urlString = postItem?.mediaFiles?[index].url, let url = URL(string: urlString) {
                        VideoPlayerView(
                            videoURL: url,
                            isActive: localIndex == index,
                            videoFromGeneral: true
                        )
                    } else {
                        Color.black
                    }
                case .unknown:
                    Color.red
            }
        }
        .frame(height: DeveloperConstants.mainContentSizesPost.generalWithImagePost)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct HeaderView: View {
    @ObservedObject var viewModel: HomeObservable
    @Binding var isLiveAnimating: Bool
    let postItem: PostItem
    
    var body: some View {
        VStack {
            HStack {
                ProfileFeedImageView(
                    imageUrl: postItem.user?.profilePicUrl ?? "",
                    userName: postItem.user?.name ?? ""
                )
                .onTapGesture {
                    viewModel.moveToUserProfileHome(for: postItem)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    if viewModel.getCurrentUserID == postItem.user?.userId {
                        Text("You")
                            .fontStyle(size: 16, weight: .semibold)
                            .foregroundColor(.white)
                    }else {
                        Text(postItem.user?.name ?? "")
                            .fontStyle(size: 14, weight: .semibold)
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 8) {
                        Text(postItem.user?.username ?? "")
                        
                        Text("•")
                        
                        TimeAgoText(utcString: postItem.createdAt ?? "")
                    }
                    .fontStyle(size: 12, weight: .regular)
                    .foregroundColor(.white)
                }
                .onTapGesture {
                    viewModel.moveToUserProfileHome(for: postItem)
                }
                Spacer()
                
                if isLiveAnimating {
                    HStack(spacing: 5) {
                        ZStack {
                            Circle()
                                .frame(width: 14, height: 14)
                                .foregroundColor(.green.opacity(0.3))
                                .scaleEffect(1.6)
                                .animation(Animation.easeInOut(duration: 1).repeatForever(), value: isLiveAnimating)
                            Circle()
                                .frame(width: 8, height: 8)
                                .foregroundColor(.green)
                        }
                        Text(Constants.liveText)
                            .fontStyle(size: 14, weight: .regular)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                }
            }
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.85), Color.clear]), startPoint: .top, endPoint: .bottom)
            )
            .clipShape(RoundedCorners(radius: 16, corners: [.topLeft, .topRight]))
            Spacer()
        }
    }
}

struct BottomView: View {
    @ObservedObject var viewModel: HomeObservable
    @Binding var localIndex: Int
    @Binding var showBootomView: Bool
    @State var showMuteButton: Bool = false
    @State private var showAllTags : Bool = false
    
    let feedItem: PostItem
    var viewHeight: CGFloat
    let likesCount: String
    let commentsCount: String
    let postId: String
    
    private var postItem: PostItem? {
        return viewModel.feedItemsObjects?.posts?.first { $0.postID == postId }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.85), Color.clear]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: viewModel.expandedDescriptions.contains(feedItem.postID ?? "") ? viewHeight / 3 : 80)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(feedItem.caption ?? "")
                    .lineLimit(viewModel.expandedDescriptions.contains(feedItem.postID ?? "") ? nil : 2)
                    .fontStyle(size: 14, weight: .medium)
                    .foregroundColor(.white)
                
                if (feedItem.caption?.count ?? 0) > 100 {
                    Button(action: {
                        viewModel.toggleDescriptionExpansion(for: feedItem)
                    }) {
                        Text(viewModel.expandedDescriptions.contains(feedItem.postID ?? "") ? "Show Less" : "Show More")
                            .fontStyle(size: 12, weight: .semibold)
                            .foregroundColor(ThemeManager.staticPinkColour)
                    }
                }
                
                actionButtons()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .bottom)
        }
        .onChange(of: localIndex) { _, newIndex in
            showMuteButton = isCurrentMediaVideo
        }
        .onAppear {
            showMuteButton = isCurrentMediaVideo
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func actionButtons() -> some View {
        HStack(spacing: 12) {
            likeButton()
            commentButton()
            shareButton()
            showMuteButton ? MuteButtonView() : nil
            
            if (feedItem.mediaFiles?.count ?? 0) > 1 {
                mediaIndicators()
            } else {
                Spacer()
            }
            
            // People Tags (after share button)
            if let peopleTags = feedItem.peopleTags, peopleTags.count > 0 {
                PeopleTagsOverlayView(peopleTags: feedItem.peopleTags ?? [], handleTapAction: { receivedUser in
                    guard let tagPeopleList = feedItem.peopleTags, tagPeopleList.contains(where: {
                        $0.userId == receivedUser.id
                    }) else { return }
                    showAllTags.toggle()
                    viewModel.moveToTaggedUserProfile(for: receivedUser.id)
                },
                                      showAllTags: $showAllTags
                )
            }
            
            moreOptionsButton()
        }
        .padding(.top, 10)
    }
    
    private func likeButton() -> some View {
        Button(action: {
            HapticManager.trigger(.medium)
            
            viewModel.handleLike(for: feedItem) }) {
            Image(systemName: feedItem.userContext?.hasLiked == true ? DeveloperConstants.systemImage.heartFill : DeveloperConstants.systemImage.heartnotfilled)
                .foregroundColor(feedItem.userContext?.hasLiked == true ? .red : .white)
            Text(likesCount)
                .foregroundColor(.white)
                .fontStyle(size: 14, weight: .medium)
        }
    }
    
    private func commentButton() -> some View {
        Button(action: {
            HapticManager.trigger(.light)
            viewModel.actionHandler?(feedItem, .comment)
        }) {
            Image(systemName: DeveloperConstants.systemImage.bubbleRight)
                .foregroundColor(.white)
            Text(commentsCount)
                .foregroundColor(.white)
                .fontStyle(size: 14, weight: .medium)
        }
    }
    
    private func shareButton() -> some View {
        Button(action: {
            HapticManager.trigger(.medium)
            viewModel.actionHandler?(feedItem, .share)
        }) {
            Image(systemName: "paperplane")
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Fixed Mute Button Implementation
    struct ReactiveMuteButton: View {
        @ObservedObject private var videoManager = VideoPlaybackManager.shared
        
        var body: some View {
            Button(action: {
                videoManager.toggleMute()
            }) {
                Image(systemName: videoManager.isMuted
                      ? "speaker.slash.fill"
                      : "speaker.wave.2.fill"
                )
                .foregroundColor(.white)
            }
            .animation(.easeInOut(duration: 0.2), value: videoManager.isMuted)
        }
    }
    
    // Alternative: Function-based approach (also fixed)
    struct MuteButtonView: View {
        @ObservedObject private var videoManager = VideoPlaybackManager.shared
        
        var body: some View {
            muteButton()
        }
        
        private func muteButton() -> some View {
            Button(action: {
                videoManager.toggleMute()
            }) {
                Image(systemName: videoManager.isMuted
                      ? "speaker.slash.fill"
                      : "speaker.wave.2.fill"
                )
                .foregroundColor(.white)
            }
            .animation(.easeInOut(duration: 0.2), value: videoManager.isMuted)
        }
    }
    
    private func moreOptionsButton() -> some View {
        Button(action: {
            HapticManager.trigger(.medium)
            if let postItem = postItem {
                viewModel.actionHandler?(postItem, .moreOptions)
            }
        }) {
            Image(systemName: DeveloperConstants.systemImage.editOptionForPostAction)
                .foregroundColor(.white)
        }
        .sheet(isPresented: $viewModel.showMoreOptionsSheet) {
            MoreOptionsBottomSheet(
                postId: viewModel.moreOptionsPostId,
                viewModel: viewModel,
                isPresented: $viewModel.showMoreOptionsSheet
            )
        }
    }
    
    private func mediaIndicators() -> some View {
        HStack {
            Spacer()
            ForEach(Array((feedItem.mediaFiles ?? []).indices), id: \.self) { index in
                Circle()
                    .frame(width: localIndex == index ? 8 : 6, height: localIndex == index ? 8 : 6)
                    .foregroundColor(localIndex == index ? .white : .gray)
                    .opacity(localIndex == index ? 1 : 0.6)
                    .animation(.easeInOut(duration: 0.2), value: localIndex == index)
            }
        }
    }
    
    private var isCurrentMediaVideo: Bool {
        guard let media = feedItem.mediaFiles, media.indices.contains(localIndex) else { return false }
        return media[localIndex].type == "video"
    }
}
