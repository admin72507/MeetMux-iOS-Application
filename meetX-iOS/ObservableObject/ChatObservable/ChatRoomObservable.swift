//
//  ChatRoomObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 08-07-2025.
//

import SwiftUI
import Combine
import PhotosUI

// MARK: - Media Item Model
struct MediaItem: Identifiable {
    let id: UUID
    let url: URL
    let isVideo: Bool
    let thumbnailURL: URL?
}

// MARK: - ChatRoomViewModel
final class ChatRoomViewModel: ObservableObject {
    // MARK: - Dependencies
    private let userDataManager = UserDataManager.shared
    private let helper = HelperFunctions()
    private let pageLimit = 10
    private var cancellables = Set<AnyCancellable>()
    private var typingTimer: Timer?
    private(set) var socketClient: SocketFeedClient?

    // MARK: - Public State
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var replyContext: ChatMessage?
    @Published var selectedMessage: ChatMessage?
    @Published var showingMessageOptions = false
    @Published var editingMessage: ChatMessage?
    @Published var isEditing = false
    @Published var typingUsers: [String] = []
    @Published var isOtherUserTyping = false
    @Published var selectedMedia: [MediaItem] = []
    @Published var selectedPhotoItems: [PhotosPickerItem] = []
    @Published var selectedVideoItems: [PhotosPickerItem] = []
    @Published var showingImagePicker = false
    @Published var showingCamera = false
    @Published var showingVideoPicker = false
    @Published var selectedConversation: RecentChat?
    @Published var sendingState: DeveloperConstants.MessageSendingState = .idle
    @Published var pendingMessage = ""
    @Published var pendingMessageId: String?
    @Published var errorToast = false
    @Published var errorMessage: String?
    @Published var showLoadOlderButton: Bool = false
    @Published var isManuallyLoadingMore: Bool = false

    // MARK: - Private State
    private var currentPage = 1
    private var canLoadMore = true
    private var isCurrentlyTyping = false
    private var pendingEdits = [String: String]()
    private var pendingDeletes = Set<String>()

    var currentUserId: String { userDataManager.getSecureUserData().userId ?? "" }
    let receivedId: String
    let helperFunctions = HelperFunctions()

    // MARK: - Init
    init(receivedId: String) {
        self.receivedId = receivedId
        setupSocketClient()
        bindError()
    }

    deinit {
      //  socketClient?.removeMessageListeners()
      //  socketClient?.removeTypingListeners()
        typingTimer?.invalidate()
    }

    // MARK: - Socket Setup & Bindings
    private func setupSocketClient() {
        socketClient = SwiftInjectDI.shared.resolve(SocketFeedClient.self) ?? SocketFeedClient()

        loadInitialMessages()

        socketClient?.setupMessageListeners(
            onNewMessage: handleNewMessage,
            onMessageDelete: handleMessageDelete
        )

        socketClient?.setupTypingListeners(
            onUserTyping: handleUserTyping,
            onUserStopTyping: handleUserStopTyping
        )
    }

    private func bindError() {
        $errorMessage.compactMap { $0 }
            .sink { [weak self] _ in self?.errorToast.toggle() }
            .store(in: &cancellables)
    }

    // MARK: - Message Handling
    private func handleNewMessage(_ message: ChatMessage) {
        DispatchQueue.main.async {
            self.messages.append(message)
        }
    }

    private func handleMessageDelete(_ messageId: String) {
        DispatchQueue.main.async {
            self.messages.removeAll { $0.id == messageId }
        }
    }

    // MARK: - Typing
    private func handleUserTyping(_ userIds: [String]) {
        DispatchQueue.main.async {
            self.typingUsers = userIds
            self.isOtherUserTyping = userIds.contains { $0 != self.currentUserId }
        }
    }

    private func handleUserStopTyping(_ userIds: [String]) {
        DispatchQueue.main.async {
            self.typingUsers.removeAll { userIds.contains($0) }
            self.isOtherUserTyping = false
        }
    }

