//
//  PastConversationScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 01-07-2025.
//
import SwiftUI
import Combine
import Kingfisher

// MARK: - ConversationListView
struct ConversationListView: View {
    @ObservedObject var viewModel: ChatLandingObservable

    @Environment(\.colorScheme) var colorScheme

    @State private var searchText = ""
    @State private var selectedFilter: DeveloperConstants.ConversationFilter = .all
    @State private var isSearchActive = false
    @State private var isMuteExpanded = false

    // Filtered conversations based on search and filter
    private var filteredConversations: [RecentChat] {
        var filtered = viewModel.recentChats

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { conversation in
                let name = conversation.name ?? conversation.username ?? ""
                return name.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply chip filter
        switch selectedFilter {
            case .all:
                break // No additional filtering
            case .unread:
                filtered = filtered.filter { conversation in
                    guard let unreadCount = conversation.unreadCount else { return false }
                    return unreadCount > 0
                }
        }

        return filtered
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Header
            searchHeader

            // Filter Chips
            filterChips

            // Conversations List - Using ScrollView instead of List for better control
            conversationsList
        }
        .background(Color(.systemGroupedBackground))
        .confirmationDialog(
            "Delete Conversation",
            isPresented: $viewModel.showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Conversation", role: .destructive) {
                if let conversation = viewModel.selectedConversation {
                    viewModel.deleteAconversation(conversation)
                }
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            if let conversationName = viewModel.selectedConversation?.name ?? viewModel.selectedConversation?.username {
                Text("Are you sure you want to delete this conversation with \(conversationName)? This action cannot be undone.")
            } else {
                Text("Are you sure you want to delete this conversation? This action cannot be undone.")
            }
        }
        .sheet(isPresented: $viewModel.showingMoreOptions) {
            moreOptionsSheet
        }
    }

    // MARK: - Search Header
    private var searchHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .fontStyle(size: 16, weight: .medium)

