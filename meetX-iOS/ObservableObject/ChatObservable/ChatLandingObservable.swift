//
//  ChatLandingObservable.swift
//  meetX-iOS
//
//  SIMPLIFIED: Removed complex loading states and timers
//

import SwiftUI
import Combine

final class ChatLandingObservable: ObservableObject {

    // MARK: - Published Properties
    @Published var selectedSegment: DeveloperConstants.ChatSegmentControl = .Messages
    @Published var errorMessage: String?
    @Published var isInitialLoading = false
    @Published var isRefreshing = false
    @Published var isSocketConnected = false
    @Published var showingDeleteConfirmation = false
    @Published var showingMoreOptions = false
    @Published var selectedConversation: RecentChat?
    @Published var allUsers: [UserData] = []
    @Published var recentChats: [RecentChat] = []
    @Published var connectionsList: [ConnectedUser] = []
    @Published var isLoadingConnections = false
    @Published var isLoadingMoreConnections = false
    @Published var isRefreshingConnections = false
    @Published var connectionsErrorMessage: String?
    @Published var swipeOpenConversationId: String? = nil
    @Published var showScrollToUnreadBanner: Bool = false
    @Published var showReportChatModal: Bool = false

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var socketCancellables = Set<AnyCancellable>()
    private var socketClient: SocketFeedClient?
    private var hasDataLoaded = false
    private var lastRefreshTime = Date()

    // Pagination
    private var currentPage = 1
    private var totalPages = 1
    private let pageLimit = DeveloperConstants.Network.pageLimit
    private var canLoadMore = true

    // Connections pagination
    private var connectionsCurrentPage = 1
    private var connectionsTotalPages = 1
    private var connectionsCanLoadMore = true
    private var connectionsSearchQuery: String?

    let routeManager = RouteManager.shared

