//
//  SocketCallClient.swift
//  meetX-iOS
//
//  Updated to handle new_post as array of PostItem
//

import Foundation
import SocketIO
import Combine
import os.log

final class SocketFeedClient: SocketFeedClientProtocol {
    // MARK: - Publishers Like, Comment and Reply
    private(set) var isConnected: Bool = false
    private var cancellables = Set<AnyCancellable>()
    private var lastHomePageUrl: String?
    private var lastExploreData: [String: Any]?
    private var isListeningForNewPosts = false
    private let refreshExplorePageSubject = PassthroughSubject<Void, Error>()
    private var connectionSubject = PassthroughSubject<Bool, Never>()

    // MARK: - Publisher for Home and Explore Section
    var feedItemsSubject = PassthroughSubject<FeedItems, Error>()
    var newPostSubject = PassthroughSubject<PostItem, Error>()
    var likeUpdateSubject = PassthroughSubject<LikeResponse, Error>()
    var newPostsBatchSubject = PassthroughSubject<[PostItem], Error>()
    let manager: SocketIOManager
    let logger = Logger(
        subsystem: DeveloperConstants.BaseURL.subSystemLogger,
        category: "SocketFeedClient"
    )
    
    // MARK: - Listener state tracking
    private enum ListenerType {
        case home
        case explore
        case none
    }
    
    private var currentListenerType: ListenerType = .none
    private var isListenersPaused = false
    
    // MARK: - Like operation tracking
    private var pendingLikeOperations: [String: PassthroughSubject<Bool, Error>] = [:]
    
    // MARK: - Chat Message Publishers
    var newMessageSubject = PassthroughSubject<ChatMessage, Error>()
    var messageUpdateSubject = PassthroughSubject<ChatMessage, Error>()
    var messageDeleteSubject = PassthroughSubject<String, Error>()
    var typingSubject = PassthroughSubject<[String], Error>()
    var stopTypingSubject = PassthroughSubject<[String], Error>()
    
    init(manager: SocketIOManager = .shared) {
        self.manager = manager
    }
    
    func connectSocket(with url: String) -> AnyPublisher<Bool, Never> {
        manager.configure(baseURL: url)
        
        manager.connect { [weak self] isConnected in
            self?.isConnected = isConnected
            self?.connectionSubject.send(isConnected)
        }
        
        return connectionSubject.eraseToAnyPublisher()
    }
    
    func disconnect() {
        isConnected = false
        cleanupAllListeners()
        manager.disconnect()
        // Reset state
        currentListenerType = .none
        isListenersPaused = false
        lastHomePageUrl = nil
        lastExploreData = nil
    }
    
    // MARK: - Listener Management
    private func cleanupAllListeners() {
        manager.off(event: "new_post")
        manager.off(event: "dataResponse")
        manager.off(event: "like_update")
        isListeningForNewPosts = false
        
        logger.info("🧹 All socket listeners cleaned up")
    }
    
    func pauseListening() {
        guard !isListenersPaused else {
            logger.info("⏸️ Listeners already paused")
            return
        }
        
        cleanupAllListeners()
        isListenersPaused = true
        logger.info("⏸️ Socket listening paused - keeping connection alive")
    }
    
    func resumeListening() {
        guard isListenersPaused else {
            logger.info("▶️ Listeners not paused, nothing to resume")
            return
        }
        
        guard currentListenerType == .home else {
            logger.info("❌ Cannot resume home listening - not previously listening to home feed")
            return
        }
        
        guard let url = lastHomePageUrl else {
            logger.info("❌ No last home page URL to resume")
            return
        }
        
        logger.info("▶️ Resuming home feed listening - restoring listeners only")
        isListenersPaused = false
        
        // FIXED: Only restore listeners, don't re-fetch data
        setupHomeListeners(homePageUrl: url)
    }
    