    func startTyping() {
        guard !isCurrentlyTyping else { return }
        isCurrentlyTyping = true
        socketClient?.emitTypingStart(receiverId: selectedConversation?.receiverId ?? "")
        resetTypingTimer()
    }

    func stopTyping() {
        guard isCurrentlyTyping else { return }
        isCurrentlyTyping = false
        typingTimer?.invalidate()
        socketClient?.emitTypingStop(receiverId: selectedConversation?.receiverId ?? "")
    }

    func resetTypingTimer() {
        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.stopTyping()
        }
    }

    // MARK: - Sending Messages
    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, sendingState != .sending else { return }

        sendingState = .sending
        pendingMessage = trimmed
        pendingMessageId = UUID().uuidString

        let optimistic = ChatMessage.optimistic(text: trimmed, id: pendingMessageId!, senderId: currentUserId, receiverId: selectedConversation?.receiverId)
        messages.append(optimistic)

        socketClient?
            .emitSendMessage(message: trimmed, receiverId: selectedConversation?.receiverId ?? "", mediaUrl: "") { [weak self] result in
                self?.handleSendResult(result, optimisticId: optimistic.id ?? "")
            }

        stopTyping()
        clearReplyContext()
    }

    private func handleSendResult(_ result: Result<ChatMessage, Error>, optimisticId: String) {
        DispatchQueue.main.async {
            switch result {
                case .success(let message):
                    self.replaceMessage(withId: optimisticId, new: message)
                    self.sendingState = .sent
                    self.pendingMessage = ""
                    self.pendingMessageId = nil
                case .failure(let error):
                    self.sendingState = .failed(error)
                    self.errorMessage = "Failed to send message: \(error.localizedDescription)"
            }
        }
    }

    func retryPendingMessage() {
        guard case .failed = sendingState, !pendingMessage.isEmpty else { return }
        messages.removeAll { $0.id == pendingMessageId }
        sendMessage(pendingMessage)
    }

    func cancelPendingMessage() {
        messages.removeAll { $0.id == pendingMessageId }
        sendingState = .idle
        pendingMessage = ""
        pendingMessageId = nil
    }

    // MARK: - Editing
    func editMessage(_ message: ChatMessage, newText: String) {
        guard let id = message.id, let receiver = message.receiverId else { return }
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        pendingEdits[id] = message.messageText
        updateMessage(id: id, text: trimmed)
        clearEditingState()

        var didRespond = false
        socketClient?.emitEditMessage(receiverId: receiver, messageId: id, newText: trimmed) { [weak self] result in
            didRespond = true
            switch result {
                case .success(let res):
                    if !res.isSuccess { self?.revertEdit(for: id) }
                case .failure:
                    self?.revertEdit(for: id)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if !didRespond {
                self.revertEdit(for: id)
            }
        }
    }

    private func revertEdit(for id: String) {
        if let original = pendingEdits[id] {
            updateMessage(id: id, text: original)
            pendingEdits.removeValue(forKey: id)
            errorMessage = "Failed to edit message"
        }
    }

    // MARK: - Deletion
    func deleteMessage(_ message: ChatMessage) {
        guard let id = message.id, let receiver = message.receiverId else { return }

        pendingDeletes.insert(id)
        markMessageAsDeleted(id: id)

        var didRespond = false
        socketClient?.emitDeleteMessage(messageId: id, receiverId: receiver) { [weak self] result in
            didRespond = true
            if case .failure = result {
                self?.revertDelete(for: id)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if !didRespond {
                self.revertDelete(for: id)
            }
        }
    }

    private func revertDelete(for id: String) {
        if pendingDeletes.contains(id),
           let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index].deletedAt = nil
            pendingDeletes.remove(id)
            errorMessage = "Failed to delete message"
        }
    }

    // MARK: - Helpers
    private func updateMessage(id: String, text: String) {
        if let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index].messageText = text
        }
    }

    private func replaceMessage(withId id: String, new message: ChatMessage) {
        if let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index] = message
        }
    }

    private func markMessageAsDeleted(id: String) {
        if let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index].deletedAt = ISO8601DateFormatter().string(from: .now)
            messages[index].messageText = "Message deleted"
        }
    }

    // MARK: - Load Initial Messages
    func loadInitialMessages() {

        makePrivateRoomSocketCall(
            receiverId: receivedId,
            completion: { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    switch result {
                        case .success(let chat):
                            self.selectedConversation = chat

                            let initialMessages = chat.messages?.sortedChronologically() ?? []
                            self.messages = initialMessages
                            self.markMessagesAsReadIfNeeded()

//                            if initialMessages.count == self.pageLimit {
//                                self.currentPage = 1
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                                    self.silentlyLoadOlderMessages()
//                                }
//                            } else {
//                                self.canLoadMore = false
//                            }

                            if chat.totalMessages ?? 0 > 10 {
                                self.showLoadOlderButton = true
                                self.canLoadMore = true
                            }else {
                                self.showLoadOlderButton = false
                                self.canLoadMore = false
                            }

                        case .failure:
                            self.errorMessage = "Failed to join chat room"
                    }
                }
            })
    }

    private func makePrivateRoomSocketCall(receiverId: String, completion: @escaping (Result<RecentChat, Error>) -> Void) {
        socketClient?.emitMakeRoomPrivate(receiverId: receiverId, completion: completion)
    }

    private func markMessagesAsReadIfNeeded() {
        guard let conversation = selectedConversation else { return }
        socketClient?.emitMarkAllMessagesAsRead(
            senderId: currentUserId,
            receiverId: conversation.receiverId ?? ""
        )
    }

    // MARK: - Misc
    func clearReplyContext() { replyContext = nil }
    func clearEditingState() { editingMessage = nil; isEditing = false }
    func showMessageOptions(for message: ChatMessage) { selectedMessage = message; showingMessageOptions = true }
    func hideMessageOptions() { selectedMessage = nil; showingMessageOptions = false }

    // MARK: - MessageView Extensions
    var sortedMessages: [ChatMessage] {
        messages.sorted {
            guard let d1 = helperFunctions.parseMessageDate($0.createdAt),
                  let d2 = helperFunctions.parseMessageDate($1.createdAt) else { return false }
            return d1 < d2
        }
    }

    var groupedMessagesByDate: [(String, [ChatMessage])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current

        let grouped = Dictionary(grouping: sortedMessages) { message in
            guard let date = helperFunctions.parseMessageDate(message.createdAt) else {
                return "Invalid"
            }
            return formatter.string(from: date)
        }

        // Return as array to preserve order
        return grouped
            .map { (key: $0.key, value: $0.value) }
            .sorted { $0.key < $1.key }
    }

}

