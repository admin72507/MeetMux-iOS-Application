//
//  SocketFeedClient+Extension.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 10-07-2025.
//

import Foundation
import SocketIO
import Combine

// MARK: - Chat Sockets in Chat Landing page
extension SocketFeedClient {

    // MARK: - Chat Landing page
    /// When user lands on chat landing page ,
    /// If page is 1 --> Hotizontal live and offline user list
    /// If page is 2 or greater it will give the past conversation list
    func emitUserOnlineAndPastConversationList(page: String, limit: String) {
        let data: [String: Any] = [
            "data": [
                "page": page,
                "limit": limit
            ]
        ]
        manager
            .emit(
                event: DeveloperConstants.ChatLandingPage.OnlineOfflineUserListPastConversationEvent,
                data: data
            )
    }

    // MARK: - Chat Listeners Setup
    /// Listen for conversation updates
    /// First 20 convo, if user uses pagnation --> page 2 --> 20 convo
    /// He is in page 2 --> he is getting a message --> 1 item --> put 0 and notify the user---> Multiple [Message]
    ///
    /// Typing event lister for showing typing at line 58
    /// Typring event stop typing at line 66
    func setupChatListeners(
        onOnlineUsersUpdate: @escaping (Any) -> Void,
        onConversationsUpdate: @escaping (Any) -> Void,
        onNewMessageReceived: @escaping (Any) -> Void,
        onUserTyping: @escaping (Any) -> Void,
        onUserStopTyping: @escaping (Any) -> Void
    ) {
        manager
            .onlistenEvent(
                event: DeveloperConstants.ChatLandingPage.listenForOnlineOfflinePastConvoEvent
            ) { data, _ in
                onOnlineUsersUpdate(data)
            }

        manager
            .onlistenEvent(
                event: DeveloperConstants.ChatLandingPage.listenForpastConversationEvent
            ) { data, _ in
                self.logger.info("📥 Received: updated-conversation-list")
                onConversationsUpdate(data)
            }

        manager
            .onlistenEvent(
                event: DeveloperConstants.ChatLandingPage.newMessageReceiveEvent
            ) { data, _ in
                self.logger.info("Received latest message")
                onNewMessageReceived(data)
            }

        manager
            .onlistenEvent(
                event: DeveloperConstants.ChatLandingPage.listenForTypingEvent
            ) { data, _ in
                onUserTyping(data)
            }

        manager
            .onlistenEvent(
                event: DeveloperConstants.ChatLandingPage.listenForTypingStopEvent
            ) { data, _ in
                onUserStopTyping(data)
            }
    }

    // MARK: - Remove Chat Listeners
    /// Remove specific listeners for chat - Stopped online offline user count
    /// Stopped User Past conversation list
    /// Stopped friends typing start and stopped
    func removeChatListeners() {
        manager.off(event: DeveloperConstants.ChatLandingPage.listenForOnlineOfflinePastConvoEvent)
        manager.off(event: DeveloperConstants.ChatLandingPage.listenForpastConversationEvent)
        manager.off(event: DeveloperConstants.ChatLandingPage.listenForTypingEvent)
        manager.off(event: DeveloperConstants.ChatLandingPage.listenForTypingStopEvent)
        logger.info("🚫 Removed chat listeners")
    }
}

// MARK: - Chat Messages in Chat Room page
extension SocketFeedClient {

    // MARK: - Message Listeners
    func setupMessageListeners(
        onNewMessage: @escaping (ChatMessage) -> Void,
        onMessageDelete: @escaping (String) -> Void
    ) {
        manager.onlistenEvent(event: "receive_message") { [weak self] data, _ in
            self?.logger.info("💬 New message received")
            self?.handleIncomingMessage(data: data, callback: onNewMessage)
        }

        manager.onlistenEvent(event: "message_deleted") { [weak self] data, _ in
            self?.logger.info("🗑️ Message deleted")
            self?.handleDeletedMessage(data: data, callback: onMessageDelete)
        }

        logger.info("👂 Message listeners initialized")
    }

    func removeMessageListeners() {
        manager.off(event: "receive_message")
    }

    // MARK: - Emit Messages
    func emitSendMessage(
        message: String,
        receiverId: String,
        mediaUrl: String?,
        completion: @escaping (Result<ChatMessage, Error>) -> Void
    ) {
        let payload: [String: Any] = [
            "message": message,
            "receiverId": receiverId,
            "mediaUrl": mediaUrl ?? ""
        ]

        manager.emitWithAck(
            event: DeveloperConstants.ChatRoomPage.sendMessage,
            data: payload,
            decodeTo: ChatMessage.self
        ) { result in
            self.logger.info("📤 Sent message to \(receiverId)")
            completion(result)
        }
    }

    func emitEditMessage(
        receiverId: String,
        messageId: String,
        newText: String,
        completion: @escaping (Result<generalCallBackChatResponse, Error>) -> Void
    ) {
        let payload: [String: Any] = [
            "receiverId": receiverId,
            "messageId": messageId,
            "message": newText
        ]

        manager.emitWithAck(
            event: "editMessage",
            data: payload,
            decodeTo: generalCallBackChatResponse.self,
            completion: completion
        )
    }

