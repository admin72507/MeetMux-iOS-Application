//  ExploreObservable.swift
//  meetX-iOS
//
//  Simplified version to fix loading issues

import SwiftUI
import Combine
import CoreLocation

class ExploreViewModel: ObservableObject {
    // MARK: - Core State (Optimized)
    @Published var isInitialLoading = true // Only true for first load
    @Published var hasReceivedData = false // True as soon as any data arrives
    @Published var isLoading = false
    @Published var feedItems: [PostItem] = []
    @Published var hasLocationAccess = false
    @Published var selectedFeedItem: PostItem?
    @Published var errorMessage: String?
    @Published var showFilterSection: Bool = false
    @Published var newPostsAvailable: [PostItem] = []
    @Published var recenterMap = false

    // MARK: - Location
    @Published var userLatitude: Double?
    @Published var userLongitude: Double?
    let locationManager = LocationManager()

    // MARK: - Pagination (Simplified)
    private var currentPage = 1
    private var hasMoreData = true
    private let limit = DeveloperConstants.Network.pageLimit
    @Published var isLoadingMore = false

    // MARK: - Filter
    @Published var currentDistanceFilter: Double = 60.0
    @Published var currentGenderFilter: String = "All"

    // MARK: - Dependencies
    private let socketClient: SocketFeedClientProtocol
    private let permissionHelper = PermissionHelper()
    let routeManager = RouteManager.shared

    // MARK: - Internal State (Simplified)
    private var cancellables = Set<AnyCancellable>()
    private var isSocketConnected = false
    private var loadingTimeoutTimer: Timer?
    private let loadingTimeout: TimeInterval = 15.0 // Max 15 seconds loading

    // MARK: - Data Management
    private var postIdSet = Set<String>()

    init(socketClient: SocketFeedClientProtocol) {
        self.socketClient = socketClient
        setupLocationObserver()
        setupSocketListeners()
    }

    deinit {
        loadingTimeoutTimer?.invalidate()
        disconnectSocket()
    }

    // MARK: - Location Setup (Simplified)
    private func setupLocationObserver() {
        locationManager.$userLocation
            .compactMap { $0 }
            .removeDuplicates { abs($0.coordinate.latitude - $1.coordinate.latitude) < 0.001 &&
                abs($0.coordinate.longitude - $1.coordinate.longitude) < 0.001 }
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)

        locationManager.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                let hasAccess = (status == .authorizedWhenInUse || status == .authorizedAlways)
                self?.hasLocationAccess = hasAccess