// MARK: - Helpers
extension ChatMessage {
    static func optimistic(text: String, id: String, senderId: String, receiverId: String?) -> ChatMessage {
        let now = ISO8601DateFormatter().string(from: .now)
        return ChatMessage(
            id: id,
            messageText: text,
            messageType: "text",
            mediaUrl: nil,
            senderId: senderId,
            receiverId: receiverId,
            roomId: nil,
            isMessageRead: false,
            deletedAt: nil,
            createdAt: now,
            updatedAt: now
        )
    }
}

extension Array where Element == ChatMessage {
    func sortedChronologically() -> [ChatMessage] {
        sorted {
            guard let d1 = ISO8601DateFormatter().date(from: $0.createdAt ?? ""),
                  let d2 = ISO8601DateFormatter().date(from: $1.createdAt ?? "") else { return false }
            return d1 < d2
        }
    }
}

// MARK: - Extension for load old conversation
extension ChatRoomViewModel {

    // MARK: - Pagination and Loading
    func loadMoreMessages(completion: (() -> Void)? = nil) {
        guard canLoadMore, !isLoadingMore else {
            completion?()
            return
        }

        isLoadingMore = true
        isManuallyLoadingMore = true
        currentPage += 1

        loadChatMessages(isSilentLoad: false) {
            self.isLoadingMore = false
            self.isManuallyLoadingMore = false
            self.showLoadOlderButton = self.canLoadMore
            completion?()
        }
    }