    func emitDeleteMessage(
        messageId: String,
        receiverId: String,
        completion: @escaping (Result<generalCallBackChatResponse, Error>) -> Void
    ) {
        let payload: [String: Any] = [
            "receiverId": receiverId,
            "messageId": messageId
        ]

        manager.emitWithAck(
            event: "deleteMessage",
            data: payload,
            decodeTo: generalCallBackChatResponse.self,
            completion: completion
        )
    }

    func emitToggleReaction(messageId: String, reaction: String) {
        let payload: [String: Any] = [
            "messageId": messageId,
            "reaction": reaction
        ]
        logger.info("❤️ Reacting to message: \(messageId)")
        manager.emit(event: "toggle_reaction", data: payload)
    }

    // MARK: - Room and Read Status
    func emitMarkAllMessagesAsRead(senderId: String, receiverId: String) {
        let payload: [String: Any] = [
            "senderId": senderId,
            "receiverId": receiverId
        ]
        manager.emit(event: DeveloperConstants.ChatRoomPage.makeAllMessagesReadEvent, data: payload)
    }

    func emitMakeRoomPrivate(receiverId: String, completion: @escaping (Result<RecentChat, Error>) -> Void) {
        let payload: [String: Any] = ["receiverId": receiverId]
        manager.emitWithAck(
            event: DeveloperConstants.ChatRoomPage.emitMakePrivateRoom,
            data: payload,
            decodeTo: RecentChat.self,
            completion: completion
        )
    }

    func emitMakePrivateRoomTurnOff(receiverId: String) {
        manager.emit(
            event: DeveloperConstants.ChatRoomPage.emitMakePrivateRoomTurnOff,
            data: ["receiverId": receiverId]
        )
    }

    // MARK: - Typing Events
    func emitTypingStart(receiverId: String) {
        manager.emit(event: "typing", data: ["receiverId": receiverId])
        logger.info("⌨️ Typing started to \(receiverId)")
    }

    func emitTypingStop(receiverId: String) {
        manager.emit(event: "stop_typing", data: ["receiverId": receiverId])
        logger.info("⌨️ Typing stopped to \(receiverId)")
    }

    func setupTypingListeners(
        onUserTyping: @escaping ([String]) -> Void,
        onUserStopTyping: @escaping ([String]) -> Void
    ) {
        manager.onlistenEvent(event: DeveloperConstants.ChatLandingPage.listenForTypingEvent) { [weak self] data, _ in
            self?.logger.info("⌨️ Typing event")
            //self?.parseTypingEvent(data: data, callback: onUserTyping)
        }

        manager.onlistenEvent(event: DeveloperConstants.ChatLandingPage.listenForTypingStopEvent) { [weak self] data, _ in
            self?.logger.info("⌨️ Stop typing event")
          //  self?.parseTypingEvent(data: data, callback: onUserStopTyping)
        }
    }

    func removeTypingListeners() {
        manager.off(event: DeveloperConstants.ChatLandingPage.listenForTypingEvent)
        manager.off(event: DeveloperConstants.ChatLandingPage.listenForTypingStopEvent)
        logger.info("🚫 Typing listeners removed")
    }

    // MARK: - Publishers
    func getNewMessagePublisher() -> AnyPublisher<ChatMessage, Error> {
        newMessageSubject.eraseToAnyPublisher()
    }

    func getMessageUpdatePublisher() -> AnyPublisher<ChatMessage, Error> {
        messageUpdateSubject.eraseToAnyPublisher()
    }

    func getMessageDeletePublisher() -> AnyPublisher<String, Error> {
        messageDeleteSubject.eraseToAnyPublisher()
    }

    func getTypingPublisher() -> AnyPublisher<[String], Error> {
        typingSubject.eraseToAnyPublisher()
    }

    func getStopTypingPublisher() -> AnyPublisher<[String], Error> {
        stopTypingSubject.eraseToAnyPublisher()
    }
}


private extension SocketFeedClient {
    func handleIncomingMessage(data: [Any], callback: @escaping (ChatMessage) -> Void) {
        guard let first = data.first else { return }
        do {
            let json = try JSONSerialization.data(withJSONObject: first)
            let message = try JSONDecoder().decode(ChatMessage.self, from: json)
            callback(message)
            newMessageSubject.send(message)
        } catch {
            newMessageSubject.send(completion: .failure(error))
        }
    }

    func handleDeletedMessage(data: [Any], callback: @escaping (String) -> Void) {
        guard let dict = data.first as? [String: Any], let messageId = dict["messageId"] as? String else { return }
        callback(messageId)
        messageDeleteSubject.send(messageId)
    }
}


extension DeveloperConstants {

    enum ChatLandingPage {
        static let OnlineOfflineUserListPastConversationEvent = "getOnlineUsers"
        static let listenForOnlineOfflinePastConvoEvent = "updated-connection-list"
        static let listenForpastConversationEvent = "updated-conversation-list"
        static let newMessageReceiveEvent = "newMessageReceived"
        static let listenForTypingEvent = "user_typing"
        static let listenForTypingStopEvent = "user_stop_typing"
    }

    enum ChatRoomPage {
        static let makeAllMessagesReadEvent = "markAllRead"
        static let emitMakePrivateRoom = "private_room"
        static let emitMakePrivateRoomTurnOff = "leave_private_room"
        static let sendMessage = "sendMessage"
    }
}
