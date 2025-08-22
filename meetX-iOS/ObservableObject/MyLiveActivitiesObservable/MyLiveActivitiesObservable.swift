//
//  MyLiveActivitiesObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 08-06-2025.
//
import Foundation
import SwiftUI
import Combine

// MARK: - ViewModel
class MyLiveActivitiesObservable: ObservableObject {
    @Published var feedItemsObjects: ActivityResponse?
    @Published var allActivities: [PostItem] = []
    @Published var filteredActivities: [PostItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var selectedActivity: PostItem?
    @Published var showingDetail = false
    @Published var selectedSegment: DeveloperConstants.MyLiveActivitisSegments = .plannedActivity
    @Published var showToastMessage: Bool = false
    @Published var errorMessage: String? = nil
    @Published var hasNoData: Bool = false
    
    // Properties for user tags selections
    @Published var showAllPeopleTag: Bool = false
    @Published var peopleTagList: [PeopleTags] = []
    
    // Show comments bottom sheet
    @Published var commentViewPostId: String? = ""
    @Published var showCommentsBottomSheet: Bool = false
    
    var cancellables = Set<AnyCancellable>()
    var otherCancellables = Set<AnyCancellable>()
    private var currentPage: Int = 1
    private var totalPages: Int = 1
    var canLoadMore: Bool = true
    let helperFunctions = HelperFunctions()
    let routeManager = RouteManager.shared
    
    // FIXED: Computed properties for counts - corrected filtering logic
    var plannedActivities: [PostItem] {
        // Planned activities are anything that's NOT liveactivity
        allActivities.filter { $0.postType?.lowercased() != "liveactivity" }
    }
    
    var liveActivities: [PostItem] {
        allActivities.filter { $0.postType?.lowercased() == "liveactivity" }
    }
    
    var plannedCount: Int { plannedActivities.count }
    var liveCount: Int { liveActivities.count }
    
    init() {
        // When people tag is inserted
        $peopleTagList
            .sink { [weak self] peopleTags in
                if peopleTags.count > 0 {
                    self?.showAllPeopleTag.toggle()
                }
            }
            .store(in: &otherCancellables)
        
        $errorMessage
            .compactMap { $0 }
            .sink { error in
                self.showToastMessage.toggle()
            }
            .store(in: &otherCancellables)
        
        // Listen to segment changes and update filtered activities
        $selectedSegment
            .sink { [weak self] segment in
                self?.updateFilteredActivities()
            }
            .store(in: &otherCancellables)
        
        // Update filtered activities when all activities change
        $allActivities
            .sink { [weak self] _ in
                self?.updateFilteredActivities()
                self?.updateNoDataState()
            }
            .store(in: &otherCancellables)
    }
    
    private func updateFilteredActivities() {
        switch selectedSegment {
            case .plannedActivity:
                filteredActivities = plannedActivities
            case .liveActivity:
                filteredActivities = liveActivities
        }
    }
    
    private func updateNoDataState() {
        hasNoData = filteredActivities.isEmpty && !isLoading
    }
    
    func resetPagination() {
        currentPage = 1
        totalPages = 1
        allActivities.removeAll()
        canLoadMore = true
        hasNoData = false
        updateFilteredActivities()
    }
    
    func loadMoreIfNeeded() {
        guard canLoadMore && !isLoadingMore && currentPage < totalPages else { return }
        
        // Check if we need more items for the current segment
        let currentFilteredCount = filteredActivities.count
        
        // Load more if we have less than 10 items in current filter but have more pages
        if currentFilteredCount < 10 && currentPage < totalPages {
            loadMoreActivities()
        }
    }
    
    private func loadMoreActivities() {
        currentPage += 1
        listAllActivitiesPosted(isLoadMore: true)
    }
}

// MARK: - Fetch all activities with client-side filtering
extension MyLiveActivitiesObservable {
    
    func loadInitialData() {
        resetPagination()
        listAllActivitiesPosted(isLoadMore: false)
    }
    
    func listAllActivitiesPosted(isLoadMore: Bool = false) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else { return }
        
        let urlString = URLBuilderConstants.URLBuilder(type: .fetchAllUserActivities)
        
        let queryParams: [String: String] = [
            "page": "\(currentPage)",
            "limit": "\(DeveloperConstants.Network.pageLimit)"
        ]
        
