////
////  NotificationObservable.swift
////  meetX-iOS
////
////  Created by Karthick Thavasimuthu on 24-03-2025.
////
import SwiftUI
import Combine

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var selectedTab: NotificationTab = .all
    @Published var selectedFilter: NotificationType? = nil
    @Published var viewState: ViewState = .loading
    @Published var errorMessage: String? = nil
    @Published var errorToast: Bool = false
    @Published var isRefreshing = false
    @Published var isLoadingMore = false
    @Published var hasMoreData = true
    
    private var currentPage = 1
    private var totalPages = 1
    private var totalCount = 0
    private let limit = DeveloperConstants.Network.pageLimit
    private var cancellables = Set<AnyCancellable>()
    private var routeManager = RouteManager.shared
    
    init() {
        loadNotifications()
        
        $errorMessage
            .compactMap { $0 }
            .sink { error in
                self.errorToast.toggle()
            }
            .store(in: &cancellables)
    }
    
    var filteredNotifications: [NotificationItem] {
        var filtered = notifications
        
        // Filter by tab
        if selectedTab == .activity {
            filtered = filtered.filter { notification in
                guard let type = NotificationType(rawValue: notification.type) else { return false }
                return type.isActivityType
            }
        }
        
        // Filter by selected type
        if let selectedFilter = selectedFilter {
            filtered = filtered.filter { $0.type == selectedFilter.rawValue }
        }
        
        return filtered
    }
    
    var availableFilters: [NotificationType] {
        let uniqueTypes = Set(notifications.compactMap { NotificationType(rawValue: $0.type) })
        return Array(uniqueTypes).sorted { $0.displayName < $1.displayName }
    }
    
    var allNotificationCount: Int {
        return notifications.count
    }
    
    var activityNotificationCount: Int {
        return notifications.filter { notification in
            guard let type = NotificationType(rawValue: notification.type) else { return false }
            return type.isActivityType
        }.count
    }
    
    func loadNotifications() {
        // Reset pagination state for fresh load
        currentPage = 1
        hasMoreData = true
        notifications.removeAll()
        viewState = .loading
        
        loadNotificationList()
    }
    
    func refreshNotifications() async {
        isRefreshing = true
        
        // Reset pagination state for refresh
        currentPage = 1
        hasMoreData = true
        notifications.removeAll()
        
        loadNotificationList()
        
        // Wait for the API call to complete
        try? await Task.sleep(nanoseconds: 500_000_000)
        isRefreshing = false
    }
    
    func loadMoreNotifications() {
        guard !isLoadingMore && hasMoreData && viewState == .loaded else { return }
        
        isLoadingMore = true
        currentPage += 1
        loadNotificationList()
    }
    
    func retryLoading() {
        loadNotifications()
    }
    
    func acceptNotification(_ notification: NotificationItem) {
        switch NotificationType(rawValue: notification.type) {
            case .chatConnectionRequest:
                handleChatRequestAccept(
                    notification,
                    .chatAccept
                )
                
            case .activityInterestRequest:
                handleInviteAction(
                    notification,
                    .acceptInvite
                )
                
            case .followRequest:
                handleFollowHandling(
                    notification,
                    .followAccept
                )
                
            case .none, .some(.chatConnectionAccept), .some(.newPost), .some(.like), .some(.comment), .some(.activityInterestAccept), .some(.followAccepted), .some(.follow), .some(.commentLike), .some(.commentReply):
                break
        }
    }
    
    func declineNotification(_ notification: NotificationItem) {
        switch NotificationType(rawValue: notification.type) {
            case .chatConnectionRequest:
                handleChatRequestAccept(
                    notification,
                    .chatDecline
                )
                
            case .activityInterestRequest:
                handleInviteAction(
                    notification,
                    .declineInvite
                )
                
            case .followRequest:
                handleFollowHandling(
                    notification,
                    .followDecline
                )
                
            case .none, .some(.chatConnectionAccept), .some(.newPost), .some(.like), .some(.comment), .some(.activityInterestAccept), .some(.followAccepted), .some(.follow), .some(.commentLike), .some(.commentReply):
                break
        }
    }
    
    func selectFilter(_ filter: NotificationType?) {
        selectedFilter = filter
    }
    
    // Check if we should load more data when scrolling
    func shouldLoadMore(for notification: NotificationItem) -> Bool {
        guard let lastNotification = notifications.last else { return false }
        return notification.id == lastNotification.id && hasMoreData && !isLoadingMore
    }
    
    private func loadNotificationList() {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            viewState = .error("Dependency injection failed")
            isLoadingMore = false
            return
        }
        
        let urlString = URLBuilderConstants.URLBuilder(type: .notificationList)
        
        let queryParams: [String: String] = [
            "page": "\(currentPage)",
            "limit": "\(limit)"
        ]
        
        let publisher: AnyPublisher<NotificationResponse, APIError> = apiService.genericPublisher(
            fromURLString: urlString,
            queryParameters: queryParams
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                guard let self = self else { return }
                
                Loader.shared.stopLoading()
                self.isLoadingMore = false
                
                if case .failure(let error) = result {
                    print("Error loading notifications: \(error.localizedDescription)")
                    
                    if self.currentPage == 1 {
                        self.viewState = .error("Error Loading Notifications")
                    } else {
                        self.currentPage -= 1
                    }
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                Loader.shared.stopLoading()
                self.isLoadingMore = false
                
                // Handle the new response structure
                let newNotifications = response.notifications
                
                if self.currentPage == 1 {
                    self.notifications = newNotifications
                } else {
                    self.notifications.append(contentsOf: newNotifications)
                }
                
                // Update pagination info from response
                self.totalCount = response.totalNotification
                self.totalPages = response.totalPage
                self.hasMoreData = self.currentPage < response.totalPage
                
                self.viewState = self.notifications.isEmpty ? .empty : .loaded
            })
            .store(in: &cancellables)
    }
}