                    TextField("Search conversations...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .fontStyle(size: 14, weight: .regular)
                        .onTapGesture {
                            isSearchActive = true
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            isSearchActive = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .fontStyle(size: 16, weight: .medium)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(colorScheme == .light ? .white : Color(.tertiarySystemGroupedBackground))
                .cornerRadius(10)

                if isSearchActive {
                    Button("Cancel") {
                        searchText = ""
                        isSearchActive = false
                        hideKeyboard()
                    }
                    .fontStyle(size: 16, weight: .medium)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DeveloperConstants.ConversationFilter.allCases, id: \.self) { filter in
                    filterChipView(for: filter)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private func filterChipView(for filter: DeveloperConstants.ConversationFilter) -> some View {
        FilterChipChat(
            title: filter.title,
            isSelected: selectedFilter == filter,
            unreadCount: filter == .unread ? getUnreadCount() : nil
        ) {
            selectedFilter = filter
        }
    }

    // MARK: - Conversations List
    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if filteredConversations.isEmpty {
                    emptyStateView
                        .padding(.top, 60)
                } else {
                    // Conversations Card Section
                    VStack(spacing: 0) {
                        ForEach(filteredConversations.indices, id: \.self) { index in
                            let conversation = filteredConversations[index]

                            SwipeableConversationRow(
                                viewModel: viewModel,
                                conversation: conversation,
                                onDelete: {
                                    viewModel.showDeleteConfirmation(for: conversation)
                                },
                                onMoreOptions: {
                                    viewModel.showMoreOptions(for: conversation)
                                }
                            )
                            .onAppear {
                                if filteredConversations.count >= 10,
                                   index == filteredConversations.count - 3 {
                                    viewModel.loadMoreConversations()
                                }
                            }

                            if index < filteredConversations.count - 1 {
                                Divider()
                                    .padding(.leading, 86)
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                // Loading more section
                //            if viewModel.isLoadingMore {
                //                VStack(spacing: 8) {
                //                    ProgressView()
                //                        .scaleEffect(0.9)
                //                    Text("Loading more conversations...")
                //                        .fontStyle(size: 12, weight: .regular)
                //                        .foregroundColor(.secondary)
                //                }
                //                .padding(.vertical, 20)
                //            }
            }
            .padding(.bottom, 50) // Replace Spacer with padding
        }
        .refreshable {
            await viewModel.refreshData() // Enable pull-to-refresh
        }
    }

    // MARK: - More Options Sheet
    private var moreOptionsSheet: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 24)

            // Header
            VStack(spacing: 16) {
                if let conversation = viewModel.selectedConversation {
                    HStack(spacing: 12) {
                        KFImage(URL(string: conversation.profilePicUrl ?? ""))
                            .placeholder {
                                Circle()
                                    .fill(Color(.tertiarySystemGroupedBackground))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .fontStyle(size: 16, weight: .medium)
                                            .foregroundColor(.secondary)
                                    )
                            }
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                            .frame(width: 40, height: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(conversation.name ?? conversation.username ?? "Unknown")
                                .fontStyle(size: 16, weight: .semibold)
                                .foregroundColor(.primary)

                            Text("Chat Options")
                                .fontStyle(size: 14, weight: .regular)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
            }

            // Options Card
            VStack(spacing: 0) {
                muteOptionRow()

                if isMuteExpanded {
                    // Mute Duration Options
                    VStack(spacing: 0) {
                        Divider()
                            .padding(.leading, 52)

                        muteDurationOption("8 hours", duration: .hours(8))

                        Divider()
                            .padding(.leading, 52)

                        muteDurationOption("12 hours", duration: .hours(12))

                        Divider()
                            .padding(.leading, 52)

                        muteDurationOption("1 week", duration: .days(7))

                        Divider()
                            .padding(.leading, 52)

                        muteDurationOption("1 year", duration: .days(365))
                    }
                }

                Divider()
                    .padding(.leading, 52)

                // Visit Profile Option
                moreOptionRow(
                    icon: "person.circle",
                    title: "Visit Profile",
                    subtitle: "View this person's profile",
                    action: {
                        if let conversation = viewModel.selectedConversation {
                            viewModel.visitProfile(conversation)
                        }
                    }
                )

                Divider()
                    .padding(.leading, 52)

                // Report Chat Option
                moreOptionRow(
                    icon: "exclamationmark.triangle",
                    title: "Report Chat",
                    subtitle: "Report this conversation",
                    textColor: .red,
                    action: {
                        viewModel.showingMoreOptions.toggle()
                        viewModel.showReportChatModal.toggle()
                    }
                )
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 24)

            Spacer()
        }
        .onDisappear() {
            isMuteExpanded = false
        }
        .background(Color(.systemGroupedBackground))
        .presentationDetents([.height(isMuteExpanded ? 600 : 380)])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - More Option Row
    private func moreOptionRow(
        icon: String,
        title: String,
        subtitle: String,
        textColor: Color = .primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .fontStyle(size: 16, weight: .medium)
                        .foregroundColor(textColor)

                    Text(subtitle)
                        .fontStyle(size: 14, weight: .regular)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: icon)
                    .fontStyle(size: 20, weight: .medium)
                    .foregroundStyle(
                        LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Mute Option Row
    private func muteOptionRow() -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                if !(viewModel.selectedConversation?.isMuted ?? false) {
                    isMuteExpanded.toggle()
                }else {
                    HapticManager.trigger(.medium)
                    if let conversation = viewModel.selectedConversation {
                        viewModel
                            .muteConversation(
                                conversation,
                                completion: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isMuteExpanded = false
                                    }
                                    viewModel.showingMoreOptions = false
                                }
                            )
                    }
                }
            }
        }) {
            HStack(spacing: 12) {

                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        viewModel.selectedConversation?.isMuted ?? false
                        ? "Unmute Chat"
                        :"Mute Chat"
                    )
                    .fontStyle(size: 16, weight: .medium)
                    .foregroundColor(.primary)

                    Text(
                        viewModel.selectedConversation?.isMuted ?? false
                        ?"Turn on notifications for this chat"
                        :"Turn off notifications for this chat"
                    )
                    .fontStyle(size: 14, weight: .regular)
                    .foregroundColor(.secondary)
                }

                Spacer()
                if !(viewModel.selectedConversation?.isMuted ?? false) {
                    Image(systemName: isMuteExpanded
                          ? "chevron.up"
                          : "chevron.down"
                    )
                    .fontStyle(size: 14, weight: .medium)
                    .foregroundColor(.secondary)
                }