        if !isLoadMore {
            isLoading = true
            hasNoData = false
            Loader.shared.startLoading()
        } else {
            isLoadingMore = true
        }
        
        let publisher: AnyPublisher<ActivityResponse, APIError> = apiService.genericPublisher(
            fromURLString: urlString,
            queryParameters: queryParams
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                if !isLoadMore {
                    self.isLoading = false
                    Loader.shared.stopLoading()
                } else {
                    self.isLoadingMore = false
                }
                
                if case .failure(let error) = completion {
                    debugPrint("Fetch failed: \(error)")
                    self.errorMessage = error.localizedDescription
                    
                    // Reset page count on error
                    if isLoadMore {
                        self.currentPage = max(1, self.currentPage - 1)
                    }
                }
                
                // Update no data state after completion
                self.updateNoDataState()
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                self.feedItemsObjects = response
                self.totalPages = response.totalPages
                self.canLoadMore = response.currentPage < response.totalPages
                
                if isLoadMore {
                    // Append new activities to existing list
                    self.allActivities.append(contentsOf: response.activities)
                } else {
                    // Replace with new activities
                    self.allActivities = response.activities
                }
                
                // ADDED: Force update of filtered activities after data load
                DispatchQueue.main.async {
                    self.updateFilteredActivities()
                }
            })
            .store(in: &cancellables)
    }
    
    func onSegmentChanged(to segment: DeveloperConstants.MyLiveActivitisSegments) {
        selectedSegment = segment
        
        // ADDED: Immediate update of filtered activities
        updateFilteredActivities()
        
        // Check if we need to load more data for the current segment
        // If current segment has very few items and we can load more, fetch next page
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.loadMoreIfNeeded()
        }
    }
    
    func refreshData() {
        loadInitialData()
    }
    
    // Helper method to get activities count for a specific type
    func getActivitiesCount(for type: DeveloperConstants.MyLiveActivitisSegments) -> Int {
        switch type {
            case .plannedActivity:
                return plannedCount
            case .liveActivity:
                return liveCount
        }
    }
    
    // Method to check if we should load more based on current segment
    private func shouldLoadMoreForCurrentSegment() -> Bool {
        let currentSegmentCount = getActivitiesCount(for: selectedSegment)
        return currentSegmentCount < 5 && canLoadMore // Load more if less than 5 items for current segment
    }
}

// MARK: - Extension for Post End
extension MyLiveActivitiesObservable {
    
    func handleEndPlannedLivePost(
        _ postID: String,
        _ selectedSegment : DeveloperConstants.MyLiveActivitisSegments
    ) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            self.errorMessage = "Failed to map"
            return
        }
        
        Loader.shared.startLoading()
        
        let urlString = URLBuilderConstants.URLBuilder(type: .endLiveActivity)
        
        let queryParams: [String: String] = [
            "post_id": "\(postID)"
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
                
                if let index = allActivities.firstIndex(where: { $0.postID == postID }) {
                    allActivities.remove(at: index)
                }
                self.selectedSegment = selectedSegment
                
            })
            .store(in: &cancellables)
    }
    
    // Get current User ID
    var getCurrentUserID: String {
        KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userID) ?? ""
    }
  
    @MainActor func moveToTaggedUserProfile(for userId: String) {
        guard userId != "" else { return }
        let viewModel = ProfileMeAndOthersObservable(
            typeOfProfile: getCurrentUserID == userId ? .personal : .others,
            userId: userId
        )
        showAllPeopleTag.toggle()
        routeManager.navigate(to: ProfileMeAndOthersRoute(
            viewmodel: viewModel
        ))
    }
    
    // MARK: - Like a post
    func handleLikeLivePost(postId: String) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            self.errorMessage = "Failed to map"
            return
        }
        
        guard postId != "" else {
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
                self.updateLikeStatus(
                    success: response.success ?? false,
                    totalLikesR: response.totalLikes ?? 0,
                    postId: response.postId ?? ""
                )
            })
            .store(in: &cancellables)
    }
    
    private func updateLikeStatus(success: Bool, totalLikesR: Int, postId: String) {
        guard success else { return }
        
        if let index = filteredActivities.firstIndex(where: { $0.postID == postId }) {
            filteredActivities[index].totalLikes = totalLikesR
            filteredActivities[index].userContext?.hasLiked = totalLikesR > 0
        }
    }
}
