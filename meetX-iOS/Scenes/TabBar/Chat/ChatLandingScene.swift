//
//  ChatLandingScene.swift
//  meetX-iOS
//
//  SIMPLIFIED: Removed complex loading states and timers
//

import SwiftUI
import Kingfisher
import Combine
import AlertToast

struct ChatLandingScene: View {
    @Binding var isTabBarPresented: Bool
    @ObservedObject private var viewModel: ChatLandingObservable = ViewModelStore.shared.getChatLandingObservable()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Active Users (only for Messages)
            if viewModel.selectedSegment == .Messages {
                HorizontalUserListView(viewModel: viewModel)
            }

            // Segment Control
            CustomSegmentedControl(
                selectedSegment: $viewModel.selectedSegment,
                titleProvider: { $0.title },
                onSegmentChanged: { index in
                    viewModel.selectedSegment = index == 0 ? .Messages : .ExploreConnections
                }
            )
            .frame(height: 45)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Main Content
            Group {
                switch viewModel.selectedSegment {
                    case .Messages:
                        MessagesContentView(viewModel: viewModel)
                    case .ExploreConnections:
                        ExploreConnectionsView(viewModel: viewModel)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.selectedSegment)
        }
        .background(ThemeManager.backgroundColor)
        .onAppear {
            viewModel.onViewAppear()
        }
        .onDisappear {
            viewModel.onViewDisappear()
        }
        .toast(isPresenting: Binding<Bool>(
            get: { !(viewModel.errorMessage?.isEmpty ?? true) },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            HelperFunctions().apiErrorToastCenter(
                Constants.chatTitleWithEmoji,
                viewModel.errorMessage ?? ""
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.refreshIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChatLandingNeedsRefresh"))) { _ in
            viewModel.forceRefresh()
        }
        .sheet(isPresented: $viewModel.showReportChatModal) {
            if let conversation = viewModel.selectedConversation {
                ReportChatView(
                    viewModel: viewModel,
                    conversation: conversation
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var headerView: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "message.circle.fill")
                    .fontStyle(size: 28, weight: .semibold)
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedSegment == .Messages ? "Chats" : "Connections")
                        .fontStyle(size: 24, weight: .bold)
                        .foregroundColor(.primary)

                    Text(viewModel.selectedSegment == .Messages
                         ? "Where Conversations Come to Life"
                         : "Start chat with people you know")
                    .fontStyle(size: 14, weight: .regular)
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                viewModel.routeManager.navigate(to: CreateRecommendedRoute())
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(ThemeManager.gradientBackground)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(ThemeManager.backgroundColor)
    }
}

// MARK: - SIMPLIFIED: Messages Content View
struct MessagesContentView: View {
    @ObservedObject var viewModel: ChatLandingObservable

    var body: some View {
        Group {
            if viewModel.recentChats.isEmpty {
                if viewModel.isInitialLoading {
                    SimpleLoadingView()
                } else {
                    ChatEmptyView {
                        viewModel.refreshData()
                    }
                }
            } else {
                ConversationListView(viewModel: viewModel)
                    .refreshable {
                        await viewModel.refreshData()
                    }
            }
        }
    }
}

// MARK: - SIMPLIFIED: Horizontal User List
struct HorizontalUserListView: View {
    @ObservedObject var viewModel: ChatLandingObservable

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.allUsers.isEmpty {
                if viewModel.isInitialLoading {
                    HorizontalUserLoadingView()
                } else {
                    HorizontalUserEmptyView {
                        viewModel.routeManager.navigate(to: CreateRecommendedRoute())
                    }
                }
            } else {
                HorizontalActiveUsersView(
                    users: viewModel.allUsers,
                    onUserAvatarTapped: { user in
                        HapticManager.trigger(.medium)
                        viewModel.routeManager.navigate(
                            to: ChatRoomRoute(
                                receiverId: user.userId ?? "",
                                profilePicture: user.profilePicUrl ?? ""
                            )
                        )
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - SIMPLIFIED: Loading Views
struct SimpleLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(
                    CircularProgressViewStyle(
                        tint: ThemeManager.staticPinkColour
                    )
                )

            Text("Loading...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ThemeManager.backgroundColor)
    }
}

struct HorizontalUserLoadingView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 68, height: 68)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            )

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 12)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 100)
    }
}

// MARK: - SIMPLIFIED: Empty Views
struct ChatEmptyView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.circle")
                .font(.system(size: 60))
                .foregroundStyle(ThemeManager.gradientNewPinkBackground)

            VStack(spacing: 12) {
                Text("No Conversations Yet")
                    .fontStyle(size: 18, weight: .semibold)
                    .foregroundColor(.primary)

                Text("Start a conversation with someone online")
                    .fontStyle(size: 16, weight: .light)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: {
                    HapticManager.trigger(.light)
                    onRetry()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                        Text("Refresh")
                            .fontStyle(size: 14, weight: .medium)
                    }
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(ThemeManager.gradientNewPinkBackground, lineWidth: 1)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ThemeManager.backgroundColor)
    }
}

struct HorizontalUserEmptyView: View {
    let onTap: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    Circle()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 68, height: 68)
                        .overlay(
                            Image(systemName: "plus.message")
                                .font(.system(size: 24))
                                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        )
                        .onTapGesture {
                            HapticManager.trigger(.light)
                            onTap()
                        }

                    Text("Add Connection")
                        .fontStyle(size: 14, weight: .light)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 100)
    }
}

// MARK: - SIMPLIFIED: Active Users View
struct HorizontalActiveUsersView: View {
    let users: [UserData]
    let onUserAvatarTapped: (UserData) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(users, id: \.userId) { user in
                    UserAvatarView(user: user)
                        .onTapGesture {
                            onUserAvatarTapped(user)
                        }
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 100)
    }
}

// MARK: - SIMPLIFIED: User Avatar View
struct UserAvatarView: View {
    let user: UserData

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .stroke(
                    user.isUserActive == true
                    ? ThemeManager.gradientNewPinkBackground
                    : LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 68, height: 68)
                .overlay(
                    Group {
                        if let imageURL = URL(string: user.profilePicUrl ?? "") {
                            KFImage(imageURL)
                                .cacheOriginalImage()
                                .fade(duration: 0.2)
                                .placeholder {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.gray)
                                        )
                                }
                                .resizable()
                                .scaledToFill()
                                .clipShape(Circle())
                                .frame(width: 60, height: 60)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                )

            Text(user.name ?? user.username ?? "Unknown")
                .fontStyle(size: 12, weight: .regular)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(maxWidth: 80, maxHeight: .infinity)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 10)
    }
}
