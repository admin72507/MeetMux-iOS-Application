//
//  SocketFeedClientProtocol.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 18-05-2025.
//

import Foundation
import Combine

protocol SocketFeedClientProtocol {
    var isConnected: Bool { get }
    
    // Connection management
    func connectSocket(with url: String) -> AnyPublisher<Bool, Never>
    func disconnect()
    
    // Listener management
    func pauseListening()
    func resumeListening()
    func resumeExploreListening()
    
    // Feed listeners
    func listenForFeedPosts(homePageUrl: String) -> AnyPublisher<FeedItems, Error>
    func listenForExploreFeedPosts(lat: Double, long: Double, url: String) -> AnyPublisher<FeedItems, Error>
    
    // Post publishers
    func getNewPostsPublisher() -> AnyPublisher<PostItem, Error>
    func getNewPostsBatchPublisher() -> AnyPublisher<[PostItem], Error>
    func getExpiredPostRefreshInExplore() -> AnyPublisher<Void, any Error>
    
    // Pagination
    func requestMoreExploreData(lat: Double, long: Double, url: String)
    func requestMoreHomeData(homePageUrl: String)
    
    // Generic emit
    func emitEvent(emitEventName: String, data: [String: Any])
    
    // Like Post
    func likePost(postId: String)
    func getLikeUpdatesPublisher() -> AnyPublisher<LikeResponse, Error>
    
    // MARK: - Chat Management
    func emitUserOnlineAndPastConversationList(page: String, limit: String)
    func setupChatListeners(
        onOnlineUsersUpdate: @escaping (Any) -> Void,
        onConversationsUpdate: @escaping (Any) -> Void,
        onNewMessageReceived: @escaping (Any) -> Void,
        onUserTyping: @escaping (Any) -> Void,
        onUserStopTyping: @escaping (Any) -> Void
    )
    func removeChatListeners()
    
    // MARK: - Chat Messages
    func setupMessageListeners(
        onNewMessage: @escaping (ChatMessage) -> Void,
        onMessageDelete: @escaping (String) -> Void
    )
    func removeMessageListeners()
    
    // Message operations
    func emitSendMessage(
        message: String,
        receiverId: String,
        mediaUrl: String?,
        completion: @escaping (Result<ChatMessage, Error>) -> Void
    )
    func emitEditMessage(
        receiverId: String,
        messageId: String,
        newText: String,
        completion: @escaping (Result<generalCallBackChatResponse, Error>) -> Void
    )
    func emitDeleteMessage(
        messageId: String,
        receiverId: String,
        completion: @escaping (Result<generalCallBackChatResponse, Error>) -> Void
    )
    func emitToggleReaction(messageId: String, reaction: String)
    func emitMarkAllMessagesAsRead(
        senderId: String,
        receiverId: String
    )
    func emitMakeRoomPrivate(
        receiverId: String,
        completion: @escaping (Result<RecentChat, Error>) -> Void
    )
    func emitMakePrivateRoomTurnOff(receiverId: String)

    // MARK: - Typing Events
    func emitTypingStart(receiverId: String)
    func emitTypingStop(receiverId: String)
    func setupTypingListeners(
        onUserTyping: @escaping ([String]) -> Void,
        onUserStopTyping: @escaping ([String]) -> Void
    )
    func removeTypingListeners()
    
    // MARK: - Chat Publishers
    func getNewMessagePublisher() -> AnyPublisher<ChatMessage, Error>
    func getMessageUpdatePublisher() -> AnyPublisher<ChatMessage, Error>
    func getMessageDeletePublisher() -> AnyPublisher<String, Error>
    func getTypingPublisher() -> AnyPublisher<[String], Error>
    func getStopTypingPublisher() -> AnyPublisher<[String], Error>
}
