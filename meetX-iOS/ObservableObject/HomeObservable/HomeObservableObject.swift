//
//  HomeObservableObject.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 06-03-2025.
//

import SwiftUI
import Combine

final class HomeObservable: ObservableObject {
    
    // UI State
    @Published var selectedSubActivityID: Int = 99009922991
    @Published var showBottomSheet: Bool = false
    @Published var selectedSegment: DeveloperConstants.HomePageSegmentControlList = .all {
        didSet {
            updateFilteredPosts()
        }
    }
    
    // Feed State
    @Published var expandedDescriptions: Set<String> = []
    @Published var likedItems: Set<UUID> = []
    @Published var feedItemsObjects: FeedItems? {
        didSet {
            updateFilteredPosts()
        }
    }
    @Published var filteredPosts: [PostItem] = []
    @Published var newPostsAvailable: [PostItem] = [] // Track new posts for UI notification
    
    // Toast System
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    private var toastTimer: Timer?
    
    // Location Info (now updated via LocationViewModel's publishers)
    @Published var mainLocationName: String = Constants.locateMeText
    @Published var entireLocationName: String = Constants.locateMeDescription
    @Published var latitude: Double? = nil
    @Published var longitude: Double? = nil
    @Published var isLocationSelectionSheetPresent: Bool = false
    
    private let socketClient: SocketFeedClientProtocol
    private var socketCancellables = Set<AnyCancellable>()
    private var cancellables = Set<AnyCancellable>()
    
    // Socket State Management
    @Published var isSocketConnected: Bool = false
    @Published var isSocketListening: Bool = false
    private var shouldReconnectOnResume: Bool = false
    
    // Feed Scroll Handling
    var lastOffset: CGFloat = 0
    var actionHandler: ((PostItem, DeveloperConstants.FeedAction) -> Void)?
    let routeManager = RouteManager.shared
    
    private let permissionHelper = PermissionHelper()
    
    // API Filters (static)
    let activityType: URLBuilderConstants.ActivityType = .all
    var interestSelected: [Int] = []
    
    // Error
    @Published var errorMessage: String? = nil
    
    // Pagination properties
    @Published var isLoading = false
    @Published var isLoadingMore = false
    private var currentPage = 1
    private let limit = DeveloperConstants.Network.pageLimit
    private var totalCount = 0
    private var hasMoreData = true
    
    // Data Management
    private var postIdSet = Set<String>() // For O(1) duplicate checking
    
    // Show joined user list
    @Published var showJoinedUserList: Bool = false
    @Published var selectedJoinedUserList: [PeopleTags] = []
    
    // Show comment view
    @Published var commentViewPostId: String? = ""
    @Published var showCommentView: Bool = false
    
    let userDataManager: UserDataManager = UserDataManager.shared
    @Published var showMoreOptionsSheet: Bool = false
    
    // like debounce
    private var likeDebounceTask: DispatchWorkItem?
    private var pendingLikeStates: [String: Bool] = [:]
    
    // More options
    @Published var moreOptionsPostId: String = ""
    
    // Share sheet
    @Published var isShareSheetPresented = false
    @Published var shareItems: [Any] = []
    
    // MARK: - Init with injected LocationViewModel
    init(
        socketClient: SocketFeedClientProtocol,
        locationVM: LocationObservable
    ) {
        self.socketClient = socketClient

        // Bind LocationViewModel published properties to this object's properties
        locationVM.$subLocalityName
            .compactMap { $0 }
            .assign(to: \.mainLocationName, on: self)
            .store(in: &cancellables)
        
        locationVM.$locationName
            .compactMap { $0 }
            .assign(to: \.entireLocationName, on: self)
            .store(in: &cancellables)
        
        locationVM.$latitude
            .assign(to: \.latitude, on: self)
            .store(in: &cancellables)
        
        locationVM.$longitude
            .assign(to: \.longitude, on: self)
            .store(in: &cancellables)
        
        // Initialize socket connection check
        checkSocketConnectionAndSetupListeners()
      //  checkPermissions()

        // Comment. Like Action Handlers
        actionHandler = { [weak self] post, action in
            self?.moreOptionsPostId = post.postID ?? ""
            self?.handleAction(for: post, action: action)
        }
    }
    
    // MARK: - Socket Connection Management
    
