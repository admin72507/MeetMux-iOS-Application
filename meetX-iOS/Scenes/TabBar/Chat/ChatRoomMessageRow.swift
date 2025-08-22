//
//  ChatRoomMessageRow.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 12-07-2025.
//

import SwiftUI
import Combine

// MARK: - Enhanced Message Row View
struct MessageRowView: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    let sendingState: DeveloperConstants.MessageSendingState
    let onLongPress: (CGPoint, CGSize) -> Void
    let onRetry: () -> Void
    let isLastMessage: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let showRetryOption: Bool

    @State private var isPressed: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @State private var showTimestamp = false
    @State private var isExpanded = false

    var body: some View {
        messageContent
    }

    private var messageContent: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromCurrentUser {
                Spacer(minLength: UIScreen.main.bounds.width * 0.25)

                VStack(alignment: .trailing, spacing: 4) {
                    messageBubble
                    if showTimestamp || isLastMessage {
                        timestampView
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    messageBubble
                    if showTimestamp || isLastMessage {
                        timestampView
                    }
                }
                Spacer(minLength: UIScreen.main.bounds.width * 0.25)
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showTimestamp.toggle()
            }
        }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
               // onDoubleTap()
            }
        )
    }

    // Add this preference key structure before your ChatRoomScene view
    struct BubblePositionPreferenceKey: PreferenceKey {
        static var defaultValue: CGRect = .zero
        static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
            value = nextValue()
        }
    }

    // Add this validation in MessageRowView's messageBubble computed property
    private var messageBubble: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
            // Show bubble if message has text OR if it's a sending/pending message OR if it's deleted
            let shouldShowBubble = {
                // Always show deleted messages
                if message.deletedAt != nil {
                    return true
                }

                // Show if message has valid text content
                if let messageText = message.messageText,
                   !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return true
                }

                // Show if message is currently being sent (for sender side)
                if isFromCurrentUser && (
                    sendingState == .sending || sendingState == .idle || showRetryOption
                ) {
                    return true
                }

                return false
            }()

            if shouldShowBubble {
                // Main bubble with retry button
                HStack(spacing: 8) {
                    if isFromCurrentUser {
                        // Retry button for failed messages (left side for sender)
                        if showRetryOption {
                            retryButton
                        }

                        // Message bubble
                        messageBubbleContent
                    } else {
                        // Message bubble
                        messageBubbleContent

                        // Retry button for failed messages (right side for receiver - shouldn't happen)
                        if showRetryOption {
                            retryButton
                        }
                    }
                }
            }
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isFromCurrentUser ? .trailing : .leading)
        .padding(isFromCurrentUser ? .leading : .trailing, 50)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        ))
    }

    private var messageBubbleContent: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 8) {
            // Determine the display text
            let displayText: String = {
                if message.deletedAt != nil {
                    return "Message deleted successfully!"
                } else if let messageText = message.messageText,
                          !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return messageText
                } else if isFromCurrentUser && (sendingState == .sending || sendingState == .idle) {
                    return "Sending..."
                } else {
                    return "Message"
                }
            }()

            let isLongText = displayText.count > 500
            let displayedText = isLongText && !isExpanded ?
            String(displayText.prefix(500)) + "..." : displayText

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(displayedText)
                    .fontStyle(
                        size: 14,
                        weight: message.deletedAt != nil ? .regular : .medium
                    )
                    .italic(message.deletedAt != nil)
                    .foregroundColor(deletedMessageColor)
                    .multilineTextAlignment(.leading)

                // Read More/Less button
                if isLongText {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Text(isExpanded ? "Read Less" : "Read More")
                            .fontStyle(size: 14, weight: .semibold)
                            .foregroundColor(
                                ThemeManager.staticPurpleColour
                            )
                            .padding(.top, 2)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(bubbleBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .opacity(message.deletedAt != nil ? 0.7 : 1.0)
            .overlay(bubbleOverlay)
            .shadow(
                color: shadowColor,
                radius: message.deletedAt != nil ? 2 : 6,
                x: 0,
                y: message.deletedAt != nil ? 1 : 3
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onLongPressGesture(
                minimumDuration: 0.5,
                maximumDistance: 10,
                perform: handleLongPress,
                onPressingChanged: { pressing in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = pressing
                    }
                }
            )
        }
    }

    private var retryButton: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            // Call retry action
            onRetry()
        }) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.red)
                .background(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                )
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }

    private var deletedMessageColor: Color {
        if message.deletedAt != nil {
            return Color(.systemGray)
        }

        if isFromCurrentUser {
            return .white
        } else {
            return Color.primary
        }
    }

    private var bubbleBackground: some ShapeStyle {
        if message.deletedAt != nil {
            return AnyShapeStyle(Color(.systemGray5))
        }

        if isFromCurrentUser {
            // Sender bubble with gradient
            return AnyShapeStyle(
                ThemeManager.gradientNewPinkBackground
            )
        } else {
            // Receiver bubble - adapts to color scheme
            return AnyShapeStyle(receiverBubbleColor)
        }
    }

    private var receiverBubbleColor: Color {
        colorScheme == .dark
        ? Color(.systemGray6)
        : .white
    }

    private var bubbleOverlay: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                strokeColor,
                lineWidth: strokeWidth
            )
    }

    private var strokeColor: Color {
        if message.deletedAt != nil {
            return Color.clear
        }

        if isFromCurrentUser {
            return Color.clear
        } else {
            return Color(.systemGray4).opacity(0.3)
        }
    }

    private var strokeWidth: CGFloat {
        return (!isFromCurrentUser && message.deletedAt == nil) ? 0.5 : 0
    }

    private var shadowColor: Color {
        if message.deletedAt != nil {
            return Color.black.opacity(0.05)
        }

        return Color.black.opacity(
            colorScheme == .dark ? 0.3 : 0.15
        )
    }

    private func handleLongPress() {
        guard message.deletedAt == nil else {
            print("Long press on deleted message - no overlay")
            return
        }

        // Add haptic feedback
        HapticManager.trigger(.medium)

        // Calculate bubble position more accurately
        let bubbleX = isFromCurrentUser ?
        UIScreen.main.bounds.width * 0.7 :
        UIScreen.main.bounds.width * 0.3
        let bubbleY = UIScreen.main.bounds.height / 2

        let position = CGPoint(x: bubbleX, y: bubbleY)
        let estimatedSize = CGSize(width: 220, height: 60)

        onLongPress(position, estimatedSize)
    }

    private var timestampView: some View {
        if let createdAt = message.createdAt,
           let dataSet = HelperFunctions.convertUTCToISTAndCalculateDifference(utcString: createdAt) {
            return AnyView(
                HStack(spacing: 4) {
                    Text(dataSet.time.uppercased())
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if isFromCurrentUser {
                        Image(systemName: message.isMessageRead == true ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                    .padding(.horizontal, 4)
                    .transition(.opacity)
            )
        }
        return AnyView(EmptyView())
    }
}
