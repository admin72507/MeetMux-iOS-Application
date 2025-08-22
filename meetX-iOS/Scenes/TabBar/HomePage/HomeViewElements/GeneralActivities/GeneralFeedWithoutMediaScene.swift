//
//  GeneralFeedWithoutMediaScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 01-06-2025.
//

import SwiftUI
import Combine

struct GeneralPostWithOutMediaScene: View {
    @ObservedObject var viewModel: HomeObservable
    @Binding var isLiveAnimating: Bool
    @Binding var showBottomViewWithDescription: Bool
    let postId: String
    
    @State private var isExpanded: Bool = false
    @State private var likeScale: CGFloat = 1.0
    @State private var likeRotation: Double = 0
    @State private var contentHeight: CGFloat = 0
    @State private var textHeight: CGFloat = 0
    
    private let headerHeight: CGFloat = 80
    private let footerHeight: CGFloat = 60
    private let maxCharacters: Int = 150
    var viewHeight: CGFloat
    
    @State private var localIndex = 0
    
    private var postItem: PostItem? {
        return viewModel.feedItemsObjects?.posts?.first { $0.postID == postId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header View - Using ThemedHeaderView instead of HeaderView
            if let postItem = postItem {
                ThemedHeaderView(
                    viewModel: viewModel,
                    isLiveAnimating: $isLiveAnimating,
                    postItem: postItem
                )
                
                // Content Area - Main text content
                contentView()
                
                //                // Bottom View with Actions
                TextPostBottomView(
                    viewModel: viewModel,
                    postId: postId,
                    isExpanded: $isExpanded,
                    likeScale: $likeScale,
                    likeRotation: $likeRotation,
                    showBootomView: $showBottomViewWithDescription
                )
            }
        }
        .onAppear {
            if let postItem = postItem {
                print(postItem)
                localIndex = postItem.mediaFiles?.startIndex ?? 0
            }
        }
        .background(ThemeManager.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
    
    private func contentView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let caption = postItem?.caption, !caption.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(caption)
                        .lineLimit(isExpanded ? nil : calculateLineLimit())
                        .fontStyle(size: 14, weight: .regular)
                        .foregroundColor(ThemeManager.foregroundColor)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(
                            GeometryReader { geometry in
                                Color.clear.onAppear {
                                    textHeight = geometry.size.height
                                }
                                .onChange(of: isExpanded) { _, _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        textHeight = geometry.size.height
                                    }
                                }
                            }
                        )
                        .padding(.bottom, 5)
                    
                    // Show More/Less button
                    if shouldShowToggleButton() {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Text(isExpanded ? "Show Less" : "Show More")
                                .fontStyle(size: 12, weight: .semibold)
                                .foregroundColor(ThemeManager.staticPinkColour)
                                .padding(.bottom, 2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                Text("No content available")
                    .fontStyle(size: 16, weight: .medium)
                    .foregroundColor(ThemeManager.foregroundColor.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(minHeight: 60)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func calculateLineLimit() -> Int {
        guard let caption = postItem?.caption else { return 1 }
        
        // Calculate based on content length and newlines
        let lines = caption.components(separatedBy: .newlines)
        let totalLines = lines.count
        
        // For collapsed state, show maximum 3 lines
        let maxLinesForCollapsed = 3
        
        // If text has natural line breaks, respect them up to the limit
        if totalLines <= maxLinesForCollapsed {
            return totalLines
        } else {
            return maxLinesForCollapsed
        }
    }
    
    private func shouldShowToggleButton() -> Bool {
        guard let caption = postItem?.caption, !caption.isEmpty else { return false }
        
        // Show toggle if content has more than 3 lines or more than 120 characters
        let lines = caption.components(separatedBy: .newlines).count
        let hasMultipleLines = lines > 3
        let hasLongText = caption.count > 120
        
        // Also check if the text would naturally wrap to more than 3 lines
        let estimatedLines = max(lines, caption.count / 50) // Rough estimation
        
        return hasMultipleLines || hasLongText || estimatedLines > 3
    }
}

struct TextPostBottomView: View {
    @ObservedObject var viewModel: HomeObservable
    let postId: String
    @Binding var isExpanded: Bool
    @Binding var likeScale: CGFloat
    @Binding var likeRotation: Double
    @Binding var showBootomView: Bool
    @State var showAllTags = false
    
    private var feedItem: PostItem? {
        return viewModel.feedItemsObjects?.posts?.first { $0.postID == postId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Separator line
            Rectangle()
                .fill(ThemeManager.foregroundColor.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            // Action buttons
            actionButtons()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }
    
    private func actionButtons() -> some View {
        HStack(spacing: 20) {
            likeButton()
            commentButton()
            shareButton()
            
            Spacer()
            
            // People Tags (after share button)
            if let peopleTags = feedItem?.peopleTags, peopleTags.count > 0 {
                PeopleTagsOverlayView(peopleTags: feedItem?.peopleTags ?? [], handleTapAction: { receivedUser in
                    guard let tagPeopleList = feedItem?.peopleTags, tagPeopleList.contains(where: {
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
    }
    
    // MARK: - Updated Like Button (if needed)
    private func likeButton() -> some View {
        Button(action: {
            HapticManager.trigger(.medium)
            // Like animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                likeScale = 1.3
                likeRotation += 360
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    likeScale = 1.0
                }
            }
            
            // Handle like with optimistic update
            if let feedItem = feedItem {
                viewModel.handleLike(for: feedItem)
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: feedItem?.userContext?.hasLiked == true
                      ? DeveloperConstants.systemImage.heartFill
                      : DeveloperConstants.systemImage.heartnotfilled
                )
                .foregroundColor(feedItem?.userContext?.hasLiked == true ? .red : ThemeManager.foregroundColor)
                    .scaleEffect(likeScale)
                    .rotationEffect(.degrees(likeRotation))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: likeScale)
                    .animation(.easeInOut(duration: 0.3), value: likeRotation)
                
                Text("\(feedItem?.totalLikes ?? 0)")
                    .foregroundColor(ThemeManager.foregroundColor)
                    .fontStyle(size: 14, weight: .medium)
            }
        }
    }
    
    private func commentButton() -> some View {
        Button(action: {
            HapticManager.trigger(.medium)
            
            if let feedItem = feedItem {
                viewModel.actionHandler?(feedItem, .comment)
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: DeveloperConstants.systemImage.bubbleRight)
                    .foregroundColor(ThemeManager.foregroundColor)
                
                Text("\(feedItem?.totalComments ?? 0)")
                    .foregroundColor(ThemeManager.foregroundColor)
                    .fontStyle(size: 14, weight: .medium)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func shareButton() -> some View {
        Button(action: {
            HapticManager.trigger(.medium)
            
            if let feedItem = feedItem {
                viewModel.actionHandler?(feedItem, .share)
            }
        }) {
            Image(systemName: "paperplane")
                .foregroundColor(ThemeManager.foregroundColor)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func moreOptionsButton() -> some View {
        Button(action: {
            HapticManager.trigger(.medium)
            
            if let feedItem = feedItem {
                viewModel.actionHandler?(feedItem, .moreOptions)
            }
        }) {
            Image(systemName: DeveloperConstants.systemImage.editOptionForPostAction)
                .foregroundColor(ThemeManager.foregroundColor)
        }
        .sheet(isPresented: $viewModel.showMoreOptionsSheet) {
                MoreOptionsBottomSheet(
                    postId: viewModel.moreOptionsPostId,
                    viewModel: viewModel,
                    isPresented: $viewModel.showMoreOptionsSheet
                )
        }
    }
}

// Updated HeaderView to remove any gradient backgrounds
struct ThemedHeaderView: View {
    @ObservedObject var viewModel: HomeObservable
    @Binding var isLiveAnimating: Bool
    let postItem: PostItem
    
    var body: some View {
        HStack(spacing: 12) {
            ProfileFeedImageView(
                imageUrl: postItem.user?.profilePicUrl ?? "",
                userName: postItem.user?.name ?? ""
            )
            .onTapGesture {
                viewModel.moveToUserProfileHome(for: postItem)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if viewModel.getCurrentUserID == postItem.user?.userId {
                    Text("You")
                        .fontStyle(size: 16, weight: .semibold)
                        .foregroundColor(ThemeManager.foregroundColor)
                } else {
                    Text(postItem.user?.name ?? "")
                        .fontStyle(size: 16, weight: .semibold)
                        .foregroundColor(ThemeManager.foregroundColor)
                }
                
                HStack(spacing: 8) {
                    Text(postItem.user?.username ?? "")
                        .fontStyle(size: 12, weight: .light)
                        .foregroundColor(ThemeManager.foregroundColor.opacity(0.7))
                    
                    Text("•")
                        .fontStyle(size: 12, weight: .light)
                        .foregroundColor(ThemeManager.foregroundColor.opacity(0.5))
                    
                    TimeAgoText(utcString: postItem.createdAt ?? "")
                        .fontStyle(size: 12, weight: .light)
                        .foregroundColor(ThemeManager.foregroundColor.opacity(0.7))
                }
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
                        .foregroundColor(ThemeManager.foregroundColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ThemeManager.backgroundColor.opacity(0.8))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(ThemeManager.foregroundColor.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(ThemeManager.backgroundColor)
    }
}

// Extension to maintain consistency with existing code
extension GeneralPostWithOutMediaScene {
    static func create(
        viewModel: HomeObservable,
        isLiveAnimating: Binding<Bool>,
        showBottomViewWithDescription: Binding<Bool>,
        postId: String,
        viewHeight: CGFloat
    ) -> GeneralPostWithOutMediaScene {
        return GeneralPostWithOutMediaScene(
            viewModel: viewModel,
            isLiveAnimating: isLiveAnimating,
            showBottomViewWithDescription: showBottomViewWithDescription,
            postId: postId, viewHeight: viewHeight
        )
    }
}
