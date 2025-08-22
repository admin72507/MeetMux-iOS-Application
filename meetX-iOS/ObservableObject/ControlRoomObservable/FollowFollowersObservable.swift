//
//  FollowFollowersObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 22-05-2025.
//

import Foundation
import Combine

class FollowFollowersObservable: ObservableObject {
    
    @Published var selectedSegment: DeveloperConstants.FollowFollowersList = .Following {
        didSet {
            if oldValue != selectedSegment {
                page = 1
                canLoadMoreSearch = true // Reset pagination flag
                if !shouldPreventRedundantSegmentRequest() {
                    fetchConnections()
                }
            }
        }
    }
    
    @Published var followFollowingSearchText: String = ""
    @Published var filteredConnections: [FollowingFollowersItem] = []
    @Published var isSearchLoading = false
    
    private var lastQuery: String = ""
    private var lastSegment: DeveloperConstants.FollowFollowersList = .Following
    private var cancellables = Set<AnyCancellable>()
    private var searchDebounceCancellable: AnyCancellable?
    
    @Published var errorMessage: String = ""
    @Published var showToastMessage: Bool = false
    let routeManager = RouteManager.shared
    
    private var page: Int = 1
    var canLoadMoreSearch: Bool = true
    private var totalCount: Int = 0 // Add total count tracking
    
    init() {
        observeSearch()
    }
    
    // MARK: - Observe Search Text
    private func observeSearch() {
        $followFollowingSearchText
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self = self else { return }
                self.page = 1
                self.canLoadMoreSearch = true // Reset pagination flag on new search
                self.fetchConnections()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Avoid Redundant API Calls on Segment Switch
    private func shouldPreventRedundantSegmentRequest() -> Bool {
        return lastSegment == selectedSegment && lastQuery == followFollowingSearchText
    }
    
    @MainActor func navigateToProfile(_ user: FollowingFollowersItem) {
        guard user.userId != nil || user.userId != "" else { return }
        let viewModel = ProfileMeAndOthersObservable(
            typeOfProfile: .others,
            userId: user.userId ?? ""
        )
        routeManager.navigate(to: ProfileMeAndOthersRoute(
            viewmodel: viewModel
        ))
    }
    
    // MARK: - Fetch API Based on Segment + Query
    private func fetchConnections() {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else { return }
        
        let urlString = URLBuilderConstants.URLBuilder(type: .followList)
        let type = selectedSegment == .Following ? "following" : "followers"
        
        let queryParams: [String: String] = [
            "type": type,
            "page": "\(page)",
            "limit": "\(DeveloperConstants.Network.pageLimit)",
            "query": followFollowingSearchText
        ]
        
        lastSegment = selectedSegment
        lastQuery = followFollowingSearchText
        isSearchLoading = true
        Loader.shared.startLoading()
        
        let publisher: AnyPublisher<FollowingFollowersModel, APIError> = apiService.genericPublisher(
            fromURLString: urlString,
            queryParameters: queryParams
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isSearchLoading = false
                Loader.shared.stopLoading()
                if case .failure(let error) = completion {
                    print("Search failed: \(error)")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                let newResults = response.data ?? []
                
                // Update total count if available from API response
                if let total = response.totalCount {
                    self.totalCount = total
                }
                
                // Check if we can load more based on current data count vs total
                let currentCount = self.page == 1 ? newResults.count : self.filteredConnections.count + newResults.count
                self.canLoadMoreSearch = currentCount < self.totalCount && !newResults.isEmpty
                
                // Alternative: If API doesn't provide totalCount, use this logic
                // self.canLoadMoreSearch = newResults.count == DeveloperConstants.Network.pageLimit
                
                if self.page == 1 {
                    self.filteredConnections = newResults
                } else {
                    self.filteredConnections.append(contentsOf: newResults)
                }
                
                print("Page: \(self.page), New results: \(newResults.count), Total items: \(self.filteredConnections.count), Can load more: \(self.canLoadMoreSearch)")
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Load More
    func loadMoreIfNeeded(currentItem: FollowingFollowersItem) {
        guard canLoadMoreSearch,
              !isSearchLoading,
              let last = filteredConnections.last,
              last.id == currentItem.id else {
            return
        }
        
        print("Loading more... Current page: \(page)")
        page += 1
        fetchConnections()
    }
    
    // MARK: - Unfollow
    func handleUnfollow(user: FollowingFollowersItem) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else { return }
        
        let requestBody = UnFollowFollowBackRequest(
            targetUserId: user.userId ?? "")
        
        apiService.genericPostPublisher(
            toURLString: URLBuilderConstants.URLBuilder(type: .unFollowFollowBack),
            requestBody: requestBody,
            isAuthNeeded: true)
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            guard let self = self else { return }
            switch completion {
                case let .failure(error):
                    showToastMessage.toggle()
                    errorMessage = error.localizedDescription
                case .finished:
                    break
            }
            Loader.shared.stopLoading()
        }, receiveValue: { [weak self] (response: UnFollowFollowBackResponse) in
            guard let self = self else { return }
            self.showToastMessage.toggle()
            self.errorMessage = response.message ?? ""
            if self.selectedSegment == .Following {
                self.filteredConnections.removeAll { $0.userId == user.userId }
                // Update total count when removing items
                self.totalCount = max(0, self.totalCount - 1)
            }
        })
        .store(in: &cancellables)
    }
}
