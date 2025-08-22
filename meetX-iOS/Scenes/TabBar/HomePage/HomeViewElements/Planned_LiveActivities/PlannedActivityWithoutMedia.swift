//
//  PlannedActivityWithoutMedia.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 03-06-2025.
//

import SwiftUI
import Kingfisher

struct PlannedActivitiesWithoutMediaScene: View {
    
    @ObservedObject var viewModel: HomeObservable
    @State private var isExpanded: Bool = false
    @Binding var isLive: Bool
    let postId: String
    
    @State private var contentHeight: CGFloat = 0
    @State private var textHeight: CGFloat = 0
    @State private var likeScale: CGFloat = 1.0
    @State private var likeRotation: Double = 0
    @State private var showBottomViewWithDescription: Bool = false
    
    private let maxCharacters: Int = 150
    
    private var postItem: PostItem? {
        return viewModel.feedItemsObjects?.posts?.first { $0.postID == postId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let postItem = postItem {
                // Header with people tags overlay
                ZStack(alignment: .topTrailing) {
                    PlannedActivityHeaderScene(
                        feedItem: postItem,
                        isLive: $isLive,
                        viewModel: viewModel
                    )
                    .padding(.horizontal, 10)
                }
                
                // Location Section
                LocationSectionScene(
                    feedItem: postItem,
                    viewModel: viewModel,
                    actionForJoinedUser: { joinedUserTags in
                        viewModel.selectedJoinedUserList = joinedUserTags
                        viewModel.showJoinedUserList.toggle()
                    }
                )
                .padding(.top, 10)
                
                // Content Area - Caption with show more/less
                contentView()
                
                // Footer with like, comment, share, options and people tags
                PlannedActivityBottomView(
                    viewModel: viewModel,
                    feedItem: postItem,
                    isExpanded: $isExpanded,
                    likeScale: $likeScale,
                    likeRotation: $likeRotation,
                    showBootomView: $showBottomViewWithDescription,
                    totalLikes: "\(postItem.totalLikes ?? 0)",
                    totalComments: "\(postItem.totalComments ?? 0)",
                    hasLiked: postItem.userContext?.hasLiked ?? false,
                    postId: postItem.postID ?? ""
                )
            }
            
        }
        .sheet(isPresented: $viewModel.showJoinedUserList) {
            PeopleTagsDetailView(
                peopleTags: viewModel.selectedJoinedUserList,
                onUserTapAction: { receivedUser in
                    viewModel.showJoinedUserList.toggle()
                    viewModel.moveToTaggedUserProfile(for: receivedUser.userId)
                }, title: Constants.joinUserTitle)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .background(ThemeManager.backgroundColor)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4) // Reduced from 8 to 4
        .padding(.top, 4) // Reduced from 8 to 4
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
    
    private func contentView() -> some View {
        VStack(alignment: .leading, spacing: 6) { // Reduced from 8 to 6
            if let caption = postItem?.caption, !caption.isEmpty {
                VStack(alignment: .leading, spacing: 6) { // Reduced from 8 to 6
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
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                Text("Join this activity to see more details")
                    .fontStyle(size: 14, weight: .medium)
                    .foregroundColor(ThemeManager.foregroundColor.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(minHeight: 30) // Reduced from 40 to 30
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12) // Reduced from 12 to 8
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
        
        // Show toggle if content has more than 3 lines or more than 100 characters (including whitespace)
        let lines = caption.components(separatedBy: .newlines).count
        let hasMultipleLines = lines > 3
        let hasLongText = caption.count > 50 // Changed from 120 to 100
        
        // Also check if the text would naturally wrap to more than 3 lines
        let estimatedLines = max(lines, caption.count / 50) // Rough estimation
        
        return hasMultipleLines || hasLongText || estimatedLines > 3
    }
}

// MARK: - Planned Activity Bottom View (Footer)
struct PlannedActivityBottomView: View {
    @ObservedObject var viewModel: HomeObservable
    let feedItem: PostItem
    @Binding var isExpanded: Bool
    @Binding var likeScale: CGFloat
    @Binding var likeRotation: Double
    @Binding var showBootomView: Bool
    
    @State private var showAllTags : Bool = false
    @State private var hasShownInterest: Bool
    
    let totalLikes: String
    let totalComments: String
    let hasLiked: Bool
    let postId: String
    
    init(viewModel: HomeObservable,
         feedItem: PostItem,
         isExpanded: Binding<Bool>,
         likeScale: Binding<CGFloat>,
         likeRotation: Binding<Double>,
         showBootomView: Binding<Bool>,
         totalLikes: String,
         totalComments: String,
         hasLiked: Bool,
         postId: String
        ) {
        self.viewModel = viewModel
        self.feedItem = feedItem
        self._isExpanded = isExpanded
        self._likeScale = likeScale
        self._likeRotation = likeRotation
        self._showBootomView = showBootomView
        self._hasShownInterest = State(initialValue: feedItem.userContext?.hasShownInterest ?? false)
        self.totalLikes = totalLikes
        self.totalComments = totalComments
        self.hasLiked = hasLiked
        self.postId = postId
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
                .padding(.vertical, 8) // Reduced from 12 to 8
        }
    }
    
    private func actionButtons() -> some View {
        HStack(spacing: 20) {
            likeButton()
            commentButton()
            shareButton()
            
            Spacer()
            
            // People Tags (after share button)
            if let peopleTags = feedItem.peopleTags, peopleTags.count > 0 {
                PeopleTagsOverlayView(peopleTags: feedItem.peopleTags ?? [], handleTapAction: { receivedUser in
                    guard let tagPeopleList = feedItem.peopleTags, tagPeopleList.contains(where: {
                        $0.userId == receivedUser.id
                    }) else { return }
                    showAllTags.toggle()
                    viewModel.moveToTaggedUserProfile(for: receivedUser.id)
                },
                showAllTags: $showAllTags)
            }
            
            moreOptionsButton()
        }
    }
    
    // MARK: - Updated Like Button
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
            
            viewModel.handleLike(for: feedItem)
        }) {
            HStack(spacing: 6) {
                Image(systemName: feedItem.userContext?.hasLiked == true
                      ? DeveloperConstants.systemImage.heartFill
                      : DeveloperConstants.systemImage.heartnotfilled
                )
                .foregroundColor(feedItem.userContext?.hasLiked == true ? .red : ThemeManager.foregroundColor)
                .scaleEffect(likeScale)
                .rotationEffect(.degrees(likeRotation))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: likeScale)
                .animation(.easeInOut(duration: 0.3), value: likeRotation)
                
                Text("\(feedItem.totalLikes ?? 0)")
                    .foregroundColor(ThemeManager.foregroundColor)
                    .fontStyle(size: 14, weight: .medium)
            }
        }
    }
    
    private func commentButton() -> some View {
        Button(action: {
            HapticManager.trigger(.medium)
            viewModel.actionHandler?(feedItem, .comment)
        }) {
            HStack(spacing: 6) {
                Image(systemName: DeveloperConstants.systemImage.bubbleRight)
                    .foregroundColor(ThemeManager.foregroundColor)
                
                Text(totalComments)
                    .foregroundColor(ThemeManager.foregroundColor)
                    .fontStyle(size: 14, weight: .medium)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func shareButton() -> some View {
        Button(action: {
            HapticManager.trigger(.medium)
            viewModel.actionHandler?(feedItem, .share)
        }) {
            Image(systemName: "paperplane")
                .foregroundColor(ThemeManager.foregroundColor)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func moreOptionsButton() -> some View {
        Button(action: {
            HapticManager.trigger(.medium)
            viewModel.actionHandler?(feedItem, .moreOptions)
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

// MARK: - People Tags Overlay View (Updated for Footer)
struct PeopleTagsOverlayView: View {
    let peopleTags: [PeopleTags]
    let handleTapAction: (PeopleTags) -> Void
    
    @Binding var showAllTags: Bool
    
    private let maxVisibleTags = 4
    
    var body: some View {
        HStack(spacing: -8) {
            ForEach(Array(visibleTags.enumerated()), id: \.offset) { index, tag in
                KFImage(URL(string: tag.profilePicUrl))
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                ProgressView()
                            )
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(ThemeManager.backgroundColor, lineWidth: 1)
                    )
                    .zIndex(Double(visibleTags.count - index))
            }
            
            if remainingCount > 0 {
                Circle()
                    .fill(ThemeManager.staticPinkColour.opacity(0.8))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text("+\(remainingCount)")
                            .fontStyle(size: 8, weight: .bold)
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(ThemeManager.backgroundColor, lineWidth: 1)
                    )
                    .zIndex(0)
            }
        }
        .onTapGesture {
            showAllTags.toggle()
        }
        .sheet(isPresented: $showAllTags) {
            PeopleTagsDetailView(peopleTags: peopleTags, onUserTapAction: { receivedUser in
                handleTapAction(receivedUser)
            }, title: Constants.taggedUserTitle)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var visibleTags: [PeopleTags] {
        Array(peopleTags.prefix(maxVisibleTags))
    }
    
    private var remainingCount: Int {
        max(peopleTags.count - maxVisibleTags, 0)
    }
}


// MARK: - People Tags Detail View
import SwiftUI
import Kingfisher

struct PeopleTagsDetailView: View {
    let peopleTags: [PeopleTags]
    let onUserTapAction: (PeopleTags) -> Void
    let title: String
    
    var body: some View {
        List {
            Section(header:
                VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontStyle(size: 16, weight: .semibold)
                    .foregroundColor(ThemeManager.foregroundColor)
                
                Text("\nvisit the profile page to see more information about the person".capitalizingFirstLetter())
                    .fontStyle(size: 12, weight: .light)
                    .foregroundColor(.gray)
            }
                .padding(.top, 8)
                .textCase(nil)
            ) {
                ForEach(peopleTags) { tag in
                    HStack(spacing: 12) {
                        KFImage(URL(string: tag.profilePicUrl))
                            .placeholder {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay(ProgressView())
                            }
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(ThemeManager.backgroundColor, lineWidth: 1)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            let userDisplayName = KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userID) ?? "" == tag.userId ? "You" : tag.name
                            Text(userDisplayName)
                                .fontStyle(size: 16, weight: .semibold)
                                .foregroundColor(ThemeManager.foregroundColor)
                            
                            Text(tag.username)
                                .fontStyle(size: 14, weight: .regular)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onUserTapAction(tag)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(ThemeManager.backgroundColor.ignoresSafeArea())
    }
}


// MARK: - Extension for Dynamic Height Calculation
extension PlannedActivitiesWithoutMediaScene {
    static func calculateHeight(for postItem: PostItem, isExpanded: Bool = false) -> CGFloat {
        let headerHeight: CGFloat = 100 // PlannedActivityHeaderScene height
        let locationHeight: CGFloat = 80 // LocationSectionScene height
        let interestButtonHeight: CGFloat = 60 // InterestButtonSection height
        let footerHeight: CGFloat = 50 // Reduced footer height
        let padding: CGFloat = 8 // Reduced overall padding
        
        // Calculate content height based on caption
        var contentHeight: CGFloat = 30 // Reduced minimum height
        
        if let caption = postItem.caption, !caption.isEmpty {
            let estimatedLineHeight: CGFloat = 20
            let maxCollapsedLines = 3
            
            if isExpanded {
                let lines = caption.components(separatedBy: .newlines).count
                let estimatedLines = max(lines, caption.count / 50)
                contentHeight = CGFloat(estimatedLines) * estimatedLineHeight + 30 // Reduced padding
            } else {
                contentHeight = CGFloat(maxCollapsedLines) * estimatedLineHeight + 30 // Reduced padding
            }
            
            // Add show more/less button height if needed
            if caption.count > 100 || caption.components(separatedBy: .newlines).count > 3 {
                contentHeight += 25 // Reduced button height
            }
        }
        
        return headerHeight + locationHeight + contentHeight + interestButtonHeight + footerHeight + padding
    }
    
    static func create(
        viewModel: HomeObservable,
        isLive: Binding<Bool>,
        postId: String
    ) -> PlannedActivitiesWithoutMediaScene {
        return PlannedActivitiesWithoutMediaScene(
            viewModel: viewModel,
            isLive: isLive,
            postId: postId
        )
    }
}