    // MARK: - Init
    init() {
        setupSocketClient()

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ChatLandingNeedsRefresh"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.forceRefresh()
        }
    }

    deinit {
        socketClient?.disconnect()
        socketCancellables.removeAll()
        cancellables.removeAll()
    }

    // MARK: - Socket Setup
    private func setupSocketClient() {
        socketClient = SwiftInjectDI.shared.resolve(SocketFeedClient.self) ?? SocketFeedClient()
    }

    // MARK: - SIMPLIFIED: View Lifecycle
    func onViewAppear() {
        errorMessage = nil

        // Only show initial loading if we have no data
        if !hasDataLoaded && recentChats.isEmpty && allUsers.isEmpty {
            isInitialLoading = true
        }

        if socketClient?.isConnected == true {
            loadData()
        } else {
            connectAndLoadData()
        }
    }

    func onViewDisappear() {
        // Keep socket connected but pause listening
        socketClient?.removeChatListeners()
    }

    // MARK: - SIMPLIFIED: Data Loading
    private func connectAndLoadData() {
        guard let socketClient = socketClient else {
            handleError("Socket client not available")
            return
        }

        socketClient.connectSocket(with: DeveloperConstants.BaseURL.socketBaseURL)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] success in
                self?.isSocketConnected = success
                if success {
                    self?.setupSocketListeners()
                    self?.loadData()
                } else {
                    self?.handleError("Failed to connect")
                }
            }
            .store(in: &socketCancellables)
    }

    private func loadData() {
        resetPagination()
        setupSocketListeners()

        socketClient?.emitUserOnlineAndPastConversationList(
            page: "1",
            limit: "\(pageLimit)"
        )
    }

    func refreshData() {
        isRefreshing = true
        errorMessage = nil
        loadData()
    }

    @MainActor
    func refreshData() async {
      //  await refreshData()
        // Wait for refresh to complete
        while isRefreshing {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    func forceRefresh() {
        hasDataLoaded = false
        recentChats.removeAll()
        allUsers.removeAll()
        onViewAppear()
    }

    func refreshIfNeeded() {
        // Only refresh if data is older than 30 seconds
        let thirtySecondsAgo = Date().addingTimeInterval(-30)
        if lastRefreshTime < thirtySecondsAgo {
            refreshData()
        }
    }

    // MARK: - SIMPLIFIED: Socket Listeners
    private func setupSocketListeners() {
        socketClient?.setupChatListeners(
            onOnlineUsersUpdate: { [weak self] in self?.handleOnlineUsersResponse(data: $0) },
            onConversationsUpdate: { [weak self] in self?.handleConversationsResponse(data: $0) },
            onNewMessageReceived: { [weak self] in self?.handleNewMessage(data: $0) },
            onUserTyping: { _ in },
            onUserStopTyping: { _ in }
        )
    }

    // MARK: - SIMPLIFIED: Response Handlers
    private func handleOnlineUsersResponse(data: Any) {
        guard let dataArray = data as? [[String: Any]],
              let responseDict = dataArray.first,
              let jsonData = try? JSONSerialization.data(withJSONObject: responseDict),
              let response = try? JSONDecoder().decode(OnlineOfflineUsersList.self, from: jsonData),
              let users = response.users else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.allUsers = users.sorted {
                let first = ($0.isUserActive ?? false ? 0 : 1, $0.name ?? $0.username ?? "")
                let second = ($1.isUserActive ?? false ? 0 : 1, $1.name ?? $1.username ?? "")
                return first < second
            }
            self?.finishLoading()
        }
    }

    private func handleConversationsResponse(data: Any) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let responses = try? JSONDecoder().decode([RecentChatResponse].self, from: jsonData),
              let response = responses.first else {
            handleError("Invalid data received")
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Update pagination
            if let totalCount = response.totalCount, let limit = response.limit {
                self.totalPages = max(1, Int(ceil(Double(totalCount) / Double(limit))))
                self.canLoadMore = self.currentPage < self.totalPages
            }

            // Update chats
            if let newChats = response.recentChats {
                if self.currentPage == 1 {
                    self.recentChats = newChats
                } else {
                    // Append new chats for pagination
                    for chat in newChats {
                        if !self.recentChats.contains(where: { $0.receiverId == chat.receiverId }) {
                            self.recentChats.append(chat)
                        }
                    }
                }
            }

            self.showScrollToUnreadBanner = self.totalUnreadCount > 0
            self.finishLoading()
        }
    }

    private func handleNewMessage(data: Any) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let recentChats = try? JSONDecoder().decode([RecentChat].self, from: jsonData) else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            for chat in recentChats {
                if let index = self.recentChats.firstIndex(where: { $0.conversationId == chat.conversationId }) {
                    self.recentChats.remove(at: index)
                }
                self.recentChats.insert(chat, at: 0)
            }

            playSystemSoundForNewMessage()
        }
    }

    private func finishLoading() {
        isInitialLoading = false
        isRefreshing = false
        hasDataLoaded = true
        lastRefreshTime = Date()
    }

    private func handleError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.isInitialLoading = false
            self?.isRefreshing = false
            self?.errorMessage = message
        }
    }

    // MARK: - Pagination
    func loadMoreConversations() {
        guard canLoadMore && currentPage < totalPages else { return }

        currentPage += 1
        socketClient?.emitUserOnlineAndPastConversationList(
            page: "\(currentPage)",
            limit: "\(pageLimit)"
        )
    }

    private func resetPagination() {
        currentPage = 1
        canLoadMore = true
    }

    // MARK: - Computed Properties
    var onlineUsers: [UserData] { allUsers.filter { $0.isUserActive == true } }
    var offlineUsers: [UserData] { allUsers.filter { $0.isUserActive == false } }
    var totalUnreadCount: Int { recentChats.compactMap { $0.unreadCount }.reduce(0, +) }
    var canLoadMoreConversations: Bool { canLoadMore }
    var hasConversations: Bool { !recentChats.isEmpty }
    var connectionStatus: String { isSocketConnected ? "Connected" : "Disconnected" }

    // MARK: - Actions
    @MainActor func visitProfile(_ conversation: RecentChat) {
        showingMoreOptions = false
        moveToUserProfileHome(for: conversation)
    }

    func showDeleteConfirmation(for conversation: RecentChat) {
        selectedConversation = conversation
        showingDeleteConfirmation = true
    }

    func showMoreOptions(for conversation: RecentChat) {
        selectedConversation = conversation
        showingMoreOptions = true
    }
}

