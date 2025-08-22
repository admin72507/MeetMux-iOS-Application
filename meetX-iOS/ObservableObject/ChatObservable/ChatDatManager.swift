//
//  ChatDatManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 16-07-2025.
//

import Foundation
import Combine

final class ChatDataManager: ObservableObject {
    static let shared = ChatDataManager()

    // MARK: - Published Properties
    @Published var recentChats: [RecentChat] = []
    @Published var allUsers: [UserData] = []
    @Published var isLoading = false
    @Published var lastUpdateTime: Date = Date()

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var socketManager = SocketIOManager.shared
    private var isSocketListening = false
    private var currentPage = 1
    private var totalPages = 1
    private let pageLimit = DeveloperConstants.Network.pageLimit
    private var canLoadMore = true

    private init() {
        setupSocketListeners()
    }

    // MARK: - Socket Management
    private func setupSocketListeners() {
        guard !isSocketListening else { return }
        isSocketListening = true

        // Listen for new messages globally
        socketManager.onlistenEvent(event: "newMessage") { [weak self] data, _ in
            DispatchQueue.main.async {
                self?.handleNewMessage(data: data)
            }
        }

        // Listen for conversation updates
        socketManager.onlistenEvent(event: "conversationUpdate") { [weak self] data, _ in
            DispatchQueue.main.async {
                self?.handleConversationUpdate(data: data)
            }
        }

        // Listen for user status changes
        socketManager.onlistenEvent(event: "userStatusUpdate") { [weak self] data, _ in
            DispatchQueue.main.async {
                self?.handleUserStatusUpdate(data: data)
            }
        }

        // Listen for message read receipts
        socketManager.onlistenEvent(event: "messageRead") { [weak self] data, _ in
            DispatchQueue.main.async {
                self?.handleMessageRead(data: data)
            }
        }
    }

    // MARK: - Data Loading
    func loadInitialData() {
        guard !isLoading else { return }
        isLoading = true
        resetPagination()
        emitGetConversationsAndUsers()
    }

    func refreshData() {
        resetPagination()
        emitGetConversationsAndUsers()
    }

    func loadMoreConversations() {
        guard canLoadMore && !isLoading && currentPage < totalPages else { return }
        currentPage += 1
        emitGetConversationsAndUsers()
    }

