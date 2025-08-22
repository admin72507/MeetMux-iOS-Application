import SwiftUI
import Combine

struct ChatInputField: View {
    @Binding var messageText: String
    @State private var isEditing: Bool = false
    @State private var editingMessage: String? = nil
    @State private var replyContext: String? = nil

    // Callbacks
    var onSendMessage: (String) -> Void
    var onEditMessage: (String, String) -> Void
    var onCancelEditing: () -> Void
    var onClearReply: () -> Void
    var onTextChange: () -> Void
    var onPlusButtonTap: () -> Void
    var onMicButtonTap: () -> Void
    var onFocusChange: (Bool) -> Void

    init(
        messageText: Binding<String>,
        onSendMessage: @escaping (String) -> Void,
        onEditMessage: @escaping (String, String) -> Void = { _, _ in },
        onCancelEditing: @escaping () -> Void = {},
        onClearReply: @escaping () -> Void = {},
        onTextChange: @escaping () -> Void = {},
        onPlusButtonTap: @escaping () -> Void = {},
        onMicButtonTap: @escaping () -> Void = {},
        onFocusChange: @escaping (Bool) -> Void = { _ in }
    ) {
        self._messageText = messageText
        self.onSendMessage = onSendMessage
        self.onEditMessage = onEditMessage
        self.onCancelEditing = onCancelEditing
        self.onClearReply = onClearReply
        self.onTextChange = onTextChange
        self.onPlusButtonTap = onPlusButtonTap
        self.onMicButtonTap = onMicButtonTap
        self.onFocusChange = onFocusChange
    }

    var body: some View {
        VStack(spacing: 0) {
            // Edit indicator
            if isEditing {
                editingIndicator
            }

            // Reply indicator
            if let replyText = replyContext {
                replyIndicator(replyText: replyText)
            }

            // Main input container
            HStack(spacing: 12) {
                // Plus button - COMMENTED OUT
                /*
                 Button(action: onPlusButtonTap) {
                 Image(systemName: "plus")
                 .font(.system(size: 18, weight: .medium))
                 .foregroundColor(.primary)
                 .frame(width: 32, height: 32)
                 .background(Color(.systemGray6))
                 .clipShape(Circle())
                 }
                 */

                // Text input
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .fontStyle(size: 16, weight: .regular)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .lineLimit(1...4)
                    .onChange(of: messageText) { _, _ in
                        onTextChange()
                    }
                    .onSubmit {
                        if canSendMessage {
                            sendMessage()
                        }
                    }

                Button(action: {
                    if canSendMessage {
                        sendMessage()
                    }
                    // Mic functionality commented out
                    // else {
                    //     onMicButtonTap()
                    // }
                }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            canSendMessage
                            ? ThemeManager.gradientNewPinkBackground
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                }
                .disabled(!canSendMessage)
                .animation(.easeInOut(duration: 0.2), value: canSendMessage)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }

    private var editingIndicator: some View {
        HStack {
            Image(systemName: "pencil")
                .font(.system(size: 14))
                .foregroundColor(.blue)

            Text("Edit message")
                .fontStyle(size: 14, weight: .regular)
                .foregroundColor(.blue)

            Spacer()

            Button("Cancel") {
                cancelEditing()
            }
            .font(.system(size: 14))
            .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    private func replyIndicator(replyText: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Replying to")
                    .fontStyle(size: 12, weight: .light)
                    .foregroundColor(ThemeManager.foregroundColor)
                Text(replyText)
                    .fontStyle(size: 14, weight: .semibold)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button("Cancel") {
                clearReplyContext()
            }
            .fontStyle(size: 14, weight: .semibold)
            .foregroundColor(ThemeManager.staticPinkColour)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    private var canSendMessage: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Methods
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }

        if isEditing, let editingMsg = editingMessage {
            onEditMessage(editingMsg, trimmedMessage)
            cancelEditing()
        } else {
            onSendMessage(trimmedMessage)
        }

        messageText = ""
        provideSendFeedback()
    }

    private func cancelEditing() {
        isEditing = false
        editingMessage = nil
        messageText = ""
        onCancelEditing()
    }

    private func clearReplyContext() {
        replyContext = nil
        onClearReply()
    }

    // MARK: - Public Methods
    func startEditing(messageId: String, currentText: String) {
        editingMessage = messageId
        messageText = currentText
        isEditing = true
    }

    func setReplyContext(_ text: String) {
        replyContext = text
    }

    // MARK: - Helper Methods
    private func provideSendFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}
