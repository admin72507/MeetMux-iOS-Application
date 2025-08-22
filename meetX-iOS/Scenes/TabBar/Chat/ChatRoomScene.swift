//
//  ChatRoomMessageRow.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 12-07-2025.
//

import SwiftUI
import Combine
import Foundation
import AudioToolbox
import Kingfisher

struct ChatRoomScene: View {
    @StateObject var viewModel: ChatRoomViewModel
    @Environment(\.dismiss) private var dismiss
    @State var messageText = ""
    @FocusState var isTextFieldFocused: Bool
    @State var imageLoadFailed = false
    @State private var showingMessageOptionsOverlay = false
    @State private var selectedMessageForOptions: ChatMessage?
    @State private var messagePosition: CGPoint = .zero
    @State private var messageSize: CGSize = .zero
    @Environment(\.colorScheme) private var colorScheme

    let receiverId: String
    let profilePicture: String

    init(
        receiverId: String,
        profilePicture: String
    ) {
        self.receiverId = receiverId
        self.profilePicture = profilePicture
        self._viewModel = StateObject(wrappedValue: ChatRoomViewModel(
            receivedId: receiverId
        ))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                ChatRoomHeaderView(
                    name: viewModel.selectedConversation?.name ?? "Unknown",
                    username: viewModel.selectedConversation?.username ?? "",
                    profilePicUrl: profilePicture,
                    onBack: { dismiss() },
                    lastSeenText: viewModel.isOtherUserTyping ? "typing..." : "Last seen recently"
                )

                if viewModel.messages.isEmpty {
                    // Show no messages view
                    NoChatView()
                } else {
                    // Messages
                    MessagesView(
                        viewModel: viewModel,
                        selectedMessageForOptions: $selectedMessageForOptions,
                        messagePosition: $messagePosition,
                        showingMessageOptionsOverlay: $showingMessageOptionsOverlay,
                        messageSize: $messageSize,
                        isTextFieldFocused: $isTextFieldFocused
                    )
                }

                // Typing indicator
//                if viewModel.isOtherUserTyping {
//                    TypingIndicatorView()
//                        .id("typing_indicator")
//                        .transition(.asymmetric(
//                            insertion: .move(edge: .bottom).combined(with: .opacity),
//                            removal: .move(edge: .bottom).combined(with: .opacity)
//                        ))
//                }

                // Input field
                ChatInputField(
                    messageText: $messageText,
                    onSendMessage: { message in
                        if viewModel.isEditing, let editingMessage = viewModel.editingMessage {
                            viewModel.editMessage(editingMessage, newText: message)
                        } else {
                            viewModel.sendMessage(message)
                        }
                        provideSendMessageFeedback()
                    },
                    onEditMessage: { messageId, newText in
                        if let message = viewModel.editingMessage {
                            viewModel.editMessage(message, newText: newText)
                        }
                    },
                    onCancelEditing: {
                        cancelEditing()
                    },
                    onClearReply: {
                        viewModel.clearReplyContext()
                    },
                    onTextChange: {
                        handleTextChange()
                    },
                    onPlusButtonTap: {
                        // Plus button functionality commented out
                        // print("Plus button tapped")
                    },
                    onMicButtonTap: {
                        // Mic button functionality commented out
                        // print("Microphone button tapped")
                    },
                    onFocusChange: { focused in
                        if focused {
                            // Enhanced keyboard handling - scroll to bottom when focused
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                scrollToBottomAnimated()
                            }
                        }
                    }
                )
                .focused($isTextFieldFocused)
                .background(Color(.systemBackground))
                .onChange(of: isTextFieldFocused) { _, isFocused in
                    if isFocused {
                        // Additional scroll to bottom when text field gains focus
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            scrollToBottomAnimated()
                        }
                    }
                }
            }
            .blur(radius: showingMessageOptionsOverlay ? 8 : 0)
            .animation(.easeInOut(duration: 0.3), value: showingMessageOptionsOverlay)

            // Enhanced message options overlay
            if showingMessageOptionsOverlay {
                messageOptionsOverlay
            }
        }
        .toast(isPresenting: $viewModel.errorToast) {
            HelperFunctions()
                .apiErrorToastCenter(
                    "Chat Room!!",
                    viewModel.errorMessage ?? Constants.unknownError
                )
        }
        .onTapGesture {
            if isTextFieldFocused {
                isTextFieldFocused = false
            }
            if showingMessageOptionsOverlay {
                hideMessageOptions()
            }
        }
        .onDisappear {
            viewModel.makePrivateRoomSocketCallOff(receiverId: receiverId)
        }
    }

    @ViewBuilder
    func fallbackInitialCircle(for name: String) -> some View {
        let firstLetter = String(name.prefix(1)).uppercased()

        ZStack {
            Circle()
                .fill(ThemeManager.gradientNewPinkBackground)

            Text(firstLetter)
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 40, height: 40)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    // MARK: - Enhanced Message Options Overlay
    private var messageOptionsOverlay: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        hideMessageOptions()
                    }
                }

            if let message = selectedMessageForOptions {
                VStack(spacing: 16) {
                    // Message preview - positioned based on actual message position
                    HStack {
                        if message.senderId != viewModel.currentUserId {
                            // Receiver message
                            VStack(alignment: .leading, spacing: 4) {
                                Text(message.deletedAt != nil ? "Message Deleted" : (message.messageText ?? ""))
                                    .fontStyle(size: 14, weight: .regular)
                                    .italic(message.deletedAt != nil)
                                    .foregroundColor(
                                        message.deletedAt != nil ?
                                            .secondary :
                                            receiverForegroundColor
                                    )
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        message.deletedAt != nil ?
                                        AnyShapeStyle(Color(.systemGray4)) :
                                            AnyShapeStyle(receiverBackgroundColor)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(
                                                message.deletedAt == nil ? receiverBorderColor : Color.clear,
                                                lineWidth: 1
                                            )
                                    )
                                    .opacity(message.deletedAt != nil ? 0.6 : 1.0)
                            }
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)

                            Spacer()
                        } else {
                            // Sender message
                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(message.deletedAt != nil ? "Message Deleted" : (message.messageText ?? ""))
                                    .font(.system(size: 14, weight: .regular, design: .default))
                                    .italic(message.deletedAt != nil)
                                    .foregroundColor(
                                        message.deletedAt != nil ? .secondary : .white
                                    )
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        message.deletedAt != nil ?
                                        AnyShapeStyle(Color(.systemGray4)) :
                                            AnyShapeStyle(ThemeManager.gradientNewPinkBackground)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                    .opacity(message.deletedAt != nil ? 0.6 : 1.0)
                            }
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Options menu - positioned below the message
                    HStack {
                        if message.senderId != viewModel.currentUserId {
                            VStack(spacing: 0) {
                                optionsMenu(for: message)
                            }
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.6, alignment: .leading)
                            Spacer()
                        } else {
                            Spacer()
                            VStack(spacing: 0) {
                                optionsMenu(for: message)
                            }
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.6, alignment: .trailing)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .position(
                    x: UIScreen.main.bounds.width / 2,
                    y: max(
                        UIScreen.main.bounds.height * 0.3,
                        min(
                            messagePosition.y,
                            UIScreen.main.bounds.height * 0.7
                        )
                    )
                )
                .scaleEffect(showingMessageOptionsOverlay ? 1 : 0.8)
                .opacity(showingMessageOptionsOverlay ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingMessageOptionsOverlay)
            }
        }
    }

    private var receiverBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray2) : Color.white
    }

    private var receiverForegroundColor: Color {
        colorScheme == .dark ? Color.white : ThemeManager.foregroundColor
    }

    private var receiverBorderColor: Color {
        colorScheme == .dark ? Color.clear : Color(.systemGray4)
    }

    @ViewBuilder
    private func optionsMenu(for message: ChatMessage) -> some View {
        VStack(spacing: 0) {
            // Edit
            if message.senderId == viewModel.currentUserId && message.deletedAt == nil {
                MessageOptionButton(
                    icon: "applepencil.and.scribble",
                    title: "Edit",
                    isFirst: true,
                    isLast: false,
                    iconOnRight: true
                ) {
                    withAnimation {
                        hideMessageOptions()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        editMessage(message)
                    }
                }
            }
            
            // Copy
            if message.deletedAt == nil {
                MessageOptionButton(
                    icon: "document.on.document",
                    title: "Copy",
                    isFirst: false,
                    isLast: message.senderId != viewModel.currentUserId,
                    iconOnRight: true
                ) {
                    withAnimation {
                        hideMessageOptions()
                    }
                    copyMessage(message)
                }
            }
            
            // Delete
            if message.senderId == viewModel.currentUserId && message.deletedAt == nil {
                MessageOptionButton(
                    icon: "trash",
                    title: "Delete",
                    isDestructive: true,
                    isFirst: false,
                    isLast: true,
                    iconOnRight: true
                ) {
                    withAnimation {
                        hideMessageOptions()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        deleteMessage(message)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 15)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func scrollToBottomAnimated() {
        // Enhanced fallback scrolling when proxy is not available
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // This will be handled by the ScrollViewReader in messagesView
        }
    }

    private func hideMessageOptions() {
        withAnimation(.easeInOut(duration: 0.25)) {
            showingMessageOptionsOverlay = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            selectedMessageForOptions = nil
            messagePosition = .zero
            messageSize = .zero
        }
    }

    func handleTextChange() {
        if !messageText.isEmpty {
            viewModel.startTyping()
        } else {
            viewModel.stopTyping()
        }
        viewModel.resetTypingTimer()
    }

    private func editMessage(_ message: ChatMessage) {
        viewModel.editingMessage = message
        messageText = message.messageText ?? ""
        viewModel.isEditing = true
        isTextFieldFocused = true
        // Scroll to bottom when editing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            scrollToBottomAnimated()
        }
    }

    private func copyMessage(_ message: ChatMessage) {
        UIPasteboard.general.string = message.messageText
        HapticManager.trigger(.light)
    }

    private func deleteMessage(_ message: ChatMessage) {
        viewModel.deleteMessage(message)
    }

    func cancelEditing() {
        viewModel.isEditing = false
        viewModel.editingMessage = nil
        messageText = ""
        viewModel.clearReplyContext()
    }

    private func provideSendMessageFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .rigid)
        impactFeedback.impactOccurred()
        AudioServicesPlaySystemSound(1004)
    }
}