                Image(systemName: "speaker.slash")
                    .fontStyle(size: 20, weight: .medium)
                    .foregroundStyle(
                        LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Mute Duration Options
    private func muteDurationOption(
        _ title: String,
        duration: DeveloperConstants.MuteDuration
    ) -> some View {
        Button(
            action: {
                HapticManager.trigger(.medium)
                if let conversation = viewModel.selectedConversation {
                    viewModel
                        .muteConversation(
                            conversation,
                            completion: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isMuteExpanded = false
                                }
                                viewModel.showingMoreOptions = false
                            }
                        )
                }
            }) {
                HStack {
                    Text(title)
                        .fontStyle(size: 15, weight: .regular)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding(.horizontal, 52)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "message.circle" : "magnifyingglass")
                .fontStyle(size: 50, weight: .regular)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Conversations" : "No Results Found")
                    .fontStyle(size: 18, weight: .semibold)
                    .foregroundColor(.primary)

                Text(searchText.isEmpty ?
                     "Start a conversation with someone online" :
                        "Try searching with different keywords")
                .fontStyle(size: 14, weight: .regular)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    // MARK: - Helper Methods
    private func getUnreadCount() -> Int {
        return viewModel.recentChats.compactMap { $0.unreadCount }.reduce(0, +)
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Swipeable Conversation Row
extension ConversationListView {
    struct SwipeableConversationRow: View {
        @ObservedObject var viewModel: ChatLandingObservable
        @State private var offset: CGFloat = 0
        @State private var isShowingActions = false

        let conversation: RecentChat
        let onDelete: () -> Void
        let onMoreOptions: () -> Void
        private let actionWidth: CGFloat = 80
        private let maxSwipeDistance: CGFloat = 160

        var body: some View {
            ZStack(alignment: .trailing) {
                // Action buttons background
                HStack(spacing: 0) {
                    Spacer()

                    // More options button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            offset = 0
                        }
                        onMoreOptions()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "ellipsis")
                                .fontStyle(size: 10, weight: .light)
                                .foregroundColor(.white)

                            Text("More")
                                .fontStyle(size: 10, weight: .light)
                                .foregroundColor(.white)
                        }
                        .frame(width: actionWidth, height: 84)
                        .background(ThemeManager.gradientNewPinkBackground)
                    }

                    // Delete button
                    Button(action: {
                        HapticManager.trigger(.medium)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            offset = 0
                        }
                        onDelete()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "trash")
                                .fontStyle(size: 10, weight: .light)
                                .foregroundColor(.white)

                            Text("Delete")
                                .fontStyle(size: 10, weight: .light)
                                .foregroundColor(.white)
                        }
                        .frame(width: actionWidth, height: 84)
                        .background(Color.red)
                    }
                }
                .frame(width: maxSwipeDistance)

                // Main conversation row
                ConversationRowView(conversation: conversation)
                    .background(Color(.secondarySystemGroupedBackground))
                    .offset(x: offset)
                    .gesture(
                        DragGesture(minimumDistance: 20, coordinateSpace: .local) // Add minimum distance
                            .onChanged { value in
                                let translation = value.translation
                                let horizontalMovement = abs(translation.width)
                                let verticalMovement = abs(translation.height)

                                // Only respond to horizontal swipes if they're more horizontal than vertical
                                guard horizontalMovement > verticalMovement * 1.5 else { return }

                                // Only allow left swipe (negative translation)
                                if translation.width < 0 {
                                    offset = max(translation.width, -maxSwipeDistance)
                                } else if offset < 0 {
                                    // Allow right swipe to close
                                    offset = min(0, offset + translation.width)
                                }
                            }
                            .onEnded { value in
                                let translation = value.translation
                                let velocity = value.velocity
                                let horizontalMovement = abs(translation.width)
                                let verticalMovement = abs(translation.height)

                                // Only complete the swipe action if it was primarily horizontal
                                guard horizontalMovement > verticalMovement * 1.5 else {
                                    // Reset to current state if gesture was too vertical
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        offset = offset < -maxSwipeDistance/2 ? -maxSwipeDistance : 0
                                        isShowingActions = offset < 0
                                    }
                                    return
                                }

                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if translation.width < -60 || velocity.width < -300 {
                                        // Show actions
                                        offset = -maxSwipeDistance
                                        isShowingActions = true
                                        viewModel.swipeOpenConversationId = conversation.conversationId
                                    } else {
                                        // Hide actions
                                        offset = 0
                                        isShowingActions = false
                                        viewModel.swipeOpenConversationId = nil
                                    }
                                }
                            }
                    )
            }
            .onChange(of: viewModel.swipeOpenConversationId) { _, newId in
                // If swipeOpenConversationId is not this cell, reset offset
                if newId != conversation.conversationId {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        offset = 0
                        isShowingActions = false
                    }
                }
            }
            .clipped()
            .onTapGesture {
                if isShowingActions {
                    // Close actions on tap
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        offset = 0
                        isShowingActions = false
                        viewModel.swipeOpenConversationId = nil
                    }
                } else {
                    // Handle conversation tap
                    HapticManager.trigger(.medium)
                    viewModel.routeManager
                        .navigate(
                            to: ChatRoomRoute(
                                receiverId: conversation.receiverId ?? "",
                                profilePicture: conversation.profilePicUrl ?? ""
                            )
                        )
                }
            }
        }
    }
}