                if !hasAccess && status != .notDetermined {
                    self?.setError("Location access required to load nearby posts")
                    self?.stopLoading() // Stop loading if no location access
                }
            }
            .store(in: &cancellables)
    }

    private func handleLocationUpdate(_ location: CLLocation) {
        userLatitude = location.coordinate.latitude
        userLongitude = location.coordinate.longitude
        hasLocationAccess = true
        clearError()
        // Auto-load data if we have no posts and not currently loading
        if feedItems.isEmpty && !isLoading && isInitialLoading {
            loadInitialData()
        }
    }

    // MARK: - Data Loading (Simplified)
    func loadInitialData() {
        guard hasLocationAccess,
              let lat = userLatitude,
              let long = userLongitude else {
            setError("Location not available")
            return
        }
        guard !isLoading else { return }
        isInitialLoading = true
        isLoading = true
        hasReceivedData = false
        clearError()
        resetPagination()
        clearData()
        connectAndLoadData(lat: lat, long: long)
    }

    func refreshData() {
        guard hasLocationAccess else {
            setError("Location access required")
            return
        }
        isInitialLoading = true
        isLoading = true
        hasReceivedData = false
        clearError()
        resetPagination()
        clearData()
        if let lat = userLatitude, let long = userLongitude {
            connectAndLoadData(lat: lat, long: long)
        }
    }

    func loadMoreData() {
        guard hasLocationAccess,
              !isLoadingMore,
              !isLoading,
              hasMoreData,
              let lat = userLatitude,
              let long = userLongitude else {
            return
        }

        debugPrint("📄 Loading more data...")
        currentPage += 1
        isLoadingMore = true

        loadDataFromSocket(lat: lat, long: long, append: true)
    }

    // MARK: - Loading State Management (Simplified)
    private func startLoading() {
        isLoading = true
        clearError()
        startLoadingTimeout()
    }

    private func stopLoading() {
        isLoading = false
        isLoadingMore = false
        stopLoadingTimeout()
        Loader.shared.stopLoading()
    }

    private func startLoadingTimeout() {
        loadingTimeoutTimer?.invalidate()
        loadingTimeoutTimer = Timer.scheduledTimer(withTimeInterval: loadingTimeout, repeats: false) { [weak self] _ in
            debugPrint("⏰ Loading timeout reached")
            self?.handleLoadingTimeout()
        }
    }

    private func stopLoadingTimeout() {
        loadingTimeoutTimer?.invalidate()
        loadingTimeoutTimer = nil
    }

    private func handleLoadingTimeout() {
        stopLoading()
        setError("Loading took too long. Please try again.")
    }

    // MARK: - Socket Operations (Simplified)
    private func connectAndLoadData(lat: Double, long: Double) {
        if isSocketConnected {
            loadDataFromSocket(lat: lat, long: long)
        } else {
            connectSocket { [weak self] success in
                if success {
                    self?.loadDataFromSocket(lat: lat, long: long)
                } else {
                    self?.stopLoading()
                    self?.setError("Failed to connect to server")
                }
            }
        }
    }

    private func connectSocket(completion: @escaping (Bool) -> Void) {
        debugPrint("🔌 Connecting to socket...")

        socketClient.connectSocket(with: DeveloperConstants.BaseURL.socketBaseURL)
            .receive(on: DispatchQueue.main)
            .sink { success in
                self.isSocketConnected = success
                completion(success)
            }
            .store(in: &cancellables)
    }

    private func loadDataFromSocket(lat: Double, long: Double, append: Bool = false) {
        let urlString = createURLForSocket()
        socketClient.listenForExploreFeedPosts(lat: lat, long: long, url: urlString)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.handleSocketCompletion(completion, append: append)
                },
                receiveValue: { [weak self] feedItems in
                    self?.handleSocketResponse(feedItems, append: append)
                }
            )
            .store(in: &cancellables)
    }

    private func handleSocketResponse(_ response: FeedItems, append: Bool) {
        let newPosts = response.posts ?? []
        if append {
            addUniquePostsToFeed(newPosts)
        } else {
            replaceFeedWithPosts(newPosts)
        }
        // Update pagination
        hasMoreData = feedItems.count < (response.totalCount ?? 0)
        // --- Immediate UI update logic ---
        if !newPosts.isEmpty {
            hasReceivedData = true
            isInitialLoading = false
            isLoading = false
        } else if feedItems.isEmpty {
            // If empty response, stop loading and mark as received
            hasReceivedData = true
            isInitialLoading = false
            isLoading = false
        }
        clearError()
    }

    private func handleSocketCompletion(_ completion: Subscribers.Completion<Error>, append: Bool) {
        isLoading = false
        isInitialLoading = false
        switch completion {
            case .finished:
                break
            case .failure(let error):
                setError("Failed to load posts: \(error.localizedDescription)")
        }
    }

    // MARK: - Data Management (Simplified)
    private func replaceFeedWithPosts(_ posts: [PostItem]) {
        clearData()
        addUniquePostsToFeed(posts)
    }

    private func addUniquePostsToFeed(_ posts: [PostItem]) {
        for post in posts {
            if !postIdSet.contains(post.id) {
                postIdSet.insert(post.id)
                feedItems.append(post)
            }
        }
    }

    private func clearData() {
        feedItems.removeAll()
        postIdSet.removeAll()
        selectedFeedItem = nil
        newPostsAvailable.removeAll()
    }

    private func resetPagination() {
        currentPage = 1
        hasMoreData = true
    }

    private func setError(_ message: String) {
        errorMessage = message
        debugPrint("❌ Error: \(message)")
    }

    private func clearError() {
        errorMessage = nil
    }

    private func disconnectSocket() {
        isSocketConnected = false
        socketClient.pauseListening()
        cancellables.removeAll()
    }

    // MARK: - Socket Listeners (Simplified)
    private func setupSocketListeners() {
        // Listen for new posts
        socketClient.getNewPostsPublisher()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] newPost in
                    self?.handleNewPost(newPost)
                }
            )
            .store(in: &cancellables)

        // Listen for expiredPostRefresh
        socketClient.getExpiredPostRefreshInExplore()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] _ in
                    debugPrint("🔄 Expired post refresh event received - refreshing data")
                    self?.refreshData()
                }
            )
            .store(in: &cancellables)
    }

    private func handleNewPost(_ newPost: PostItem) {
        guard !postIdSet.contains(newPost.id) else { return }

        postIdSet.insert(newPost.id)
        newPostsAvailable.append(newPost)
        feedItems.insert(newPost, at: 0)

        debugPrint("🆕 New post added: \(newPost.caption ?? "No caption")")
    }

    // MARK: - URL Building
    private func createURLForSocket() -> String {
        let basePath = DeveloperConstants.BaseURL.socketBaseURL +
        DeveloperConstants.Network.urlBaseAppender +
        URLBuilderConstants.ClientPathAppender.exploreActivities.rawValue

        var urlComponents = URLComponents(string: basePath)
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: "\(currentPage)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        return urlComponents?.url?.absoluteString ?? ""
    }
}