    func resumeExploreListening() {
        guard isListenersPaused else {
            logger.info("▶️ Listeners not paused, nothing to resume")
            return
        }
        
        guard currentListenerType == .explore else {
            logger.info("❌ Cannot resume explore listening - not previously listening to explore feed")
            return
        }
        
        guard let data = lastExploreData else {
            logger.info("❌ No last explore data to resume")
            return
        }
        
        logger.info("▶️ Resuming explore feed listening - restoring listeners only")
        isListenersPaused = false
        
        // FIXED: Only restore listeners, don't re-fetch data
        setupExploreListeners(with: data)
    }
    // MARK: - Home Feed Processing
    func listenForFeedPosts(homePageUrl: String) -> AnyPublisher<FeedItems, Error> {
        cleanupAllListeners()
        lastHomePageUrl = homePageUrl
        currentListenerType = .home
        isListenersPaused = false
        
        manager.emit(event: "getallposts", data: ["homePageUrl": homePageUrl])
        setupHomeListeners(homePageUrl: homePageUrl)
        
        return feedItemsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - HOME PAGE
    /// Listeners Setup
    private func setupHomeListeners(homePageUrl: String) {
        // Handle new_post as array
        manager.onlistenEvent(event: "new_post") { [weak self] response, _ in
            self?.logger.info("🆕 New post received in home feed")
            self?.handleNewPostArrayResponse(data: response)
        }
        
        manager.onlistenEvent(event: "dataResponse") { [weak self] data, _ in
            self?.logger.info("📦 Data response received for home feed")
            self?.handleFeedPostsResponse(data: data)
        }
        
        isListeningForNewPosts = true
        logger.info("👂 Home feed listeners set up")
    }
    
    // MARK: - EXPLORE
    /// Explore Feeds
    func listenForExploreFeedPosts(
        lat: Double,
        long: Double,
        url: String
    ) -> AnyPublisher<FeedItems, any Error> {
        
        cleanupAllListeners()
        
        let data: [String: Any] = [
            "explorePageUrl": url,
            "body": [
                "latitude": "\(lat)",
                "longitude": "\(long)"
            ]
        ]
        
        lastExploreData = data
        currentListenerType = .explore
        isListenersPaused = false
        
        manager.emit(event: "getliveposts", data: data)
        setupExploreListeners(with: data)
        
        return feedItemsSubject.eraseToAnyPublisher()
    }
    
    /// EXPLORE Setup listeners
    private func setupExploreListeners(with data: [String: Any]) {
        // Handle new_post as array for explore too
        manager.onlistenEvent(event: "new_post") { [weak self] response, _ in
            self?.logger.info("🆕 New post received in explore feed")
            self?.handleNewPostArrayResponse(data: response)
        }
        
        manager.onlistenEvent(event: "dataResponse") { [weak self] responseData, _ in
            self?.logger.info("📦 Data response received for explore feed")
            self?.handleFeedPostsResponse(data: responseData)
        }
        
        manager.onlistenEvent(event: "postExpired", callback: { _, _ in
            self.logger.info("Some Expired post is there")
            self.refreshExplorePageSubject.send()
        })
        
        isListeningForNewPosts = true
        logger.info("👂 Explore feed listeners set up")
    }
    
    // MARK: - Like Listener Setup
    private func setupLikeListener(_ postId: String) {
        manager.onlistenEvent(event: "like_update") { [weak self] data, _ in
            self?.logger.info("👍 Like update received: \(data)")
            self?.handleLikeResponse(data: data)
        }
    }
    
    // MARK: - Publishers
    func getNewPostsPublisher() -> AnyPublisher<PostItem, Error> {
        return newPostSubject.eraseToAnyPublisher()
    }
    
    func getNewPostsBatchPublisher() -> AnyPublisher<[PostItem], Error> {
        return newPostsBatchSubject.eraseToAnyPublisher()
    }
    
    func getExpiredPostRefreshInExplore() -> AnyPublisher<Void, any Error> {
        return refreshExplorePageSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Pagination
    func requestMoreExploreData(lat: Double, long: Double, url: String) {
        let data: [String: Any] = [
            "explorePageUrl": url,
            "body": [
                "latitude": "\(lat)",
                "longitude": "\(long)"
            ]
        ]
        
        logger.info("📄 Requesting more explore data")
        manager.emit(event: "getliveposts", data: data)
    }
    
    func requestMoreHomeData(homePageUrl: String) {
        logger.info("📄 Requesting more home data")
        manager.emit(event: "getallposts", data: ["homePageUrl": homePageUrl])
    }
    
    func emitEvent(emitEventName: String, data: [String : Any]) {
        manager.emit(event: emitEventName, data: data)
    }
}

// MARK: - Data Handlers
extension SocketFeedClient {
    // MARK: - Standalone Like Post Method
    func likePost(postId: String) {
        let eventName = "like_post"
        let data: [String: Any] = [
            "likeUrl": DeveloperConstants.BaseURL.socketLikeURL + "\(postId)"
        ]
        
        logger.info("👍 Emitting like_post for postId: \(postId)")
        manager.emit(event: eventName, data: data)
        
        // Set up like listener ONLY when we emit a like
        setupLikeListener(postId)
    }
    
    // MARK: - Get Like Updates Publisher (This is all you need)
    func getLikeUpdatesPublisher() -> AnyPublisher<LikeResponse, Error> {
        return likeUpdateSubject.eraseToAnyPublisher()
    }
}
