////
////  PostDetailView.swift
////  meetX-iOS
////
////  Modern Post Detail View with Socket Integration
////
//
//import SwiftUI
//import Combine
//
//struct PostDetailView: View {
//    @StateObject private var viewModel: PostDetailViewModel
//    @Environment(\.dismiss) private var dismiss
//    @FocusState private var isCommentFieldFocused: Bool
//    @FocusState private var isReplyFieldFocused: Bool
//    
//    init(post: PostItem, socketClient: SocketFeedClientProtocol = SocketFeedClient()) {
//        self._viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post, socketClient: socketClient))
//    }
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                // Background
//                LinearGradient(
//                    colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .ignoresSafeArea()
//                
//                if viewModel.isJoiningRoom {
//                    // Loading State
//                    loadingView
//                } else {
//                    // Main Content
//                    ScrollView {
//                        LazyVStack(spacing: 0) {
//                            // Post Content
//                            postHeaderSection
//                            postContentSection
//                            postActionsSection
//                            
//                            // Comments Section
//                            commentsSection
//                        }
//                    }
//                    .refreshable {
//                        // Refresh functionality if needed
//                    }
//                }
//                
//                // Comment Input Overlay
//                VStack {
//                    Spacer()
//                    commentInputSection
//                }
//            }
//        }
//        .navigationBarHidden(true)
//        .alert("Error", isPresented: $viewModel.showError) {
//            Button("OK") { }
//        } message: {
//            Text(viewModel.error ?? "Something went wrong")
//        }
//    }
//}
//
//// MARK: - Loading View
//private extension PostDetailView {
//    var loadingView: some View {
//        VStack(spacing: 20) {
//            ProgressView()
//                .scaleEffect(1.2)
//                .tint(.blue)
//            
//            Text("Joining conversation...")
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//}
//
//// MARK: - Post Header Section
//private extension PostDetailView {
//    var postHeaderSection: some View {
//        VStack(spacing: 0) {
//            // Navigation Bar
//            HStack {
//                Button(action: { dismiss() }) {
//                    Image(systemName: "chevron.left")
//                        .font(.title2)
//                        .foregroundColor(.primary)
//                        .frame(width: 44, height: 44)
//                        .background(Color(.systemGray6))
//                        .clipShape(Circle())
//                }
//                
//                Spacer()
//                
//                Text("Post")
//                    .font(.headline)
//                    .fontWeight(.semibold)
//                
//                Spacer()
//                
//                Button(action: {}) {
//                    Image(systemName: "ellipsis")
//                        .font(.title2)
//                        .foregroundColor(.primary)
//                        .frame(width: 44, height: 44)
//                        .background(Color(.systemGray6))
//                        .clipShape(Circle())
//                }
//            }
//            .padding(.horizontal, 20)
//            .padding(.top, 10)
//            .padding(.bottom, 20)
//            
//            // User Info
//            HStack(spacing: 15) {
//                AsyncImage(url: URL(string: viewModel.post.user?.profilePic ?? "")) { image in
//                    image
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                } placeholder: {
//                    Circle()
//                        .fill(Color(.systemGray5))
//                        .overlay(
//                            Image(systemName: "person.fill")
//                                .foregroundColor(.gray)
//                        )
//                }
//                .frame(width: 50, height: 50)
//                .clipShape(Circle())
//                .overlay(
//                    Circle()
//                        .stroke(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
//                )
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(viewModel.post.user?.userName ?? "Unknown User")
//                        .font(.headline)
//                        .fontWeight(.semibold)
//                    
//                    if let location = viewModel.post.location {
//                        HStack(spacing: 4) {
//                            Image(systemName: "location.fill")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                            Text(location)
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                    }
//                }
//                
//                Spacer()
//                
//                if let createdAt = viewModel.post.createdAt {
//                    Text(formatDate(createdAt))
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//            }
//            .padding(.horizontal, 20)
//        }
//    }
//}
//
//// MARK: - Post Content Section
//private extension PostDetailView {
//    var postContentSection: some View {
//        VStack(alignment: .leading, spacing: 15) {
//            // Caption
//            if let caption = viewModel.post.caption, !caption.isEmpty {
//                Text(caption)
//                    .font(.body)
//                    .multilineTextAlignment(.leading)
//                    .padding(.horizontal, 20)
//            }
//            
//            // Media Content
//            if let mediaFiles = viewModel.post.mediaFiles, !mediaFiles.isEmpty {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 10) {
//                        ForEach(mediaFiles, id: \.self) { mediaUrl in
//                            AsyncImage(url: URL(string: mediaUrl)) { image in
//                                image
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fill)
//                            } placeholder: {
//                                Rectangle()
//                                    .fill(Color(.systemGray5))
//                                    .overlay(
//                                        ProgressView()
//                                            .tint(.gray)
//                                    )
//                            }
//                            .frame(width: 300, height: 200)
//                            .clipShape(RoundedRectangle(cornerRadius: 15))
//                        }
//                    }
//                    .padding(.horizontal, 20)
//                }
//            }
//            
//            // Activity Tags
//            if let activityTags = viewModel.post.activityTags, !activityTags.isEmpty {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 8) {
//                        ForEach(activityTags, id: \.self) { tag in
//                            Text("#\(tag)")
//                                .font(.caption)
//                                .padding(.horizontal, 12)
//                                .padding(.vertical, 6)
//                                .background(
//                                    Capsule()
//                                        .fill(Color.blue.opacity(0.1))
//                                )
//                                .foregroundColor(.blue)
//                        }
//                    }
//                    .padding(.horizontal, 20)
//                }
//            }
//        }
//        .padding(.vertical, 15)
//    }
//}
//
//// MARK: - Post Actions Section
//private extension PostDetailView {
//    var postActionsSection: some View {
//        VStack(spacing: 15) {
//            // Action Buttons
//            HStack(spacing: 30) {
//                // Like Button
//                Button(action: viewModel.toggleLike) {
//                    HStack(spacing: 8) {
//                        Image(systemName: viewModel.post.userContext?.hasLiked == true ? "heart.fill" : "heart")
//                            .font(.title2)
//                            .foregroundColor(viewModel.post.userContext?.hasLiked == true ? .red : .primary)
//                            .scaleEffect(viewModel.post.userContext?.hasLiked == true ? 1.1 : 1.0)
//                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.post.userContext?.hasLiked)
//                        
//                        Text("\(viewModel.post.totalLikes ?? 0)")
//                            .font(.subheadline)
//                            .fontWeight(.medium)
//                    }
//                }
//                .buttonStyle(ActionButtonStyle())
//                
//                // Comment Button
//                Button(action: { isCommentFieldFocused = true }) {
//                    HStack(spacing: 8) {
//                        Image(systemName: "bubble.right")
//                            .font(.title2)
//                        
//                        Text("\(viewModel.comments.count)")
//                            .font(.subheadline)
//                            .fontWeight(.medium)
//                    }
//                }
//                .buttonStyle(ActionButtonStyle())
//                
//                Spacer()
//                
//                // Share Button
//                Button(action: {}) {
//                    Image(systemName: "square.and.arrow.up")
//                        .font(.title2)
//                }
//                .buttonStyle(ActionButtonStyle())
//            }
//            .padding(.horizontal, 20)
//            
//            Divider()
//                .padding(.horizontal, 20)
//        }
//    }
//}
//
//// MARK: - Comments Section
//private extension PostDetailView {
//    var commentsSection: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            // Comments Header
//            HStack {
//                Text("Comments")
//                    .font(.headline)
//                    .fontWeight(.semibold)
//                
//                Spacer()
//                
//                Text("\(viewModel.comments.count)")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//            }
//            .padding(.horizontal, 20)
//            .padding(.vertical, 15)
//            
//            // Comments List
//            if viewModel.comments.isEmpty {
//                emptyCommentsView
//            } else {
//                LazyVStack(spacing: 15) {
//                    ForEach(viewModel.comments) { comment in
//                        CommentRowView(
//                            comment: comment,
//                            isExpanded: viewModel.expandedComments.contains(comment.id),
//                            isReplying: viewModel.replyingToCommentId == comment.id,
//                            replyText: $viewModel.replyText,
//                            onLike: { viewModel.toggleCommentLike(comment.id) },
//                            onReply: { viewModel.startReply(to: comment.id) },
//                            onToggleExpand: { viewModel.toggleCommentExpansion(comment.id) },
//                            onSubmitReply: { viewModel.addReply(to: comment.id) },
//                            onCancelReply: viewModel.cancelReply
//                        )
//                        .focused($isReplyFieldFocused, equals: viewModel.replyingToCommentId == comment.id)
//                    }
//                }
//                .padding(.horizontal, 20)
//            }
//        }
//        .padding(.bottom, 100) // Space for comment input
//    }
//    
//    var emptyCommentsView: some View {
//        VStack(spacing: 15) {
//            Image(systemName: "bubble.left.and.bubble.right")
//                .font(.system(size: 50))
//                .foregroundColor(.gray.opacity(0.5))
//            
//            Text("No comments yet")
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            Text("Be the first to share your thoughts!")
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.center)
//        }
//        .frame(maxWidth: .infinity)
//        .padding(.vertical, 50)
//    }
//}
//
//// MARK: - Comment Input Section
//private extension PostDetailView {
//    var commentInputSection: some View {
//        VStack(spacing: 0) {
//            if viewModel.replyingToCommentId != nil {
//                // Reply indicator
//                HStack {
//                    Text("Replying to comment")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    
//                    Spacer()
//                    
//                    Button("Cancel", action: viewModel.cancelReply)
//                        .font(.caption)
//                        .foregroundColor(.blue)
//                }
//                .padding(.horizontal, 20)
//                .padding(.vertical, 8)
//                .background(Color(.systemGray6))
//            }
//            
//            // Comment input
//            HStack(spacing: 12) {
//                AsyncImage(url: URL(string: "")) { image in
//                    image
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                } placeholder: {
//                    Circle()
//                        .fill(Color(.systemGray5))
//                        .overlay(
//                            Image(systemName: "person.fill")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                        )
//                }
//                .frame(width: 32, height: 32)
//                .clipShape(Circle())
//                
//                HStack {
//                    TextField("Write a comment...", text: $viewModel.newComment, axis: .vertical)
//                        .lineLimit(1...4)
//                        .focused($isCommentFieldFocused)
//                        .onSubmit {
//                            if !viewModel.newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                                viewModel.addComment()
//                                isCommentFieldFocused = false
//                            }
//                        }
//                    
//                    if !viewModel.newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                        Button(action: {
//                            viewModel.addComment()
//                            isCommentFieldFocused = false
//                        }) {
//                            Image(systemName: "arrow.up.circle.fill")
//                                .font(.title2)
//                                .foregroundColor(.blue)
//                        }
//                        .transition(.scale.combined(with: .opacity))
//                    }
//                }
//                .padding(.horizontal, 15)
//                .padding(.vertical, 10)
//                .background(
//                    RoundedRectangle(cornerRadius: 20)
//                        .fill(Color(.systemGray6))
//                )
//            }
//            .padding(.horizontal, 20)
//            .padding(.vertical, 12)
//            .background(
//                Color(.systemBackground)
//                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
//            )
//        }
//    }
//}
//
//// MARK: - Comment Row View
//struct CommentRowView: View {
//    let comment: CommentDetail
//    let isExpanded: Bool
//    let isReplying: Bool
//    @Binding var replyText: String
//    
//    let onLike: () -> Void
//    let onReply: () -> Void
//    let onToggleExpand: () -> Void
//    let onSubmitReply: () -> Void
//    let onCancelReply: () -> Void
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            // Main Comment
//            HStack(alignment: .top, spacing: 12) {
//                AsyncImage(url: URL(string: comment.profilePicUrl)) { image in
//                    image
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                } placeholder: {
//                    Circle()
//                        .fill(Color(.systemGray5))
//                        .overlay(
//                            Image(systemName: "person.fill")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                        )
//                }
//                .frame(width: 36, height: 36)
//                .clipShape(Circle())
//                
//                VStack(alignment: .leading, spacing: 8) {
//                    // Comment content
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text(comment.userName)
//                            .font(.subheadline)
//                            .fontWeight(.semibold)
//                        
//                        Text(comment.text)
//                            .font(.subheadline)
//                    }
//                    .padding(.horizontal, 15)
//                    .padding(.vertical, 10)
//                    .background(
//                        RoundedRectangle(cornerRadius: 15)
//                            .fill(Color(.systemGray6))
//                    )
//                    
//                    // Comment actions
//                    HStack(spacing: 20) {
//                        Button(action: onLike) {
//                            HStack(spacing: 4) {
//                                Image(systemName: comment.isLiked ? "heart.fill" : "heart")
//                                    .font(.caption)
//                                    .foregroundColor(comment.isLiked ? .red : .secondary)
//                                
//                                if comment.totalLikes > 0 {
//                                    Text("\(comment.totalLikes)")
//                                        .font(.caption)
//                                        .foregroundColor(.secondary)
//                                }
//                            }
//                        }
//                        
//                        Button("Reply", action: onReply)
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                        
//                        if !comment.replies.isEmpty {
//                            Button(action: onToggleExpand) {
//                                HStack(spacing: 4) {
//                                    Text("\(comment.replies.count) replies")
//                                        .font(.caption)
//                                        .foregroundColor(.blue)
//                                    
//                                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
//                                        .font(.caption2)
//                                        .foregroundColor(.blue)
//                                }
//                            }
//                        }
//                        
//                        Spacer()
//                        
//                        Text(formatDate(comment.createdAt))
//                            .font(.caption2)
//                            .foregroundColor(.secondary)
//                    }
//                    .padding(.leading, 15)
//                }
//            }
//            
//            // Replies
//            if isExpanded && !comment.replies.isEmpty {
//                VStack(spacing: 12) {
//                    ForEach(comment.replies) { reply in
//                        HStack(alignment: .top, spacing: 10) {
//                            AsyncImage(url: URL(string: reply.profilePicUrl)) { image in
//                                image
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fill)
//                            } placeholder: {
//                                Circle()
//                                    .fill(Color(.systemGray5))
//                                    .overlay(
//                                        Image(systemName: "person.fill")
//                                            .font(.caption2)
//                                            .foregroundColor(.gray)
//                                    )
//                            }
//                            .frame(width: 28, height: 28)
//                            .clipShape(Circle())
//                            
//                            VStack(alignment: .leading, spacing: 4) {
//                                VStack(alignment: .leading, spacing: 2) {
//                                    Text(reply.userName)
//                                        .font(.caption)
//                                        .fontWeight(.semibold)
//                                    
//                                    Text(reply.text)
//                                        .font(.caption)
//                                }
//                                .padding(.horizontal, 12)
//                                .padding(.vertical, 8)
//                                .background(
//                                    RoundedRectangle(cornerRadius: 12)
//                                        .fill(Color(.systemGray5))
//                                )
//                                
//                                HStack {
//                                    Text(formatDate(reply.createdAt))
//                                        .font(.caption2)
//                                        .foregroundColor(.secondary)
//                                    
//                                    Spacer()
//                                }
//                                .padding(.leading, 12)
//                            }
//                        }
//                        .padding(.leading, 48)
//                    }
//                }
//            }
//            
//            // Reply Input
//            if isReplying {
//                HStack(spacing: 10) {
//                    AsyncImage(url: URL(string: "")) { image in
//                        image
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                    } placeholder: {
//                        Circle()
//                            .fill(Color(.systemGray5))
//                            .overlay(
//                                Image(systemName: "person.fill")
//                                    .font(.caption)
//                                    .foregroundColor(.gray)
//                            )
//                    }
//                    .frame(width: 28, height: 28)
//                    .clipShape(Circle())
//                    
//                    HStack {
//                        TextField("Write a reply...", text: $replyText)
//                            .onSubmit(onSubmitReply)
//                        
//                        if !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                            Button("Send", action: onSubmitReply)
//                                .font(.caption)
//                                .foregroundColor(.blue)
//                        }
//                    }
//                    .padding(.horizontal, 12)
//                    .padding(.vertical, 8)
//                    .background(
//                        RoundedRectangle(cornerRadius: 15)
//                            .fill(Color(.systemGray6))
//                    )
//                }
//                .padding(.leading, 48)
//            }
//        }
//    }
//}
//
//// MARK: - Custom Button Style
//struct ActionButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
//            .opacity(configuration.isPressed ? 0.7 : 1.0)
//            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
//    }
//}
//
//// MARK: - Helper Functions
//private func formatDate(_ dateString: String) -> String {
//    // Implement your date formatting logic here
//    return "2h ago" // Placeholder
//}
//
//#Preview {
//    PostDetailView(post: PostItem(
//        postID: "1",
//        caption: "Beautiful sunset at the beach! 🌅",
//        location: "Malibu Beach, CA",
//        mediaFiles: ["https://example.com/image.jpg"],
//        user: UserItem(userName: "john_doe", profilePic: ""),
//        totalLikes: 42,
//        totalComments: 8,
//        activityTags: ["beach", "sunset", "photography"]
//    ))
//}