    /// Check socket connection status and setup listeners accordingly
    private func checkSocketConnectionAndSetupListeners() {
        print("🔍 Checking socket connection status...")
        
        if socketClient.isConnected {
            print("✅ Socket already connected, setting up listeners")
            isSocketConnected = true
            setupPostListeners()
            startListening()
        } else {
            print("🔌 Socket not connected, initiating connection")
            connectToSocket()
        }
    }
    
    /// Connect to socket with proper state management
    func connectToSocket() {
        guard !socketClient.isConnected else {
            print("⚠️ Socket already connected")
            return
        }
        
        print("🔌 Connecting to socket...")
        
        socketClient.connectSocket(with: DeveloperConstants.BaseURL.socketBaseURL)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] success in
                guard let self = self else { return }
                
                if success {
                    print("✅ Socket connected successfully")
                    self.isSocketConnected = true
                    self.setupPostListeners()
                    self.startListening()
                } else {
                    print("❌ Socket connection failed")
                    self.isSocketConnected = false
                    Loader.shared.stopLoading()
                    self.errorMessage = "Failed to connect to socket"
                }
            }
            .store(in: &socketCancellables)
    }
    
    /// Pause socket listening when user navigates away
    func pauseSocket() {
        print("⏸️ Pausing socket...")
        
        if socketClient.isConnected {
            socketClient.pauseListening()
            isSocketListening = false
            shouldReconnectOnResume = true
            print("✅ Socket paused successfully")
        } else {
            print("⚠️ Socket not connected, nothing to pause")
        }
    }
    
    /// Resume socket listening when user returns
    func activateSocket() {
        print("▶️ Activating socket...")
        
        if socketClient.isConnected {
            print("✅ Socket already connected, resuming listening")
            socketClient.resumeListening()
            isSocketListening = true
            shouldReconnectOnResume = false
            
            // Wait for listeners to be ready, then start listening
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.startListening()
            }
        } else {
            print("🔌 Socket not connected, reconnecting...")
            connectToSocket()
        }
    }
    
    /// Disconnect socket completely (use sparingly)
    func disconnectSocket() {
        print("🔌 Disconnecting socket...")
        
        socketClient.disconnect()
        socketCancellables.forEach { $0.cancel() }
        socketCancellables.removeAll()
        
        isSocketConnected = false
        isSocketListening = false
        shouldReconnectOnResume = false
        
        // Clear tracking data
        postIdSet.removeAll()
        newPostsAvailable.removeAll()
        resetPagination()
        isLoading = false
        isLoadingMore = false
        hideToast()
        
        print("✅ Socket disconnected and cleaned up")
    }
    
    // MARK: - Comment, Like Action handlers
    func handleAction(
        for post: PostItem,
        action: DeveloperConstants.FeedAction
    ) {
        switch action {
            case .like:
                handleLike(for: post)
            case .comment:
                commentViewPostId = post.postID
                showCommentView = true
            case .share:
                if let post = post.postID {
                    sharePost(postId: post)
                }else {
                    errorMessage = "Share not available for this post"
                }
            case .moreOptions:
                showMoreOptionsSheet = true
        }
    }
    
    // Get current User ID
    var getCurrentUserID: String {
        userDataManager.getSecureUserData().userId ?? ""
    }

    var getUserGender: String {
        userDataManager.getSecureUserData().userGender ?? ""
    }

    // MARK: - Enhanced Post Listeners Setup
    private func setupPostListeners() {
        print("🎧 Setting up post listeners...")
        
        // Clear existing listeners first
        socketCancellables.forEach { $0.cancel() }
        socketCancellables.removeAll()
        
        setupSinglePostListener()
        setupBatchPostListener()
        setUpLikeListeners()
        
        print("✅ Post listeners setup complete")
    }
    
    // Setup listener for single new posts
    private func setupSinglePostListener() {
        socketClient.getNewPostsPublisher()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                    case .finished:
                        print("✅ Single post listener finished")
                    case .failure(let error):
                        print("❌ Single post listener error: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] newPost in
                self?.handleNewPost(newPost)
            }
            .store(in: &socketCancellables)
    }
    
    // Setup listener for batch posts (if supported)
    private func setupBatchPostListener() {
        socketClient.getNewPostsBatchPublisher()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                    case .finished:
                        print("✅ Batch post listener finished")
                    case .failure(let error):
                        print("❌ Batch post listener error: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] newPosts in
                self?.handleNewPosts(newPosts)
            }
            .store(in: &socketCancellables)
    }
    
    // MARK: - Enhanced Post Handling Logic
    
    // Handle single new post
    private func handleNewPost(_ newPost: PostItem) {
        print("🆕 New post received in home feed: \(newPost.caption ?? "No caption")")
        
        guard let newPostId = newPost.postID, !newPostId.isEmpty else {
            print("❌ Invalid post ID, skipping")
            return
        }
        
        // Only process if we have existing feed data
        guard feedItemsObjects != nil else {
            print("⚠️ No existing feed data, post will be included in next data load")
            return
        }
        
        let wasExistingPost = removeExistingPost(with: newPostId)
        postIdSet.insert(newPostId)
        
        insertNewPostAtTop(newPost, wasUpdate: wasExistingPost)
        showNewPostToast(isUpdate: wasExistingPost)
        
        print("✅ New post handled successfully")
    }
    
    // Handle multiple new posts (batch)
    private func handleNewPosts(_ newPosts: [PostItem]) {
        print("🆕 Batch of \(newPosts.count) new posts received")
        
        guard !newPosts.isEmpty else { return }
        
        // Only process if we have existing feed data
        guard feedItemsObjects != nil else {
            print("⚠️ No existing feed data, posts will be included in next data load")
            return
        }
        
        var genuinelyNewPosts: [PostItem] = []
        var updatedPosts: [PostItem] = []
        
        // Process each post and categorize
        for newPost in newPosts {
            guard let newPostId = newPost.postID, !newPostId.isEmpty else {
                print("❌ Skipping post with invalid ID")
                continue
            }
            
            let wasExisting = removeExistingPost(with: newPostId)
            postIdSet.insert(newPostId)
            
            if wasExisting {
                updatedPosts.append(newPost)
            } else {
                genuinelyNewPosts.append(newPost)
            }
        }
        
        // Insert all posts at once
        insertNewPostsAtTop(newPosts, newCount: genuinelyNewPosts.count)
        
        // Show appropriate toast
        showBatchPostToast(newCount: genuinelyNewPosts.count, updateCount: updatedPosts.count)
        
        print("✅ Batch processed: \(genuinelyNewPosts.count) new, \(updatedPosts.count) updated")
    }
    
    // MARK: - Enhanced Post Management
    
    // Remove existing post and return whether it existed
    private func removeExistingPost(with postId: String) -> Bool {
        guard var posts = feedItemsObjects?.posts else { return false }
        
        if let existingIndex = posts.firstIndex(where: { $0.postID == postId }) {
            let removedPost = posts.remove(at: existingIndex)
            feedItemsObjects?.posts = posts
            postIdSet.remove(postId) // Remove from tracking set temporarily
            
            print("🔄 Removed existing post at index \(existingIndex): \(removedPost.caption ?? "No caption")")
            return true
        }
        
        return false
    }
    
    // MARK: - Fixed Single Post Insertion
    private func insertNewPostAtTop(_ newPost: PostItem, wasUpdate: Bool) {
        if var existingPosts = feedItemsObjects?.posts {
            // Insert at the very top
            existingPosts.insert(newPost, at: 0)
            feedItemsObjects?.posts = existingPosts
            
            // ✅ FIXED: Only increment if genuinely new
            if !wasUpdate {
                totalCount += 1
                feedItemsObjects?.totalCount = totalCount
            }
            
            print("⬆️ Inserted 1 post. Total count now: \(totalCount)")
        } else {
            // Create new feed if none exists
            feedItemsObjects = FeedItems(
                totalCount: [newPost].count,
                count: 1,
                limit: 1,
                page: limit,
                posts: [newPost],
                currentUserInterests: feedItemsObjects?.currentUserInterests
            )
            totalCount = 1
            print("🆕 Created new feed with 1 post")
        }
        
        updateFilteredPosts()
    }
    
    // MARK: - Better: Batch Post Insertion
    private func insertNewPostsAtTop(_ newPosts: [PostItem], newCount: Int) {
        if var existingPosts = feedItemsObjects?.posts {
            // Insert all posts at the top (in reverse order to maintain chronological order)
            for post in newPosts.reversed() {
                existingPosts.insert(post, at: 0)
            }
            
            feedItemsObjects?.posts = existingPosts
            
            // ✅ CORRECT: Add only genuinely new posts to total count
            totalCount += newCount
            feedItemsObjects?.totalCount = totalCount
            
            print("⬆️ Inserted \(newPosts.count) posts (\(newCount) new). Total count now: \(totalCount)")
        } else {
            // Create new feed
            feedItemsObjects = FeedItems(
                totalCount: newPosts.count,
                count: newCount,
                limit: newPosts.count,
                page: limit,
                posts: newPosts,
                currentUserInterests: feedItemsObjects?.currentUserInterests
            )
            totalCount = newCount
            print("🆕 Created new feed with \(newPosts.count) posts")
        }
        
        updateFilteredPosts()
    }
    
    // MARK: - Enhanced Toast Messages
    private func showNewPostToast(isUpdate: Bool) {
        let message = isUpdate ? "Post updated" : "New post added"
        showToastMessage(message)
    }
    
    private func showBatchPostToast(newCount: Int, updateCount: Int) {
        let message: String
        
        if newCount > 0 && updateCount > 0 {
            message = "\(newCount) new posts, \(updateCount) updated"
        } else if newCount > 0 {
            message = newCount == 1 ? "1 new post added" : "\(newCount) new posts added"
        } else if updateCount > 0 {
            message = updateCount == 1 ? "1 post updated" : "\(updateCount) posts updated"
        } else {
            return // No toast needed
        }
        
        showToastMessage(message)
    }
    
    private func showToastMessage(_ message: String) {
        toastTimer?.invalidate()
        toastMessage = message
        showToast = true
        
        print("🍞 Showing toast: \(message)")
        
        toastTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.hideToast()
            }
        }
    }
    
    private func hideToast() {
        showToast = false
        toastMessage = ""
        toastTimer?.invalidate()
        toastTimer = nil
    }
    
    // MARK: - New Post Notification Management
    
    // Show notification for new posts
    private func showNewPostNotification() {
        print("🔔 New post available! Count: \(newPostsAvailable.count)")
        // You can implement a toast or banner notification here
        // The UI can observe newPostsAvailable to show a "New posts available" button
    }
    
    // Acknowledge new posts (call this when user taps "show new posts" or scrolls to top)
    func acknowledgeNewPosts() {
        print("👀 Acknowledging \(newPostsAvailable.count) new posts")
        newPostsAvailable.removeAll()
    }
    
    // MARK: - Location Management
    
    // User selected Location update from location sheet
    func updateLocation(
        mainName: String,
        entireName: String,
        latitude: Double?,
        longitude: Double?
    ) {
        self.mainLocationName = mainName
        self.entireLocationName = entireName
        self.latitude = latitude
        self.longitude = longitude
        self.isLocationSelectionSheetPresent = false
    }
    
    // MARK: - Feed Data Loading
    
    func startListening() {
        print("🎧 Starting to listen for feed data...")
        
        guard isSocketConnected || socketClient.isConnected else {
            print("❌ Socket not connected, cannot start listening")
            return
        }
        
        resetPagination()
        isLoading = true
        isSocketListening = true
        loadHomeFeedData()
    }
    
    // Load home feed data with pagination
    private func loadHomeFeedData() {
        print("📡 Loading home feed data (page: \(currentPage))")
        
        let url = createHomePageURL()
        
        socketClient.listenForFeedPosts(homePageUrl: url)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                    case .finished:
                        self.isLoading = false
                        self.isLoadingMore = false
                        Loader.shared.stopLoading()
                        print("✅ Feed data loading completed")
                    case .failure(let error):
                        self.isLoading = false
                        self.isLoadingMore = false
                        Loader.shared.stopLoading()
                        print("❌ Socket error: \(error.localizedDescription)")
                        self.errorMessage = "Failed to load posts: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] feedItems in
                self?.handleFeedResponse(feedItems)
            }
            .store(in: &socketCancellables)
    }
    
    // Handle feed response with pagination logic
    private func handleFeedResponse(_ feedItems: FeedItems) {
        Loader.shared.stopLoading()
        
        // Update pagination info
        totalCount = feedItems.totalCount ?? 0
        let newPosts = feedItems.posts ?? []
        
        print("📊 Response contains \(newPosts.count) posts for page \(currentPage), total available: \(totalCount)")
        
        if currentPage == 1 {
            // First page - replace all items
            self.feedItemsObjects = feedItems
            postIdSet.removeAll()
            
            // Initialize post tracking set
            for post in newPosts {
                if let postId = post.postID {
                    postIdSet.insert(postId)
                }
            }
            print("🔄 Replaced feed with \(newPosts.count) new posts")
        } else {
            // Subsequent pages - append only unique items
            var uniqueNewPosts: [PostItem] = []
            
            for post in newPosts {
                if let postId = post.postID, !postIdSet.contains(postId) {
                    postIdSet.insert(postId)
                    uniqueNewPosts.append(post)
                }
            }
            
            // Append to existing posts
            if var existingPosts = feedItemsObjects?.posts {
                existingPosts.append(contentsOf: uniqueNewPosts)
                feedItemsObjects?.posts = existingPosts
                feedItemsObjects?.totalCount = totalCount
            }
            
            print("➕ Added \(uniqueNewPosts.count) unique posts from \(newPosts.count) received")
        }
        
        // Check if there's more data
        let currentPostCount = feedItemsObjects?.posts?.count ?? 0
        hasMoreData = currentPostCount < totalCount
        
        isLoading = false
        isLoadingMore = false
        errorMessage = nil
        
        print("✅ Page \(currentPage) processed successfully. Feed size: \(currentPostCount)/\(totalCount), Has more: \(hasMoreData)")
    }
    
    // Create URL with pagination parameters
    // MARK: - Fixed URL Creation Method
    private func createHomePageURL() -> String {
        let baseURL = DeveloperConstants.BaseURL.socketHomePageURL
        var urlComponents = URLComponents(string: baseURL)
        
        let type = selectedSegment == .all 
        ? "0"
        : selectedSegment == .plannedActivity
        ? "2"
        : "3"

        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: "\(currentPage)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "type", value: type)
        ]


        if LocationStorage.isUsingCurrentLocation {
            if latitude != nil, longitude != nil {
                urlComponents?.queryItems?.append(URLQueryItem(name: "lat", value: "\(latitude ?? 0)"))
                urlComponents?.queryItems?.append(URLQueryItem(name: "long", value: "\(longitude ?? 0)"))
            }
        }else {
            urlComponents?.queryItems?
                .append(
                    URLQueryItem(
                        name: "lat",
                        value: "\(LocationStorage.latitude)"
                    )
                )
            urlComponents?.queryItems?
                .append(
                    URLQueryItem(
                        name: "long",
                        value: "\(LocationStorage.longitude)"
                    )
                )
        }

        // Fix 1: Only add interests parameter when NOT "All" is selected
        // Don't send interests parameter when "All" (99009922991) is selected
        if selectedSubActivityID != 99009922991 {
            urlComponents?.queryItems?.append(URLQueryItem(name: "interests", value: "[\(selectedSubActivityID)]"))
        }
        
        guard let finalURL = urlComponents?.url else {
            return DeveloperConstants.BaseURL.socketHomeFallBackURL
        }
        
        print("🌐 Home Feed URL: \(finalURL.absoluteString)")
        return finalURL.absoluteString
    }
    
    // MARK: - Pagination Management
    
    // Reset pagination
    private func resetPagination() {
        currentPage = 1
        totalCount = 0
        hasMoreData = true
    }
    
    // Load more data (pagination)
    func loadMoreData() {
        guard !isLoadingMore,
              hasMoreData,
              socketClient.isConnected else {
            print("❌ Cannot load more data - requirements not met")
            return
        }
        
        print("📄 Loading more data - page: \(currentPage + 1)")
        currentPage += 1
        isLoadingMore = true
        
        // Request more data using socket client's requestMoreHomeData method
        let url = createHomePageURL()
        socketClient.requestMoreHomeData(homePageUrl: url)
    }
    
    // Refresh data (pull to refresh)
    func refreshData() {
        resetPagination()
        isLoading = true
        loadHomeFeedData()
    }
    
    // Check if should load more based on item position
    func shouldLoadMore(for item: PostItem) -> Bool {
        guard let posts = feedItemsObjects?.posts,
              let index = posts.firstIndex(where: { $0.id == item.id }) else {
            return false
        }
        
        // Load more when user is near the end of the list
        let thresholdIndex = max(0, posts.count - 3)
        let shouldLoad = index >= thresholdIndex && hasMoreData && !isLoadingMore
        
        if shouldLoad {
            print("📄 Loading more data triggered at index \(index)")
            loadMoreData()
        }
        
        return shouldLoad
    }
    
    // MARK: - Permission and Location Sheet
    func checkLocationAndOpenLocationSelector() {
        guard permissionHelper.getLocationAuthStatus() else {
            showBottomSheet = true
            return
        }
        isLocationSelectionSheetPresent = true
    }
    
    func checkPermissions() {
        guard permissionHelper.getLocationAuthStatus() else {
            showBottomSheet = true
            return
        }
    }
    
    @MainActor func openAppSettings() {
        permissionHelper.openAppSettings()
    }
    
    // MARK: - Feed Helpers
    
    private func updateFilteredPosts() {
        guard let posts = feedItemsObjects?.posts else {
            filteredPosts = []
            return
        }
        
        switch selectedSegment {
            case .all:
                filteredPosts = posts
            case .plannedActivity:
                filteredPosts = posts.filter { $0.feedType == .activityPlaned }
            case .liveActivity:
                filteredPosts = posts.filter { $0.feedType == .live }
        }
    }
    
    func getDisplayedSubActivities() -> [SubActivitiesModel] {
        guard let activities = feedItemsObjects?.currentUserInterests else { return [] }
        
        return Array(activities.prefix(8))
    }
    
    func handleScroll(offset: CGFloat,
                      hideTabBarWhenScrolling: @escaping () -> Void,
                      unHideTabBarWhenScrolling: @escaping () -> Void) {
        if lastOffset == 0 {
            lastOffset = offset
            return
        }
        if offset == 0 && lastOffset > 50 {
            return
        }
        
        let scrollDiff = offset - lastOffset
        if abs(scrollDiff) < 10 { return }
        
        if scrollDiff < -10 {
            hideTabBarWhenScrolling()
        } else if scrollDiff > 10 {
            unHideTabBarWhenScrolling()
        }
        lastOffset = offset
    }
    
    func toggleDescriptionExpansion(for item: PostItem) {
        if let postID = item.postID {
            if expandedDescriptions.contains(postID) {
                expandedDescriptions.remove(postID)
            } else {
                expandedDescriptions.insert(postID)
            }
        }
    }
    
    @MainActor func moveToUserProfileHome(for item: PostItem) {
        guard item.user?.userId != nil || item.user?.userId != "" else { return }
        let viewModel = ProfileMeAndOthersObservable(
            typeOfProfile: getCurrentUserID == item.user?.userId ? .personal : .others,
            userId: item.user?.userId ?? ""
        )
        routeManager.navigate(to: ProfileMeAndOthersRoute(
            viewmodel: viewModel
        ))
    }
    
    @MainActor func moveToTaggedUserProfile(for userId: String) {
        guard userId != "" else { return }
        let viewModel = ProfileMeAndOthersObservable(
            typeOfProfile: getCurrentUserID == userId ? .personal : .others,
            userId: userId
        )
        routeManager.navigate(to: ProfileMeAndOthersRoute(
            viewmodel: viewModel
        ))
    }
    
    @MainActor func moveToPostDetails(for item: PostItem) {
        if filteredPosts.firstIndex(where: { $0.postID == item.postID }) != nil {
            
            let postsBinding = Binding<[PostItem]>(
                get: { self.filteredPosts },
                set: { newValue in
                    self.filteredPosts = newValue
                }
            )
            
            routeManager.navigate(to: PostDetailPageRoute(
                postId: item.postID ?? "",
                fromDestination: .fromHome,
                postItem: postsBinding
            ))
        }
    }
}

