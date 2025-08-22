//
//  CommentsBootomSheetScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 09-06-2025.
//

import SwiftUI
import Combine
import Foundation
import Kingfisher

// MARK: - Comments Bottom Sheet
struct CommentsBottomSheet: View {
    
    @StateObject private var viewModel: CommentsViewModel
    @Binding var post: PostItem
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCommentFieldFocused: Bool
    @State private var commentText = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var editingCommentId: String? = nil
    @State private var editingCommentText = ""
    let updateCountAction: ((_ totalCommentCount: Int) -> Void)?
    
    init(post: Binding<PostItem>, updateCountAction: ((_ totalCommentCount: Int) -> Void)? = nil) {
        self._post = post
        self.updateCountAction = updateCountAction
        self._viewModel = StateObject(wrappedValue: CommentsViewModel(
            post: post.wrappedValue,
            userDataManager: UserDataManager.shared
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                    .opacity(0.3)
                
                // Comments Content
                ZStack {
                    if viewModel.isLoading && viewModel.comments.isEmpty {
                        loadingView
                    } else if viewModel.comments.isEmpty && !viewModel.isLoading {
                        emptyStateView
                    } else {
                        commentsListView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Comment Input Field - Always visible
                commentInputView
                    .background(
                        Rectangle()
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
                    )
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            .onReceive(Publishers.keyboardHeight) { height in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = height
                }
            }
        }
        .onAppear {
            viewModel.loadAllComments()
        }
        .onDisappear {
            post.incrementCommentCount(updatedCount: viewModel.comments.count)
            updateCountAction?(viewModel.comments.count)
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color(.systemGray6)))
            }
            .hidden()
            
            Spacer()
            
            Text("Comments")
                .fontStyle(size: 18, weight: .semibold)
                .foregroundColor(ThemeManager.foregroundColor)
            
            Spacer()
            
            HStack(spacing: 6) {
                Image(systemName: "bubble.right.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                
                Text("\(viewModel.totalComments)")
                    .fontStyle(size: 14, weight: .medium)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(ThemeManager.staticPinkColour)
            
            Text("Loading comments...")
                .fontStyle(size: 14, weight: .medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            // Animated Icon
            ZStack {
                Circle()
                    .fill(.cyan.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(viewModel.comments.isEmpty ? 1.0 : 0.8)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: viewModel.comments.isEmpty)
            
            VStack(spacing: 8) {
                Text("No comments yet")
                    .fontStyle(size: 16, weight: .semibold)
                    .foregroundColor(ThemeManager.foregroundColor)
                
                Text("Be the first to share your thoughts!")
                    .fontStyle(size: 12, weight: .light)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
    
    private var commentsListView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // Latest comments are shown first (Instagram-style)
                    ForEach(Array(viewModel.comments.enumerated()), id: \.element.id) { index, comment in
                        CommentRowView(
                            comment: comment,
                            viewModel: viewModel,
                            editingCommentId: $editingCommentId,
                            editingCommentText: $editingCommentText
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.comments.count)
                        
                        if index < viewModel.comments.count - 1 {
                            Divider()
                                .padding(.leading, 80)
                                .opacity(0.5)
                        }
                    }
                    
                    // Load more button for pagination
                    if viewModel.hasMoreComments && !viewModel.isLoadingMore {
                        Button(action: {
                            viewModel.loadMoreComments()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14))
                                Text("Load more comments")
                                    .fontStyle(size: 14, weight: .medium)
                            }
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                        }
                        .onAppear {
                            // Auto-load more when scrolled to bottom
                            viewModel.loadMoreComments()
                        }
                    }
                    
                    if viewModel.isLoadingMore {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading more...")
                                .fontStyle(size: 12, weight: .regular)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 12)
                    }
                    
                    // Bottom spacing for keyboard
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: max(keyboardHeight - 100, 20))
                        .id("bottom")
                }
                .padding(.bottom, 10)
            }
            .refreshable {
                await viewModel.refreshComments()
            }
            .onChange(of: viewModel.comments.count) { oldCount, newCount in
                // Only scroll to top when new comments are added (not when loading more)
                if newCount > oldCount && oldCount > 0 {
                    withAnimation(.easeOut(duration: 0.5)) {
                        proxy.scrollTo(viewModel.comments.first?.id, anchor: .top)
                    }
                }
            }
        }
    }
    
    private var commentInputView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // User Profile Picture
                CommentCurrentUserImageView(
                    imageUrl: viewModel.userDataManager.getSecureUserData().profilePicture ?? "",
                    userName: viewModel.userDataManager.getSecureUserData().userName ?? ""
                )
                
                // Text Field
                HStack(spacing: 8) {
                    TextField(
                        editingCommentId != nil ? "Edit comment..." : "Add a comment...",
                        text: editingCommentId != nil ? $editingCommentText : $commentText,
                        axis: .vertical
                    )
                    .focused($isCommentFieldFocused)
                    .fontStyle(size: 14, weight: .light)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(ThemeManager.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                editingCommentId != nil ? Color.orange.opacity(0.6) : Color.gray.opacity(0.3),
                                lineWidth: editingCommentId != nil ? 2 : 1
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .lineLimit(1...4)
                    .onSubmit {
                        if editingCommentId != nil {
                            saveEditedComment()
                        } else {
                            submitComment()
                        }
                    }
                    
                    // Cancel Edit Button (only shown when editing)
                    if editingCommentId != nil {
                        Button(action: cancelEdit) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Send/Save Button
                    Button(action: {
                        if editingCommentId != nil {
                            saveEditedComment()
                        } else {
                            submitComment()
                        }
                    }) {
                        Image(systemName: editingCommentId != nil ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(
                                (editingCommentId != nil ? !editingCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                ? (editingCommentId != nil ? ThemeManager.gradientBackground : ThemeManager.gradientNewPinkBackground)
                                : LinearGradient(colors: [.gray], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .scaleEffect((editingCommentId != nil ? !editingCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 1.0 : 0.9)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: editingCommentId != nil ? editingCommentText.isEmpty : commentText.isEmpty)
                    }
                    .disabled(editingCommentId != nil ? editingCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(ThemeManager.backgroundColor)
            
            // Edit mode indicator
            if editingCommentId != nil {
                HStack {
                    Image(systemName: "pencil")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    Text("Editing comment")
                        .fontStyle(size: 12, weight: .medium)
                        .foregroundStyle(.orange)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .background(ThemeManager.backgroundColor)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func submitComment() {
        let trimmedText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        viewModel.addNewComment(addedComment: trimmedText)
        commentText = ""
        isCommentFieldFocused = false
        
        HapticManager.trigger(.light)
    }
    
    private func startEditing(comment: CommentItem) {
        editingCommentId = comment.id
        editingCommentText = comment.text ?? ""
        isCommentFieldFocused = true
        
        // Hide menu when starting to edit
        viewModel.showingMenuForComment = nil
    }
    
    private func saveEditedComment() {
        guard let commentId = editingCommentId else { return }
        let trimmedText = editingCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        viewModel.editComment(commentId: commentId, editedComment: trimmedText)
        cancelEdit()
        
        HapticManager.trigger(.light)
    }
    
    private func cancelEdit() {
        editingCommentId = nil
        editingCommentText = ""
        isCommentFieldFocused = false
    }
    
    private func isCurrentUserComment(_ comment: CommentItem) -> Bool {
        return comment.userId == UserDataManager.shared.getSecureUserData().userId
    }
}

// MARK: - Comment Row View
struct CommentRowView: View {
    let comment: CommentItem
    @ObservedObject var viewModel: CommentsViewModel
    @Binding var editingCommentId: String?
    @Binding var editingCommentText: String
    @State private var showFullText = false
    
    private var isExpanded: Bool {
        viewModel.expandedComments.contains(comment.id ?? "")
    }
    
    private var isLiked: Bool {
        comment.likedUserIds?.contains(UserDataManager.shared.getSecureUserData().userId ?? "") ?? false
    }
    
    private var commentText: String {
        comment.text ?? ""
    }
    
    private var shouldShowExpandButton: Bool {
        commentText.count > 150 || commentText.components(separatedBy: .newlines).count > 3
    }
    
    private var isCurrentUser: Bool {
        comment.userId == UserDataManager.shared.getSecureUserData().userId
    }
    
    private var showingMenu: Bool {
        viewModel.showingMenuForComment == comment.id
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Profile Picture
                KFImage(URL(string: comment.profilePicUrl ?? ""))
                    .placeholder {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.gray.opacity(0.2), .gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 18))
                            )
                    }
                    .loadDiskFileSynchronously()
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
                
                VStack(alignment: .leading, spacing: 10) {
                    // User Info Header
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 5) {
                            if UserDataManager.shared.getSecureUserData().userId == comment.userId {
                                Text("You")
                                    .fontStyle(size: 16, weight: .semibold)
                                    .foregroundColor(ThemeManager.foregroundColor)
                            } else {
                                Text(comment.name ?? "")
                                    .fontStyle(size: 16, weight: .semibold)
                                    .foregroundColor(ThemeManager.foregroundColor)
                            }
                            
                            HStack(spacing: 8) {
                                Text(comment.userName ?? "")
                                
                                Text("•")
                                
                                TimeAgoText(utcString: comment.createdAt ?? "")
                            }
                            .fontStyle(size: 12, weight: .regular)
                            .foregroundColor(.gray)
                        }
                        .onTapGesture {
                            // Move to tagged user profile - you'll need to implement this
                             viewModel.moveToTaggedUserProfile(for: comment.userId ?? "")
                        }
                        
                        Spacer()
                        
                        // Menu Button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                if showingMenu {
                                    viewModel.showingMenuForComment = nil
                                } else {
                                    viewModel.showingMenuForComment = comment.id
                                }
                            }
                        }) {
                            Image(systemName: showingMenu ? "xmark" : "ellipsis")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color(.systemGray6))
                                        .opacity(showingMenu ? 1 : 0)
                                )
                                .scaleEffect(showingMenu ? 1.1 : 1.0)
                                .rotationEffect(.degrees(showingMenu ? 90 : 0))
                        }
                    }
                    
                    // Comment Text
                    VStack(alignment: .leading, spacing: 8) {
                        Text(commentText)
                            .fontStyle(size: 14, weight: .regular)
                            .foregroundColor(ThemeManager.foregroundColor)
                            .lineLimit(isExpanded ? nil : 3)
                            .fixedSize(horizontal: false, vertical: true)
                            .animation(.easeInOut(duration: 0.3), value: isExpanded)
                        
                        if shouldShowExpandButton {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    toggleExpanded(for: comment.id ?? "")
                                }
                            }) {
                                Text(isExpanded ? "Show less" : "Show more")
                                    .fontStyle(size: 13, weight: .regular)
                                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                            }
                        }
                    }
                    
                    // Action Buttons (only show when menu is not visible)
                    if !showingMenu {
                        HStack(spacing: 20) {
                            // Like Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                    viewModel.likeAComment(commentId: comment.id ?? "")
                                }
                                
                                HapticManager.trigger(.medium)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: isLiked ? "heart.fill" : "heart")
                                        .foregroundColor(isLiked ? .red : .secondary)
                                        .font(.system(size: 16, weight: .medium))
                                        .scaleEffect(isLiked ? 1.2 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isLiked)
                                    
                                    if let likeCount = comment.likeCount, likeCount > 0 {
                                        Text("\(likeCount)")
                                            .fontStyle(size: 12, weight: .medium)
                                            .foregroundColor(isLiked ? .red : .secondary)
                                    } else {
                                        Text("Like")
                                            .fontStyle(size: 12, weight: .medium)
                                            .foregroundColor(isLiked ? .red : .secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 4)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
            
            // Inline Menu Options (appears below the comment when menu is shown)
            if showingMenu {
                InlineMenuView(
                    comment: comment,
                    viewModel: viewModel,
                    isCurrentUser: isCurrentUser,
                    onEdit: {
                        startEditing(comment: comment)
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private func toggleExpanded(for commentId: String) {
        if viewModel.expandedComments.contains(commentId) {
            viewModel.expandedComments.remove(commentId)
        } else {
            viewModel.expandedComments.insert(commentId)
        }
    }
    
    private func startEditing(comment: CommentItem) {
        editingCommentId = comment.id
        editingCommentText = comment.text ?? ""
        
        // Hide menu when starting to edit
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            viewModel.showingMenuForComment = nil
        }
    }
}

// MARK: - Inline Menu View
struct InlineMenuView: View {
    let comment: CommentItem
    @ObservedObject var viewModel: CommentsViewModel
    let isCurrentUser: Bool
    let onEdit: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Separator line
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 1)
                .padding(.horizontal, 56)
                .padding(.top, 12)
            
            // Menu Options
            HStack(spacing: 0) {
                // Spacer to align with comment content
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 56)
                
                HStack(spacing: 24) {
                    // Edit/Report Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            if isCurrentUser {
                                onEdit()
                            } else {
                                viewModel.reportComment(commentId: comment.id ?? "")
                                viewModel.showingMenuForComment = nil
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isCurrentUser ? "square.and.pencil" : "flag.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isCurrentUser ? ThemeManager.foregroundColor : .red)
                            
                            Text(isCurrentUser ? "Edit" : "Report")
                                .fontStyle(size: 14, weight: .medium)
                                .foregroundColor(isCurrentUser ? ThemeManager.foregroundColor : .red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemGray6))
                        )
                    }
                    
                    // Delete Button (only for current user)
                    if isCurrentUser {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.deleteAComment(commentId: comment.id ?? "")
                                viewModel.showingMenuForComment = nil
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                                
                                Text("Delete")
                                    .fontStyle(size: 14, weight: .medium)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Helper Types
struct CommentMenuOption: Identifiable {
    let id = UUID()
    let commentId: String
}

// MARK: - Keyboard Height Publisher
extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
            }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ -> CGFloat in 0 }
        
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

// MARK: - Component for loading currentUser profile
struct CommentCurrentUserImageView: View {
    var imageUrl: String
    var userName: String
    
    private var firstLetter: String {
        return String(userName.prefix(2)).uppercased()
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(ThemeManager.staticPinkColour, lineWidth: 1)
                .frame(width: 30, height: 30)
            
            Circle()
                .stroke(ThemeManager.staticPinkColour, lineWidth: 1)
                .frame(width: 32, height: 32)
            
            if let url = URL(string: imageUrl), !imageUrl.isEmpty {
                KFImage(url)
                    .resizable()
                    .cancelOnDisappear(true)
                    .onFailure { _ in }
                    .placeholder {
                        placeholderView
                    }
                    .scaledToFill()
                    .frame(width: 25, height: 25)
                    .clipShape(Circle())
            } else {
                placeholderView
                    .frame(width: 25, height: 25)
            }
        }
        .shadow(radius: 5)
    }
    
    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
            Text(firstLetter)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.gray)
        }
        .clipShape(Circle())
    }
}