// MARK: - Search Connection Functionality
extension ChatLandingObservable {
    func loadConnections() {
        guard !isLoadingConnections else { return }
        isLoadingConnections = true
        connectionsErrorMessage = nil
        connectionsCurrentPage = 1
        connectionsCanLoadMore = true
        fetchConnectionsList()
    }

    func refreshConnections() {
        isRefreshingConnections = true
        connectionsErrorMessage = nil
        connectionsCurrentPage = 1
        connectionsCanLoadMore = true
        connectionsList.removeAll()
        fetchConnectionsList()
    }

    func loadMoreConnections() {
        guard connectionsCanLoadMore && !isLoadingMoreConnections && connectionsCurrentPage < connectionsTotalPages else { return }
        isLoadingMoreConnections = true
        connectionsCurrentPage += 1
        fetchConnectionsList()
    }

    func searchConnections(query: String) {
        connectionsSearchQuery = query.isEmpty ? nil : query
        if query.isEmpty {
            loadConnections()
        } else {
            isLoadingConnections = true
            connectionsErrorMessage = nil
            handleFriendsList(page: 1, limit: DeveloperConstants.Network.pageLimit, searchQuery: query, completion: { [weak self] connectionListModel in
                DispatchQueue.main.async {
                    self?.handleConnectionsResponse(connectionListModel, isSearch: true)
                }
            }, failure: { [weak self] error in
                DispatchQueue.main.async {
                    self?.handleConnectionsError(error)
                }
            })
        }
    }

    private func fetchConnectionsList() {
        handleFriendsList(page: connectionsCurrentPage, limit: DeveloperConstants.Network.pageLimit, searchQuery: connectionsSearchQuery, completion: { [weak self] connectionListModel in
            DispatchQueue.main.async {
                self?.handleConnectionsResponse(connectionListModel, isSearch: false)
            }
        }, failure: { [weak self] error in
            DispatchQueue.main.async {
                self?.handleConnectionsError(error)
            }
        })
    }

    private func handleConnectionsResponse(_ response: ConnectionListModel, isSearch: Bool) {
        isLoadingConnections = false
        isLoadingMoreConnections = false
        isRefreshingConnections = false

        if let totalCount = response.totalCount, let limit = response.limit {
            connectionsTotalPages = max(1, Int(ceil(Double(totalCount) / Double(limit))))
            connectionsCanLoadMore = connectionsCurrentPage < connectionsTotalPages
        } else {
            connectionsCanLoadMore = false
        }

        if let users = response.connectedUsers {
            if connectionsCurrentPage == 1 || isSearch {
                connectionsList = users
            } else {
                for newUser in users {
                    if !connectionsList.contains(where: { $0.userId == newUser.userId }) {
                        connectionsList.append(newUser)
                    }
                }
            }
        }

        connectionsErrorMessage = nil
    }

    private func handleConnectionsError(_ error: Error) {
        isLoadingConnections = false
        isLoadingMoreConnections = false
        isRefreshingConnections = false
        connectionsErrorMessage = error.localizedDescription
    }

    var canLoadMoreConnections: Bool {
        return connectionsCanLoadMore && !isLoadingMoreConnections
    }

    var hasConnections: Bool {
        return !connectionsList.isEmpty
    }

    var isSearchingConnections: Bool {
        return connectionsSearchQuery != nil && !connectionsSearchQuery!.isEmpty
    }

    func handleFriendsList(page: Int, limit: Int = DeveloperConstants.Network.pageLimit, searchQuery: String? = nil, completion: @escaping (ConnectionListModel) -> Void, failure: @escaping (Error) -> Void) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            failure(APIError.apiFailed(underlyingError: nil))
            return
        }

        let urlString = URLBuilderConstants.URLBuilder(type: .tagConnectionList)
        var queryParams: [String: String]
        if let search = searchQuery, !search.isEmpty {
            queryParams = ["query": search]
        } else {
            queryParams = ["page": "\(page)", "limit": "\(limit)"]
        }

        let publisher: AnyPublisher<ConnectionListModel, APIError> = apiService.genericPublisher(fromURLString: urlString, queryParameters: queryParams)
        publisher.receive(on: DispatchQueue.main).sink(receiveCompletion: { result in
            if case .failure(let error) = result {
                Loader.shared.stopLoading()
                failure(error)
            }
        }, receiveValue: { connectionListModel in
            Loader.shared.stopLoading()
            completion(connectionListModel)
        }).store(in: &cancellables)
    }
}

