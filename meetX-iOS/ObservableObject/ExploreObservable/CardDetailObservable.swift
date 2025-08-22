//
//  CardDetailObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 07-06-2025.
//

import SwiftUI
import Combine
import AVKit

@MainActor
class CardDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentMediaIndex = 0
    @Published var player: AVPlayer?
    @Published var isMuted = false
    @Published var isTextExpanded = false
    @Published var showVideoControls = true
    @Published var isVideoPlaying = false
    @Published var hasVideoEnded = false
    @Published var animatePulse = false
    @Published var scrollOffset: CGFloat = 0
    @Published var dragOffset: CGSize = .zero
    @Published var animateContent = false
    @Published var isInterestSelected = false
    @Published var errorMessage: String? = nil
    @Published var showErrorToast: Bool = false
    @Published var feedItem: PostItem
    @Published var dismissCurrentViewEndPost: Bool = false
    @Published var showJoinedUserToast: Bool = false
    
    @Published var showTheSelectedUserProfile: String = ""
    @Published var showCommentView: Bool = false
    @Published var showEndConfirmation = false
    
    // MARK: - Private Properties
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var otherCancelables = Set<AnyCancellable>()
    private var controlsHideTimer: Timer?
    private let routeManager = RouteManager.shared
    
    // MARK: - Computed Properties
    var currentUserId: String {
        KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userID) ?? ""
    }
    
    var interestButtonTitle: String {
        if feedItem.userContext?.hasShownInterest == true {
            return "Interested" //Interest Accepted
        } else if feedItem.userContext?.isInterestRequested == true {
            return "Interest Requested"
        } else {
            return "Show Interest"
        }
    }
    
    var interestButtonImage: String {
        if feedItem.userContext?.hasShownInterest == true {
            return "heart.fill" //Interest Accepted
        } else if feedItem.userContext?.isInterestRequested == true {
            return "checkmark.seal.text.page.fill" // Interested Requested
        } else {
            return "hand.raised.fill" // Show Interest
        }
    }
    
    // MARK: - Initialization
    init(feedItem: PostItem) {
        self.feedItem = feedItem
        setupInitialState()
        
        $errorMessage
            .compactMap { $0 }
            .sink { error in
                self.showErrorToast.toggle()
            }
            .store(in: &otherCancelables)
    }
    
    // MARK: - Setup Methods
    private func setupInitialState() {
        isInterestSelected = feedItem.userContext?.hasShownInterest == true ||
        feedItem.userContext?.isInterestRequested == true
        
        // Start content animation
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            withAnimation(.easeOut(duration: 0.1)) {
                animateContent = true
            }
        }
        
        // Start pulse animation
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            animatePulse = true
        }
    }
    
    func setupInitialMedia() {
        guard let mediaFiles = feedItem.mediaFiles,
              let firstMedia = mediaFiles.first,
              firstMedia.type?.lowercased() == "video",
              let urlString = firstMedia.url,
              let videoURL = URL(string: urlString) else {
            return
        }
        
        Task { @MainActor in
            await setupPlayer(url: videoURL)
        }
    }
    
    // MARK: - Player Management
    @MainActor
    private func setupPlayer(url: URL) async {
        await cleanupPlayer()
        
        // Create player on background queue to avoid blocking main thread
        let newPlayer = await withCheckedContinuation { continuation in
            Task.detached {
                let player = AVPlayer(url: url)
                player.isMuted = await self.isMuted
                continuation.resume(returning: player)
            }
        }
        
        self.player = newPlayer
        
        // Setup time observer
        setupTimeObserver()
        
        // Setup auto-hide controls
        setupControlsAutoHide()
        
        // Start playing
        newPlayer.play()
        isVideoPlaying = true
    }
    
    private func setupTimeObserver() {
        guard let player = player else { return }
        
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                await self?.handlePlayerTimeUpdate(time)
            }
        }
    }
    
    @MainActor
    private func handlePlayerTimeUpdate(_ time: CMTime) async {
        guard let player = player else { return }
        
        let currentTime = CMTimeGetSeconds(time)
        let duration = CMTimeGetSeconds(player.currentItem?.duration ?? CMTime.zero)
        
        if currentTime >= duration - 0.1 && duration > 0 {
            hasVideoEnded = true
            isVideoPlaying = false
        }
    }
    
    private func setupControlsAutoHide() {
        controlsHideTimer?.invalidate()
        controlsHideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.showVideoControls = false
                }
            }
        }
    }
    
    @MainActor
    private func cleanupPlayer() async {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        controlsHideTimer?.invalidate()
        controlsHideTimer = nil
        
        player?.pause()
        player = nil
        isVideoPlaying = false
        hasVideoEnded = false
    }
    
    func cleanup() {
        Task { @MainActor in
            await cleanupPlayer()
        }
        cancellables.removeAll()
    }
    
    // MARK: - Media Handling
    func handleMediaChange(newIndex: Int) {
        guard let mediaFiles = feedItem.mediaFiles,
              newIndex < mediaFiles.count else {
            return
        }
        
        Task { @MainActor in
            await cleanupPlayer()
            
            let media = mediaFiles[newIndex]
            if media.type?.lowercased() == "video",
               let urlString = media.url,
               let videoURL = URL(string: urlString) {
                await setupPlayer(url: videoURL)
            }
        }
    }
    
    // MARK: - User Actions
    func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
        
        // Haptic feedback on background thread
        Task.detached {
            let impactFeedback = await UIImpactFeedbackGenerator(style: .medium)
            await impactFeedback.impactOccurred()
        }
    }
    
    func toggleTextExpansion() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isTextExpanded.toggle()
        }
    }
    
    func handleInterestTap() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            // isInterestSelected.toggle()
        }
        
        // Haptic feedback on background thread
        Task.detached {
            let impactFeedback = await UIImpactFeedbackGenerator(style: .medium)
            await impactFeedback.impactOccurred()
        }
        
        // TODO: Implement API call for interest action
        Task {
            await performInterestAction()
        }
    }
    
    func handlePageControlTap(index: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentMediaIndex = index
        }
        handleMediaChange(newIndex: index)
    }
    
    // MARK: - Stats Actions
    func handleLikeTap() {
        Task {
            await performLikeAction()
        }
        
        // Haptic feedback
        Task.detached {
            let impactFeedback = await UIImpactFeedbackGenerator(style: .light)
            await impactFeedback.impactOccurred()
        }
    }
    
    func handleCommentTap() {
        Task {
            await performCommentAction()
        }
    }
    
    func handleJoinedTap() {
        Task {
            await performJoinedAction()
        }
    }
    
    // MARK: - API Calls (Placeholder implementations)
    private func performInterestAction() async {
        handleShowInterest()
    }
    
    private func performLikeAction() async {
        handleLikeLivePost()
    }
    
    private func performCommentAction() async {
        showCommentView.toggle()
    }
    
    private func performJoinedAction() async {
        if self.feedItem.joinedUserTags?.count ?? 0 > 0 {
            self.showJoinedUserToast.toggle()
        }
    }
    
    // MARK: - Helper Methods
    func needsShowMoreButton(text: String) -> Bool {
        let lines = text.components(separatedBy: .newlines)
        return lines.count > 3 || text.count > 150
    }
    
    func updateScrollOffset(_ offset: CGFloat) {
        scrollOffset = offset
    }
}


