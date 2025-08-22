//
//  SearchRecommendationsObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 30-05-2025.
//
import Combine
import SwiftUI

class SearchRecommendationsObservable: ObservableObject {
    
    @Published var recommendedUsersList: [RecommendedUser] = []
    @Published var searchUsersList: [UserSearch] = []
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    // MARK: - Action Button Publishers
    @Published var actionFollowButtonTypes: PassthroughSubject<(userId: String, action: DeveloperConstants.FollowActionType), Never> = .init()
    @Published var connectionActionButtonTypes: PassthroughSubject<(userId: String, action: ConnectionActionType), Never> = .init()
    
    // MARK: - Pagination for Recommended User
    var currentPage = 1
    private var totalCount = Int.max
    
    // MARK: - Pagination for Search Recommended User
    var currentPageSearch = 1
    private var totalCountSearch = Int.max
    private var currentSearchQuery = ""
    
    private let limit = DeveloperConstants.Network.pageLimit
    var cancellables = Set<AnyCancellable>()
    let routeManager = RouteManager.shared
    
    // Action button for connect
    enum ConnectionActionType {
        case removeConnectionRequest  // Cancel pending connection request
        case sendConnectionRequest    // Send new connection request
        case removeConnection        // Remove existing connection
    }
    
    init() {
        setupActionButtonSink()
    }
    
    func getTheRecommendedUsers() {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            return
        }
        
        let urlString = URLBuilderConstants.URLBuilder(type: .recommendedProfiles)
        
        var queryParams: [String: String]
        
        queryParams = [
            "offset": "\(currentPage)",
            "limit": "\(limit)"
        ]
        