// MARK: - Mute and Delete conversation
extension ChatLandingObservable {

    @MainActor func moveToUserProfileHome(for item: RecentChat) {
        guard item.receiverId != nil || item.receiverId != "" else { return }
        let viewModel = ProfileMeAndOthersObservable(
            typeOfProfile: .others,
            userId: item.receiverId ?? ""
        )

        NotificationCenter.default.post(name: NSNotification.Name("ChatLandingWillDisappear"), object: nil)

        routeManager.navigate(to: ProfileMeAndOthersRoute(
            viewmodel: viewModel
        ))
    }

    func deleteAconversation(_ conversation: RecentChat) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            errorMessage = "Something went wrong try again later"
            return
        }

        Loader.shared.startLoading()

        let urlString = URLBuilderConstants.URLBuilder(type: .loadMoreMessages)
        let requestBody = DeleteConversationRequest(
            conversationId: conversation.conversationId ?? ""
        )

        let publisher: AnyPublisher<generalMuteDeleteResponse, APIError> = apiService.genericPostPublisher(
            toURLString: urlString,
            requestBody: requestBody,
            isAuthNeeded: true,
            httpMethod: .patch
        )

        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                if case .failure(let error) = result {
                    Loader.shared.stopLoading()
                    self.errorMessage = error.localizedDescription
                }
            }, receiveValue: { _ in
                Loader.shared.stopLoading()

                if let index = self.recentChats.firstIndex(where: { $0.conversationId == conversation.conversationId }) {
                    self.recentChats.remove(at: index)
                }

                if self.selectedConversation?.conversationId == conversation.conversationId {
                    self.selectedConversation = nil
                }
            })
            .store(in: &cancellables)
    }

    func muteConversation(
        _ conversation: RecentChat,
        completion: @escaping () -> Void
    ) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            errorMessage = "Something went wrong try again later"
            return
        }

        let urlString = URLBuilderConstants.URLBuilder(type: .loadMoreMessages)
        let requestBody = DeleteConversationRequest(conversationId: conversation.conversationId ?? "")
        let publisher: AnyPublisher<generalMuteDeleteResponse, APIError> = apiService.genericPostPublisher(
            toURLString: urlString,
            requestBody: requestBody,
            isAuthNeeded: true,
            httpMethod: .post
        )
        publisher.receive(on: DispatchQueue.main).sink(receiveCompletion: { result in
            if case .failure(let error) = result {
                self.errorMessage = error.localizedDescription
                Loader.shared.stopLoading()
                completion()
            }
        }, receiveValue: { muteResponse in
            Loader.shared.stopLoading()
            self.errorMessage = muteResponse.message ?? ""
            if let index = self.recentChats.firstIndex(where: { $0.conversationId == conversation.conversationId }) {
                self.recentChats[index].toggleMute()
            }
            completion()
        }).store(in: &cancellables)
    }

    func reportChatConversation(
        _ conversation: RecentChat,
        reportReason: String,
        reportDescription: String,
        completion: @escaping () -> Void
    ) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            errorMessage = "Something went wrong try again later"
            return
        }

        let urlString = URLBuilderConstants.URLBuilder(type: .reportChat)
        let requestBody = ReportChatConversationRequest(
            receiverId: conversation.receiverId ?? "",
            reportReason: reportReason,
            description: reportDescription
        )
        let publisher: AnyPublisher<generalMuteDeleteResponse, APIError> = apiService.genericPostPublisher(
            toURLString: urlString,
            requestBody: requestBody,
            isAuthNeeded: true,
            httpMethod: .post
        )
        publisher.receive(on: DispatchQueue.main).sink(receiveCompletion: { result in
            if case .failure(let error) = result {
                self.errorMessage = error.localizedDescription
                Loader.shared.stopLoading()
                completion()
            }
        }, receiveValue: { reportSuccessfulResponse in
            Loader.shared.stopLoading()
            self.errorMessage = reportSuccessfulResponse.message ?? ""
            completion()
        }).store(in: &cancellables)
    }
}