    func refreshMessages() async {
        currentPage = 1
        canLoadMore = true

        await MainActor.run {
            loadInitialMessages()
            loadChatMessages()
        }
    }

    private func loadChatMessages(isSilentLoad: Bool = false, completion: (() -> Void)? = nil) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            self.errorMessage = "Failed to initialize API service"
            self.isLoadingMore = false
            completion?()
            return
        }

        guard let receiverId = selectedConversation?.receiverId else {
            self.errorMessage = "Invalid receiver ID"
            self.isLoadingMore = false
            completion?()
            return
        }

        let urlString = URLBuilderConstants.URLBuilder(type: .loadMoreMessages)
        let queryParams: [String: String] = [
            "receiverId": receiverId,
            "page": "\(currentPage)",
            "limit": "30"
        ]

        if !isSilentLoad {
            print("🔄 Loading messages - Page: \(currentPage)")
        }

        let publisher: AnyPublisher<ChatHistoryResponse, APIError> = apiService.genericPublisher(
            fromURLString: urlString,
            queryParameters: queryParams
        )

        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                guard let self = self else { return }
                if !isSilentLoad {
                    Loader.shared.stopLoading()
                }
                self.isLoadingMore = false
                completion?()

                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                    print("❌ Failed to load chat messages: \(error)")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                if !isSilentLoad {
                    Loader.shared.stopLoading()
                }
                self.handleChatHistoryResponse(response, isSilentLoad: isSilentLoad)
                completion?()
            })
            .store(in: &cancellables)
    }

    private func handleChatHistoryResponse(_ response: ChatHistoryResponse, isSilentLoad: Bool = false) {
        guard let newMessages = response.messages else {
            print("⚠️ No messages in response")
            canLoadMore = false
            return
        }

        let convertedMessages = newMessages.compactMap { apiMessage in
            convertApiMessageToLocalMessage(apiMessage)
        }.sorted { msg1, msg2 in
            guard let date1 = parseDate(msg1.createdAt),
                  let date2 = parseDate(msg2.createdAt) else {
                return false
            }
            return date1 < date2
        }

        if currentPage == 1 && !isSilentLoad {
            // First user-initiated page - replace all messages
            self.messages = convertedMessages
        } else {
            // Subsequent pages - prepend older messages
            let existingIds = Set(self.messages.compactMap { $0.id })
            let newUniqueMessages = convertedMessages.filter { message in
                !existingIds.contains(message.id ?? "")
            }

            // Prepend older messages to the beginning
            self.messages = newUniqueMessages + self.messages
        }

        // Update pagination state based on response
        // If we received fewer messages than the page limit, we've reached the end
        canLoadMore = newMessages.count >= pageLimit

        // Also check total count if available
        if let totalCount = response.totalCount {
            let totalPages = Int(ceil(Double(totalCount) / Double(pageLimit)))
            canLoadMore = canLoadMore && currentPage < totalPages
        }

        // Update showLoadOlderButton based on canLoadMore
        showLoadOlderButton = canLoadMore

        if !canLoadMore {
            print("🏁 No more messages to load")
        }
    }

    // MARK: - Helper Methods
    private func convertApiMessageToLocalMessage(_ apiMessage: ChatMessage) -> ChatMessage {
        return apiMessage
    }

    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }

        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }

    // MARK: - Computed Properties
    var canLoadMoreMessages: Bool {
        return canLoadMore && !isLoadingMore
    }
}