    private func emitGetConversationsAndUsers() {
        let data: [String: Any] = [
            "page": currentPage,
            "limit": pageLimit
        ]

        socketManager.emitWithAck(
            event: "getUserOnlineAndPastConversationList",
            data: data,
            decodeTo: CombinedChatResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleCombinedResponse(result)
            }
        }
    }

    private func resetPagination() {
        currentPage = 1
        canLoadMore = true
        if currentPage == 1 {
            recentChats.removeAll()
            allUsers.removeAll()
        }
    }

    // MARK: - Data Handlers
    private func handleCombinedResponse(_ result: Result<CombinedChatResponse, Error>) {
        isLoading = false

        switch result {
            case .success(let response):
                // Update pagination info
                if let totalCount = response.totalCount, let limit = response.limit {
                    totalPages = max(1, Int(ceil(Double(totalCount) / Double(limit))))
                    canLoadMore = currentPage < totalPages
                }

                // Update users
                if let users = response.users {
                    if currentPage == 1 {
                        allUsers = users.sorted { user1, user2 in
                            let active1 = user1.isUserActive ?? false
                            let active2 = user2.isUserActive ?? false
                            if active1 != active2 {
                                return active1 && !active2
                            }
                            return (user1.name ?? user1.username ?? "") < (user2.name ?? user2.username ?? "")
                        }
                    } else {
                        for user in users {
                            if !allUsers.contains(where: { $0.userId == user.userId }) {
                                allUsers.append(user)
                            }
                        }
                    }
                }

                // Update conversations
                if let conversations = response.recentChats {
                    if currentPage == 1 {
                        recentChats = conversations
                    } else {
                        for chat in conversations {
                            if !recentChats.contains(where: { $0.conversationId == chat.conversationId }) {
                                recentChats.append(chat)
                            }
                        }
                    }
                }

                lastUpdateTime = Date()

            case .failure(let error):
                print("❌ Failed to load chat data: \(error)")
        }
    }

    private func handleNewMessage(data: [Any]) {
        guard let firstItem = data.first,
              let jsonData = try? JSONSerialization.data(withJSONObject: firstItem),
              let newMessage = try? JSONDecoder().decode(RecentChat.self, from: jsonData) else {
            return
        }

        updateOrInsertConversation(newMessage)
    }

    private func handleConversationUpdate(data: [Any]) {
        guard let firstItem = data.first,
              let jsonData = try? JSONSerialization.data(withJSONObject: firstItem),
              let updatedConversation = try? JSONDecoder().decode(RecentChat.self, from: jsonData) else {
            return
        }

        updateOrInsertConversation(updatedConversation)
    }

    private func handleUserStatusUpdate(data: [Any]) {
        guard let firstItem = data.first,
              let jsonData = try? JSONSerialization.data(withJSONObject: firstItem),
              let userUpdate = try? JSONDecoder().decode(UserStatusUpdate.self, from: jsonData) else {
            return
        }

        // Update user status in allUsers array
        if let index = allUsers.firstIndex(where: { $0.userId == userUpdate.userId }) {
            allUsers[index].isUserActive = userUpdate.isActive
        }
    }

    private func handleMessageRead(data: [Any]) {
        guard let firstItem = data.first,
              let jsonData = try? JSONSerialization.data(withJSONObject: firstItem),
              let readReceipt = try? JSONDecoder().decode(MessageReadReceipt.self, from: jsonData) else {
            return
        }

        // Update unread count for conversation
        if let index = recentChats.firstIndex(where: { $0.conversationId == readReceipt.conversationId }) {
            recentChats[index].unreadCount = readReceipt.unreadCount
        }
    }

    // MARK: - Helper Methods
    private func updateOrInsertConversation(_ conversation: RecentChat) {
        if let index = recentChats.firstIndex(where: { $0.conversationId == conversation.conversationId }) {
            // Update existing conversation
            recentChats[index] = conversation
            // Move to top if it's a new message
            if index != 0 {
                let updated = recentChats.remove(at: index)
                recentChats.insert(updated, at: 0)
            }
        } else {
            // Insert new conversation at the top
            recentChats.insert(conversation, at: 0)
        }

        lastUpdateTime = Date()
    }

    // MARK: - Public Methods
    func markConversationAsRead(conversationId: String) {
        if let index = recentChats.firstIndex(where: { $0.conversationId == conversationId }) {
            recentChats[index].unreadCount = 0
        }
    }

    func updateLastMessage(conversationId: String, message: ChatMessage) {
        if let index = recentChats.firstIndex(where: { $0.conversationId == conversationId }) {
            recentChats[index].messages = [message]
            recentChats[index].createdAt = message.createdAt

            // Move to top
            if index != 0 {
                let updated = recentChats.remove(at: index)
                recentChats.insert(updated, at: 0)
            }
        }
    }

    func getConversation(byId conversationId: String) -> RecentChat? {
        return recentChats.first { $0.conversationId == conversationId }
    }

    var totalUnreadCount: Int {
        return recentChats.compactMap { $0.unreadCount }.reduce(0, +)
    }

    var onlineUsers: [UserData] {
        return allUsers.filter { $0.isUserActive == true }
    }

    var offlineUsers: [UserData] {
        return allUsers.filter { $0.isUserActive == false }
    }
}

// MARK: - Supporting Models
struct CombinedChatResponse: Codable {
    let users: [UserData]?
    let recentChats: [RecentChat]?
    let totalCount: Int?
    let limit: Int?
    let currentPage: Int?
}

struct UserStatusUpdate: Codable {
    let userId: String
    let isActive: Bool
}

struct MessageReadReceipt: Codable {
    let conversationId: String
    let unreadCount: Int
}