// MARK: - Public Methods
extension ExploreViewModel {
    func requestLocationAccess() {
        locationManager.requestLocationPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.hasLocationAccess = true
                    self?.clearError()
                    // Location update will trigger data loading automatically
                } else {
                    self?.setError("Location permission denied")
                }
            }
        }
    }

    func recenter() {
        recenterMap = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.recenterMap = false
        }
    }

    func acknowledgeNewPosts() {
        newPostsAvailable.removeAll()
    }

    func selectFeedItem(_ item: PostItem) {
        selectedFeedItem = item
    }

    @MainActor func openAppSettings() {
        permissionHelper.openAppSettings()
    }

    func shouldLoadMore(for item: PostItem) -> Bool {
        guard let index = feedItems.firstIndex(where: { $0.id == item.id }) else { return false }
        let threshold = max(0, feedItems.count - 3)
        return index >= threshold && hasMoreData && !isLoadingMore && !isLoading
    }

    // Filter methods
    func applyFilters() {
        refreshData()
    }

    func resetAllFilters() {
        currentDistanceFilter = 60.0
        currentGenderFilter = "All"
        applyFilters()
    }

    // Other methods
    func removePost(_ post: PostItem) {
        feedItems.removeAll { $0.postID == post.id }
        postIdSet.remove(post.id)
    }

    func updateCounts(receivedFeedItem: PostItem) {
        if let index = feedItems.firstIndex(where: { $0.postID == receivedFeedItem.postID }) {
            feedItems[index] = receivedFeedItem
        }
    }

    @MainActor func moveToUserProfileHome(for item: PostItem) {
        guard item.user?.userId != nil || item.user?.userId != "" else { return }
        let viewModel = ProfileMeAndOthersObservable(
            typeOfProfile: KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userID) ?? "" == item.user?.userId ? .personal : .others,
            userId: item.user?.userId ?? ""
        )
        routeManager.navigate(to: ProfileMeAndOthersRoute(
            viewmodel: viewModel
        ))
    }
}
