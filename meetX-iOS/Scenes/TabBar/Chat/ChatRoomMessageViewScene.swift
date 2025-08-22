import SwiftUI
import Combine

struct MessagesView: View {
    @ObservedObject var viewModel: ChatRoomViewModel
    @Binding var selectedMessageForOptions: ChatMessage?
    @Binding var messagePosition: CGPoint
    @Binding var showingMessageOptionsOverlay: Bool
    @Binding var messageSize: CGSize
    @FocusState.Binding var isTextFieldFocused: Bool

    @State private var showScrollToBottom = false
    @State private var scrollOffset: CGFloat = 0.0
    @State private var lastScrollOffset: CGFloat = 0.0
    @State private var isInitialLoad = true
    @State private var savedScrollPosition: String?
    @State private var isLoadingMoreInProgress = false

    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Top loading section
                        Group {
                            if viewModel.isManuallyLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .padding(.vertical, 8)
                                    Spacer()
                                }
                                .id("top_loader")
                            } else if viewModel.showLoadOlderButton {
                                Button(action: {
                                    loadMoreWithScrollPreservation(proxy: proxy)
                                }) {
                                    Text("Load older messages")
                                        .fontStyle(size: 14, weight: .semibold)
                                        .foregroundStyle(
                                            ThemeManager.gradientNewPinkBackground
                                        )
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .id("top_button")
                            } else if viewModel.isLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .padding(.vertical, 6)
                                    Spacer()
                                }
                                .id("top_spinner")
                            }
                        }
                        .id("top_section")

                        messageContent()

                        if viewModel.isOtherUserTyping {
                            TypingIndicatorView()
                        }

                        // Bottom spacer and scroll anchor
                        Color.clear.frame(height: 1).id("bottom_anchor")
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .coordinateSpace(name: "scroll")
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKeyMessageView.self,
                                        value: geometry.frame(in: .named("scroll")).minY)
                    }
                )
                .onPreferenceChange(ScrollOffsetPreferenceKeyMessageView.self) { value in
                    handleScrollOffset(value, proxy: proxy)
                }
                .onReceive(NotificationCenter.default.publisher(for: .scrollToMessage)) { notification in
                    if let id = notification.object as? String {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(id, anchor: .top)
                        }
                    }
                }

                if showScrollToBottom {
                    Button(action: {
                        scrollToBottom(proxy: proxy)
                    }) {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)))
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .onChange(of: viewModel.messages.count) { oldCount, newCount in
                if newCount > oldCount {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
            .onChange(of: viewModel.isLoadingMore) { oldValue, newValue in
                if oldValue && !newValue && isLoadingMoreInProgress {
                    restoreScrollPosition(proxy: proxy)
                    isLoadingMoreInProgress = false
                }
            }
            .onChange(of: isTextFieldFocused) { _,focused in
                if focused {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
            .onAppear {
                setupInitialView(proxy: proxy)
            }
            .onDisappear {
                isInitialLoad = true
            }
        }
    }

    private func handleScrollOffset(_ offset: CGFloat, proxy: ScrollViewProxy) {
        let offsetDifference = offset - lastScrollOffset

        if offsetDifference > 15 &&
            offset > -50 &&
            !viewModel.isLoadingMore &&
            !isLoadingMoreInProgress &&
            viewModel.canLoadMoreMessages &&
            !isInitialLoad {

            print("🔄 Triggering load more at offset: \(offset)")
            loadMoreWithScrollPreservation(proxy: proxy)
        }

        showScrollToBottom = offset < -300
        lastScrollOffset = offset
        scrollOffset = offset
    }

    private func loadMoreWithScrollPreservation(proxy: ScrollViewProxy) {
        guard !isLoadingMoreInProgress else { return }

        if let firstMessage = viewModel.sortedMessages.first {
            savedScrollPosition = firstMessage.id
        }

        isLoadingMoreInProgress = true
        viewModel.loadMoreMessages()
    }

    private func restoreScrollPosition(proxy: ScrollViewProxy) {
        if let savedPosition = savedScrollPosition {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                proxy.scrollTo(savedPosition, anchor: .top)
                savedScrollPosition = nil
            }
        }
    }

    private func setupInitialView(proxy: ScrollViewProxy) {
        if isInitialLoad {
            isInitialLoad = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private func messageContent() -> some View {
        ForEach(Array(viewModel.groupedMessagesByDate.enumerated()), id: \.offset) { index, group in
            let date = group.0
            let messages = group.1

            if date != "Invalid" {
                DateSeparatorView(viewModel: viewModel, date: date)
            }

            ForEach(messages) { message in
                if shouldShowMessage(message) {
                    let isLast = viewModel.sortedMessages.last?.id == message.id
                    messageView(for: message, isLast: isLast)
                }
            }
        }
    }

    private func messageView(for message: ChatMessage, isLast: Bool) -> some View {
        let showRetryOption: Bool = {
            if case .failed = viewModel.sendingState {
                return message.id == viewModel.pendingMessageId
            }
            return false
        }()

        return MessageRowView(
            message: message,
            isFromCurrentUser: message.senderId == viewModel.currentUserId,
            sendingState: viewModel.sendingState,
            onLongPress: { position, size in
                handleMessageLongPress(message: message, position: position, size: size)
            },
            onRetry: { viewModel.retryPendingMessage() },
            isLastMessage: isLast,
            onEdit: {
                viewModel.editingMessage = message
                viewModel.isEditing = true
            },
            onDelete: { viewModel.deleteMessage(message) },
            showRetryOption: showRetryOption
        )
        .id(message.id)
    }

    private func shouldShowMessage(_ message: ChatMessage) -> Bool {
        if message.deletedAt != nil { return true }
        if let text = message.messageText, !text.trimmingCharacters(in: .whitespaces).isEmpty { return true }
        if message.senderId == viewModel.currentUserId,
           (viewModel.sendingState == .sending || viewModel.sendingState == .idle) {
            return true
        }
        return false
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo("bottom_anchor", anchor: .bottom)
        }
    }

    private func handleMessageLongPress(message: ChatMessage, position: CGPoint, size: CGSize) {
        let feedback = UIImpactFeedbackGenerator(style: .heavy)
        feedback.impactOccurred()

        selectedMessageForOptions = message
        let adjustedY = max(150, min(position.y, UIScreen.main.bounds.height - 200))
        messagePosition = CGPoint(x: position.x, y: adjustedY)
        messageSize = size

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showingMessageOptionsOverlay = true
        }
    }
}

// MARK: - ScrollOffsetPreferenceKey
struct ScrollOffsetPreferenceKeyMessageView: PreferenceKey {
    static var defaultValue: CGFloat = 0.0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Notification Name
extension Notification.Name {
    static let scrollToMessage = Notification.Name("scrollToMessage")
}