// MARK: - Extension for Interest Handling
extension HomeObservable {
    
    // Handle InterestButton action
    func handleShowInterest(feedItem: PostItem) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            self.errorMessage = "Failed to map"
            return
        }
        
        guard let postIdRetrived = feedItem.postID else {
            self.errorMessage = "No valid sender Id found"
            return
        }
        
        Loader.shared.startLoading()
        
        let urlString = URLBuilderConstants.URLBuilder(type: .handleInterestInPost)
        let requestParams = InterestPostRequest(
            postId: postIdRetrived
        )
        
        let publisher: AnyPublisher<InterestPostResponse, APIError> = apiService.genericPostPublisher(
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
                    
                    if response.success == true {
                        if let index = self.feedItemsObjects?.posts?.firstIndex(where: { $0.postID == feedItem.id }) {
                            self.feedItemsObjects?.posts?[index].updateFromFollowResponse(response)
                        }
                    } else {
                        self.errorMessage = "Failed to handle interest"
                    }
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Simplified Extension for like button
extension HomeObservable {
    
    func handleLike(for post: PostItem) {
        guard let postId = post.postID, !postId.isEmpty else {
            print("❌ Invalid postId for like operation")
            return
        }
        
       // Loader.shared.startLoading()
        
        // 1. Update UI immediately for instant feedback
        updatePostLikeStatusOptimistically(post: post)
        
        // 2. Cancel any pending API call for this post
        likeDebounceTask?.cancel()
        
        // 3. Debounce API call to prevent spam
        let task = DispatchWorkItem { [weak self] in
            self?.socketClient.likePost(postId: postId)
        }
        
        likeDebounceTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }
    
    private func updatePostLikeStatusOptimistically(post: PostItem) {
        guard let postId = post.postID,
              let index = feedItemsObjects?.posts?.firstIndex(where: { $0.postID == postId }) else {
            return
        }
        
        let currentLikeStatus = post.userContext?.hasLiked ?? false
        let newLikeStatus = !currentLikeStatus
        let currentTotal = post.totalLikes ?? 0
        
        // Update the post in the main array
        feedItemsObjects?.posts?[index].userContext?.hasLiked = newLikeStatus
        feedItemsObjects?.posts?[index].totalLikes = newLikeStatus ? currentTotal + 1 : max(0, currentTotal - 1)
    }
    
    func setUpLikeListeners() {
        socketClient.getLikeUpdatesPublisher()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    switch completionResult {
                        case .finished:
                            break
                        case .failure(let error):
                            debugPrint("❌ Like failed: \(error.localizedDescription)")
                            self?.handleLikeFailure(error: error)
                    }
                },
                receiveValue: { likeResponse in }
            )
            .store(in: &socketCancellables)
    }
    
    func updateCount(for postId: String) {
        guard let updatedFeedItem = filteredPosts.first(where: { $0.postID == postId }) else { return }
        
        if let index = feedItemsObjects?.posts?.firstIndex(where: { $0.postID == updatedFeedItem.postID }) {
            feedItemsObjects?.posts?[index].totalComments = updatedFeedItem.totalComments ?? 0
            feedItemsObjects?.posts?[index].totalLikes = updatedFeedItem.totalLikes ?? 0
        }
    }
    
    private func handleLikeFailure(error: Error) {
        errorMessage = error.localizedDescription
    }
    
    // MARK: - Share post
    func sharePost(postId: String) {
        guard let postIndex = self.feedItemsObjects?.posts?.firstIndex(where: {
            $0.postID == postId
        }) else { return }
        
        guard let post = self.feedItemsObjects?.posts?[postIndex] else { return }
        
        var items: [Any] = []
        
        if let userName = post.user?.username {
            items.append("\n🎉 \(userName) invited you to check out this activity!")
        }
        
        if let location = post.location {
            items.append("\n📍 Location: \(location)")
        }
        
        if let eventDate = post.eventDate {
            if let convertedDate = HelperFunctions.convertUTCToISTAndCalculateDifference(utcString: eventDate) {
                items.append("\n🗓️ Date: \(convertedDate.date)")
            }
        }
        
        if let endTime = post.eventDate,
           post.isActive == true {
            if let convertedDate = HelperFunctions.convertUTCToISTAndCalculateDifference(utcString: endTime) {
                items.append("\n⏰ Remaining hours: \(convertedDate.hoursFromNow)")
            }
        }
        
        if post.likeCount ?? 0 > 0, post.totalComments ?? 0 > 0, post.totalInterestedUsers ?? 0 > 0 {
            items.append("\n❤️ \(post.totalLikes ?? 0) Likes   💬 \(post.totalComments ?? 0) Comments   ⭐️ \(post.totalInterestedUsers ?? 0) Interested")
        }
        
        if let imageMedia = post.mediaFiles?.first(where: { ($0.type ?? "").contains("image") }),
           let imageUrlString = imageMedia.url,
           let imageUrl = URL(string: imageUrlString) {
            
            items.append(imageUrl)
            
        } else if let videoMedia = post.mediaFiles?.first(where: { ($0.type ?? "").contains("video") }),
                  let videoUrlString = videoMedia.url,
                  let videoUrl = URL(string: videoUrlString) {
            
            items.append("\n🎬 Watch Activity: \(videoUrl.absoluteString)")
        }
        
        if let postID = post.postID {
            items.append("\n🔗 \(DeveloperConstants.BaseURL.deepLinkPostURL)\(postID)")
        }
        
        shareItems = items
        isShareSheetPresented = true
    }
}