// MARK: - Message Option Button
struct MessageOptionButton: View {
    let icon: String
    let title: String
    let isDestructive: Bool
    let isFirst: Bool
    let isLast: Bool
    let iconOnRight: Bool
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String,
        title: String,
        isDestructive: Bool = false,
        isFirst: Bool = false,
        isLast: Bool = false,
        iconOnRight: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.isDestructive = isDestructive
        self.isFirst = isFirst
        self.isLast = isLast
        self.iconOnRight = iconOnRight
        self.action = action
    }

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                if !iconOnRight {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isDestructive ? .red : .primary)
                        .frame(width: 20)
                }

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .primary)

                Spacer()

                if iconOnRight {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isDestructive ? .red : .primary)
                        .frame(width: 20)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(isPressed ? Color.primary.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onPressingChanged: { pressing in
            if !pressing {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 0.5)
                .opacity(isLast ? 0 : 1),
            alignment: .bottom
        )
    }
}

// MARK: - Date Separator View
struct DateSeparatorView: View {
    @ObservedObject var viewModel: ChatRoomViewModel
    let date: String

    var body: some View {
        HStack {
//            VStack {
//                Divider()
//            }

            Text(viewModel.helperFunctions.formatDateString(date))
                .fontStyle(size: 12, weight: .semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )

//            VStack {
//                Divider()
//            }
        }
        .padding(.horizontal, 16)
    }
}