// MARK: - Filter Chip Component
extension ConversationListView {
    struct FilterChipChat: View {
        let title: String
        let isSelected: Bool
        let unreadCount: Int?
        let onTap: () -> Void

        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 6) {
                    Text(title)
                        .fontStyle(size: isSelected ? 14 : 12, weight: isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? .white : .primary)

                    if let count = unreadCount, count > 0 {
                        Text("\(count)")
                            .fontStyle(size: 12, weight: .bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.white.opacity(0.3) : .gray.opacity(0.5))
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ?
                              ThemeManager.staticPurpleColour : Color(.tertiarySystemGroupedBackground)))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.clear : Color(.separator).opacity(0.5),
                            lineWidth: 0.5
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Conversation Row View
extension ConversationListView {
    struct ConversationRowView: View {
        let conversation: RecentChat

        @State private var imageLoadFailed: Bool = false
        @State private var isImageCached: Bool? = nil

        private var lastMessage: ChatMessage? {
            conversation.messages?.first
        }

        private var messagePreview: String {
            guard let message = lastMessage else { return "No messages" }

            let type = MessageType(rawValue: message.messageType ?? "")

            switch type {
                case .text:
                    return message.deletedAt == nil ? (message.messageText ?? "Message") : "Message deleted"
                case .image:
                    return "📷 Photo"
                case .video:
                    return "🎥 Video"
                case .audio:
                    return "🎵 Audio"
                case .unknown:
                    return "Message"
            }
        }

        private var hasUnreadMessages: Bool {
            guard let unreadCount = conversation.unreadCount else { return false }
            return unreadCount > 0
        }

        var body: some View {
            HStack(spacing: 14) {
                profileImageView
                messageContentView
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .onAppear {
                checkImageCache()
            }
        }

        // MARK: - Check Cache
        private func checkImageCache() {
            guard let urlStr = conversation.profilePicUrl,
                  let url = URL(string: urlStr) else {
                isImageCached = false
                return
            }

            let cache = KingfisherManager.shared.cache
            isImageCached = cache.isCached(forKey: url.cacheKey)
        }

        // MARK: - Profile Image View
        private var profileImageView: some View {
            ZStack(alignment: .bottomTrailing) {
                if isImageCached == true {
                    KFImage(URL(string: conversation.profilePicUrl ?? ""))
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 56, height: 56)
                } else {
                    KFImage(URL(string: conversation.profilePicUrl ?? ""))
                        .onFailure { _ in
                            imageLoadFailed = true
                        }
                        .placeholder {
                            // Simple placeholder without progress indicator
                            Circle()
                                .fill(Color(.tertiarySystemGroupedBackground))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .fontStyle(size: 24, weight: .medium)
                                        .foregroundColor(.secondary)
                                )
                        }
                        .fade(duration: 0.25)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 56, height: 56)
                }

                Circle()
                    .fill(Color.green)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(Color(.secondarySystemGroupedBackground), lineWidth: 2)
                    )
                    .opacity(0)
            }
        }

        // MARK: - Message Content View
        private var messageContentView: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(conversation.name ?? conversation.username ?? "Unknown")
                            .fontStyle(size: 16, weight: hasUnreadMessages ? .semibold : .medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(messagePreview)
                            .fontStyle(size: 14, weight: .light)
                            .lineLimit(2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 10) {
                        // Replace static Text with dynamic TimeAgoText
                        if let createdAt = conversation.createdAt {
                            TimeAgoText(utcString: createdAt)
                                .fontStyle(size: 12, weight: .regular)
                                .foregroundColor(.secondary)
                        } else {
                            Text("")
                        }

                        HStack(spacing: 15) {
                            if let unreadCount = conversation.unreadCount, unreadCount > 0 {
                                unreadBadge(count: unreadCount)
                            }

                            if conversation.isMuted ?? false {
                                Image(systemName: "speaker.slash")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }

        // MARK: - Unread Badge
        private func unreadBadge(count: Int) -> some View {
            ZStack {
                Circle()
                    .fill(ThemeManager.gradientNewPinkBackground)
                    .frame(
                        width: max(20, CGFloat(count > 9 ? 26 : 20)),
                        height: 20
                    )

                Text(count > 99 ? "99+" : "\(count)")
                    .fontStyle(size: 11, weight: .bold)
                    .foregroundColor(.white)
            }
        }
    }
}
