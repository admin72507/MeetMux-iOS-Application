//
//  TagPeopleObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 20-05-2025.
//
import Combine
import SwiftUI

final class TagPeopleViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchText: String = ""
    @Published private(set) var allConnections: [ConnectedUser] = []
    @Published private(set) var filteredConnections: [ConnectedUser] = []
    @Published var selectedConnections: Set<ConnectedUser> = []
    @Published var showActionSheet = false
    @Published var userToModify: ConnectedUser?
    @Published var actionType: ConnectionActionType?
    
    // MARK: - Pagination
    private(set) var currentPage = 1
    private var totalCount = Int.max
    private let limit = DeveloperConstants.Network.pageLimit
    private var isLoading = false
    private var cancellables = Set<AnyCancellable>()
    let routeManager = RouteManager.shared
    
    // MARK: - State
    private var isSearching = false
    let id = UUID()
    
    // MARK: - Single block User
    @Published var showSingleBlockUserAlert: Bool = false
    var responseMessage : String = ""
    
    // MARK: - Init
    init(selectedConnections: Set<ConnectedUser>) {
        self.selectedConnections = selectedConnections
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.handleSearch(text: text)
            }
            .store(in: &cancellables)
    }
    
    private func handleSearch(text: String) {
        if text.isEmpty {
            isSearching = false
            filteredConnections = allConnections
        } else {
            isSearching = true
            searchConnections(query: text)
        }
    }
    
    func isSelected(_ user: ConnectedUser) -> Bool {
        return selectedConnections.contains(user)
    }
    
    func toggleSelection(for user: ConnectedUser) {
        if selectedConnections.contains(user) {
            selectedConnections.remove(user)
        } else {
            selectedConnections.insert(user)
        }
    }
    
    private func searchConnections(query: String) {
        guard !isLoading else { return }
        isLoading = true
        Loader.shared.startLoading()
        
        handleFriendsList(page: 1, searchQuery: query) { [weak self] model in
            guard let self = self else { return }
            self.filteredConnections = model.connectedUsers ?? []
            self.isLoading = false
            Loader.shared.stopLoading()
        } failure: { [weak self] error in
            print("Search Error:", error.localizedDescription)
            self?.isLoading = false
            Loader.shared.stopLoading()
        }
    }
    
    // MARK: - Data Loading
    func loadInitialConnections() {
        guard !isSearching else { return }
        currentPage = 1
        totalCount = Int.max
        allConnections = []
        filteredConnections = []
        loadMoreConnections()
    }
    
    func loadMoreConnections() {
        guard !isLoading,
              !isSearching,
              allConnections.count < totalCount,
              (currentPage - 1) * limit < totalCount else { return }
        
        isLoading = true
        Loader.shared.startLoading()
        
        handleFriendsList(page: currentPage) { [weak self] model in
            guard let self = self else { return }
            
            let users = model.connectedUsers ?? []
            self.totalCount = model.totalCount ?? self.totalCount
            self.allConnections += users
            self.currentPage += 1
            self.filteredConnections = self.allConnections
            
            self.isLoading = false
            Loader.shared.stopLoading()
        } failure: { [weak self] error in
            print("Error:", error.localizedDescription)
            self?.isLoading = false
            Loader.shared.stopLoading()
        }
    }
    
    func resetSelections() {
        selectedConnections.removeAll()
    }
    
    // MARK: - API Call
    func handleFriendsList(
        page: Int,
        limit: Int = DeveloperConstants.Network.pageLimit,
        searchQuery: String? = nil,
        completion: @escaping (ConnectionListModel) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            failure(APIError.apiFailed(underlyingError: nil))
            return
        }
        
        let urlString = URLBuilderConstants.URLBuilder(type: .tagConnectionList)
        
        var queryParams: [String: String]
        if let search = searchQuery, !search.isEmpty {
            queryParams = ["query": search]
        } else {
            queryParams = [
                "page": "\(page)",
                "limit": "\(limit)"
            ]
        }
        
        let publisher: AnyPublisher<ConnectionListModel, APIError> = apiService.genericPublisher(fromURLString: urlString, queryParameters: queryParams)
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                if case .failure(let error) = result {
                    self.isLoading = false
                    Loader.shared.stopLoading()
                    failure(error)
                }
            }, receiveValue: { connectionListModel in
                self.isLoading = false
                Loader.shared.stopLoading()
                completion(connectionListModel)
            })
            .store(in: &cancellables)
    }
    
    func removeConnection(user: ConnectedUser) {
        filteredConnections.removeAll { $0.userId == user.userId }
        allConnections.removeAll { $0.userId == user.userId }
    }
    
    func blockConnection(user: ConnectedUser) {
        blockUserCall(
            receivedUserId: user.userId ?? "",
            completion: { [weak self] _ in
                self?.removeConnection(user: user)
                self?.showSingleBlockUserAlert = true
                
                if let self = self,
                   self.filteredConnections.count < (self.currentPage - 1) * self.limit {
                    self.loadMoreConnections()
                }
            },
            failure: { [weak self] _ in
                self?.showSingleBlockUserAlert = true
            })
    }
    
    @MainActor func navigateToProfile(_ user: ConnectedUser) {
        guard user.userId != nil || user.userId != "" else { return }
        let viewModel = ProfileMeAndOthersObservable(
            typeOfProfile: .others,
            userId: user.userId ?? ""
        )
        routeManager.navigate(to: ProfileMeAndOthersRoute(
            viewmodel: viewModel
        ))
    }
    
    func prepareAction(for user: ConnectedUser, type: ConnectionActionType) {
        self.userToModify = user
        self.actionType = type
        self.showActionSheet = true
    }
    
    func performAction() {
        guard let user = userToModify, let action = actionType else { return }
        switch action {
            case .delete:
                removeConnection(user: user)
            case .block:
                blockConnection(user: user)
        }
        clearAction()
    }
    
    func clearAction() {
        userToModify = nil
        actionType = nil
        showActionSheet = false
    }
    
    // MARK: - Block a User
    func blockUserCall(
        receivedUserId: String,
        completion: @escaping (Bool) -> Void,
        failure: @escaping (Error) -> Void) {
            guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
                failure(APIError.apiFailed(underlyingError: nil))
                return
            }
            Loader.shared.startLoading()
            
            let urlString = URLBuilderConstants.URLBuilder(type: .blockUser)
            let queryParams = [
                "userId": "\(receivedUserId)"
            ]
            
            let publisher: AnyPublisher<BlockSingleUser, APIError> = apiService.genericPublisher(
                fromURLString: urlString,
                queryParameters: queryParams
            )
            
            publisher
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] result in
                    if case .failure(let error) = result {
                        Loader.shared.stopLoading()
                        self?.responseMessage = error.localizedDescription
                        failure(error)
                    }
                }, receiveValue: { [weak self] blockSingle in
                    Loader.shared.stopLoading()
                    self?.responseMessage = blockSingle.message
                    completion(blockSingle.success)
                })
                .store(in: &cancellables)
        }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

enum ConnectionActionType {
    case delete
    case block
}