// MARK: - Make Interest Button API
extension CardDetailViewModel {
    
    // MARK: - API call for making the interest
    func handleShowInterest() {
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
                    if response.success == true {
                        self.feedItem.updateFromFollowResponse(response)
                        self.errorMessage = response.message ?? "Successfull"
                    }else {
                        self.errorMessage = response.message ?? "Activity Expired or not available"
                    }
                }
            )
            .store(in: &cancellables)
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
    
    // Get current User ID
    var getCurrentUserID: String {
        UserDataManager.shared.getSecureUserData().userId ?? ""
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
}

// MARK: - Extension for handling the end live
extension CardDetailViewModel {
    
    // Handle the end live post and dismiss the view
    func handleEndLivePost() {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            self.errorMessage = "Failed to map"
            return
        }
        
        guard let postId = feedItem.postID else {
            self.errorMessage = "No valid post details found"
            return
        }
        
        Loader.shared.startLoading()
        
        let urlString = URLBuilderConstants.URLBuilder(type: .endLiveActivity)
        
        let queryParams: [String: String] = [
            "post_id": "\(postId)"
        ]
        
        let publisher: AnyPublisher<ConnectAcceptResponse, APIError> = apiService.genericPublisher(
            fromURLString: urlString,
            queryParameters: queryParams,
            httpMethod: .patch
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                guard let self = self else { return }
                
                Loader.shared.stopLoading()
                
                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.errorMessage = response.message
                self.dismissCurrentViewEndPost.toggle()
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Like a live post
    func handleLikeLivePost() {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            self.errorMessage = "Failed to map"
            return
        }
        
        guard let postId = feedItem.postID else {
            self.errorMessage = "No valid post details found"
            return
        }
        
        Loader.shared.startLoading()
        
        let urlString = URLBuilderConstants.URLBuilder(type: .toggleLikeandDislike)
        
        let queryParams: [String: String] = [
            "postId": "\(postId)"
        ]
        
        let publisher: AnyPublisher<LikeResponseExplore, APIError> = apiService.genericPublisher(
            fromURLString: urlString,
            queryParameters: queryParams,
            httpMethod: .post
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                guard let self = self else { return }
                
                Loader.shared.stopLoading()
                
                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.feedItem.updateLikeStatus(
                    success: response.success ?? false,
                    totalLikesR: response.totalLikes ?? 0
                )
            })
            .store(in: &cancellables)
    }
}