// MARK: - Helper Extensions
extension NotificationViewModel {
    
    /// Reset all filters and reload data
    func resetFiltersAndReload() {
        selectedFilter = nil
        selectedTab = .all
        loadNotifications()
    }
    
    /// Get the current loading state description for debugging
    var loadingStateDescription: String {
        switch viewState {
            case .loading:
                return "Loading initial data..."
            case .loaded:
                if isLoadingMore {
                    return "Loading more notifications..."
                } else if isRefreshing {
                    return "Refreshing notifications..."
                } else {
                    return "Data loaded successfully"
                }
            case .empty:
                return "No notifications found"
            case .error:
                return "Error loading notifications"
        }
    }
    
    /// Check if we can perform refresh action
    var canRefresh: Bool {
        return !isRefreshing && !isLoadingMore
    }
    
    /// Get pagination info for debugging
    var paginationInfo: String {
        return "Page \(currentPage) of \(totalPages) | Total: \(totalCount) | Has More: \(hasMoreData)"
    }
}

// MARK: - Chat Request Accept
extension NotificationViewModel {
    
    enum chatActionType {
        case chatAccept
        case chatDecline
    }
    
    enum followActionType {
        case followAccept
        case followDecline
    }
    
    enum activityActionType {
        case acceptInvite
        case declineInvite
    }
    
    /// Function to handle the chat request accept
    private func handleChatRequestAccept(
        _ notification: NotificationItem,
        _ actionType: chatActionType
    ) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            self.errorMessage = "Failed to map"
            return
        }
        
        guard let userID = notification.sender?.userId else {
            self.errorMessage = "No valid sender Id found"
            return
        }
        
        Loader.shared.startLoading()
        
        let urlString = URLBuilderConstants.URLBuilder(type: actionType == .chatAccept ? .acceptConnection : .declineConnection)
        let requestParams = ConnectionAcceptRequest(
            requesterId: userID, type: "chat"
        )
        
        let publisher: AnyPublisher<ConnectAcceptResponse, APIError> = apiService.genericPostPublisher(
            toURLString: urlString,
            requestBody: requestParams,
            isAuthNeeded: true
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    Loader.shared.stopLoading()
                    
                    if case .failure(let error) = completion {
                        self.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    Loader.shared.stopLoading()
                    
                    switch response.success {
                        case true:
                            self.errorMessage = response.message
                            if let index = self.notifications.firstIndex(where: { $0.id == notification.id }) {
                                self.notifications.remove(at: index)
                            }
                        case false:
                            self.errorMessage = response.message
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    @MainActor func moveUserToSenderProfile(for userId : String) {
        guard userId != "" else { return }
        let viewModel = ProfileMeAndOthersObservable(
            typeOfProfile: .others,
            userId: userId
        )
        routeManager.navigate(to: ProfileMeAndOthersRoute(
            viewmodel: viewModel
        ))
    }
}


// MARK: - Handle Follow
extension NotificationViewModel {
    
    /// Function to handle
    func handleFollowHandling(
        _ notification: NotificationItem,
        _ actionType: followActionType
    ) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            self.errorMessage = "Failed to map"
            return
        }
        
        guard let senderID = notification.sender?.userId else {
            self.errorMessage = "No valid sender Id found"
            return
        }
        
        Loader.shared.startLoading()
        
        let urlString = URLBuilderConstants.URLBuilder(type: .handleFollowAcceptAndDecline)
        let requestParams = FollowAcceptDeclineRequest(
            senderId: senderID, action: actionType == .followAccept ? "accept" : "reject")
        
        let publisher: AnyPublisher<FollowAcceptResponse, APIError> = apiService.genericPostPublisher(
            toURLString: urlString,
            requestBody: requestParams,
            isAuthNeeded: true
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    Loader.shared.stopLoading()
                    
                    if case .failure(let error) = completion {
                        self.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    Loader.shared.stopLoading()
                    self.errorMessage = response.message
                    if let index = self.notifications.firstIndex(where: { $0.id == notification.id }) {
                        self.notifications.remove(at: index)
                    }
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Function to handle Invite accept and decline
extension NotificationViewModel {
    func handleInviteAction(
        _ notification: NotificationItem,
        _ actionType: activityActionType
    ) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            self.errorMessage = "Failed to map"
            return
        }
        
        guard let postId = notification.postId else {
            self.errorMessage = "No valid post details found"
            return
        }
        
        guard let participantId = notification.participationId else {
            self.errorMessage = "No valid sender found"
            return
        }
        
        Loader.shared.startLoading()
        
        let urlString = URLBuilderConstants.URLBuilder(type: .handleActivityInvitePost)
        let requestParams = ActivityRequest(
            action: actionType == .acceptInvite ? "accept" : "reject",
            postId: postId,
            participationId: participantId
        )
        
        let publisher: AnyPublisher<InterestResponse, APIError> = apiService.genericPostPublisher(
            toURLString: urlString,
            requestBody: requestParams,
            isAuthNeeded: true
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    Loader.shared.stopLoading()
                    
                    if case .failure(let error) = completion {
                        self.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    Loader.shared.stopLoading()
                    self.errorMessage = response.message
                    if let index = self.notifications.firstIndex(where: { $0.id == notification.id }) {
                        self.notifications.remove(at: index)
                    }
                }
            )
            .store(in: &cancellables)
    }
}