        let publisher: AnyPublisher<SearchRecommendationsModel, APIError> = apiService.genericPublisher(fromURLString: urlString, queryParameters: queryParams)
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                    Loader.shared.stopLoading()
                }
            }, receiveValue: { [weak self] connectionListModel in
                guard let self else { return }
                Loader.shared.stopLoading()
                if self.currentPage == 1 {
                    self.recommendedUsersList = connectionListModel.data
                } else {
                    self.recommendedUsersList.append(contentsOf: connectionListModel.data)
                }
            })
            .store(in: &cancellables)
    }
    
    @MainActor func moveToUserProfileHome(for item: RecommendedUser) {
        guard item.userId != "" else { return }
        let viewModel = ProfileMeAndOthersObservable(
            typeOfProfile: KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userID) ?? "" == item.userId ? .personal : .others,
            userId: item.userId
        )
        routeManager.navigate(to: ProfileMeAndOthersRoute(
            viewmodel: viewModel
        ))
    }
    
    @MainActor func moveToUserProfileHome(for item: UserSearch) {
        guard let userId = item.userId, !userId.isEmpty else { return }
        let viewModel = ProfileMeAndOthersObservable(
            typeOfProfile: KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userID) ?? "" == userId ? .personal : .others,
            userId: userId
        )
        routeManager.navigate(to: ProfileMeAndOthersRoute(
            viewmodel: viewModel
        ))
    }
    
    func searchRecommendations(_ searchQuery: String) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            return
        }
        
        // If it's a new search query, reset pagination
        if currentSearchQuery != searchQuery {
            currentSearchQuery = searchQuery
            currentPageSearch = 1
            searchUsersList.removeAll()
        }
        
        // Prevent duplicate API calls for same page
        guard currentPageSearch <= totalCountSearch else { return }
        
        isLoading = true
        
        let urlString = URLBuilderConstants.URLBuilder(type: .searchUser)
        
        var queryParams: [String: String]
        
        queryParams = [
            "user": "\(searchQuery)",
            "offset": "\(currentPageSearch)",
            "limit": "\(limit)"
        ]
        
        let publisher: AnyPublisher<SearchUserResponseModel, APIError> = apiService.genericPublisher(fromURLString: urlString, queryParameters: queryParams)
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                guard let self else { return }
                self.isLoading = false
                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                    print("Search Error: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] searchResponse in
                guard let self else { return }
                self.isLoading = false
                
                // Update total count for pagination
                if let count = searchResponse.count {
                    self.totalCountSearch = max(1, Int(ceil(Double(count) / Double(self.limit))))
                }
                
                // Handle the response data
                if let searchData = searchResponse.data {
                    if self.currentPageSearch == 1 {
                        // First page - replace existing data
                        self.searchUsersList = searchData
                    } else {
                        // Subsequent pages - append new data
                        self.searchUsersList.append(contentsOf: searchData)
                    }
                } else {
                    // No data received
                    if self.currentPageSearch == 1 {
                        self.searchUsersList.removeAll()
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    func loadMoreSearchResults() {
        guard !isLoading && currentPageSearch < totalCountSearch && !currentSearchQuery.isEmpty else {
            return
        }
        
        currentPageSearch += 1
        searchRecommendations(currentSearchQuery)
    }
    
    func clearSearchResults() {
        searchUsersList.removeAll()
        currentSearchQuery = ""
        currentPageSearch = 1
        totalCountSearch = Int.max
    }
    
    // MARK: - Helper method to update user in array
    private func updateRecommendedUser(userId: String, updater: (inout RecommendedUser) -> Void) {
        if let index = recommendedUsersList.firstIndex(where: { $0.userId == userId }) {
            updater(&recommendedUsersList[index])
        }
    }
    
    private func updateSearchUser(userId: String, updater: (inout UserSearch) -> Void) {
        if let index = searchUsersList.firstIndex(where: { $0.userId == userId }) {
            updater(&searchUsersList[index])
        }
    }
}

// MARK: - Extension For Action Button Setup
extension SearchRecommendationsObservable {
    
    private func setupActionButtonSink() {
        actionFollowButtonTypes
            .sink { [weak self] (userId, actionType) in
                self?.handleFollowButtonAction(userId: userId, actionType: actionType)
            }
            .store(in: &cancellables)
        
        connectionActionButtonTypes
            .sink { [weak self] (userId, actionType) in
                self?.handleConnectionRequestStatus(userId: userId, actionType: actionType)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Extension For Connect Handler
extension SearchRecommendationsObservable {
    
    /// Function to handle the API call and other systems
    private func handleConnectionRequestStatus(userId: String, actionType: ConnectionActionType) {
        
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            self.errorMessage = "Failed to map"
            return
        }
        
        Loader.shared.startLoading()
        
        let urlString = URLBuilderConstants.URLBuilder(type: .connectSystem)
        let requestParams = ConnectionRequest(targetUserId: userId)
        
        let publisher: AnyPublisher<ConnectAndFollowModel, APIError> = apiService.genericPostPublisher(
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
                    
                    // Find and update the user in recommendedUsersList
                    if let index = self.recommendedUsersList.firstIndex(where: { $0.userId == userId }) {
                        self.recommendedUsersList[index].updateFromConnectResponseSuggestion(response)
                    }
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Extension for Follow Handler
extension SearchRecommendationsObservable {
    
    /// Function to handle the follow button action
    // Similar approach for follow handler
    private func handleFollowButtonAction(userId: String, actionType: DeveloperConstants.FollowActionType) {
        
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            self.errorMessage = "Failed to map"
            return
        }
        
        Loader.shared.startLoading()
        
        let urlString = URLBuilderConstants.URLBuilder(type: .unFollowFollowBack)
        let requestParams = ConnectionRequest(targetUserId: userId)
        
        let publisher: AnyPublisher<UnFollowFollowBackResponse, APIError> = apiService.genericPostPublisher(
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
                    
                    // Find and update the user in recommendedUsersList
                    if let index = self.recommendedUsersList.firstIndex(where: { $0.userId == userId }) {
                        _ = self.recommendedUsersList[index].updateFromFollowResponse(response, expectedAction: actionType)
                    }
                }
            )
            .store(in: &cancellables)
    }
}
