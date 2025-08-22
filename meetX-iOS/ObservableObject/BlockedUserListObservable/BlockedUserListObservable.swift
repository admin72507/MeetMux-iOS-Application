import Foundation
import Combine
import SwiftUI

class BlockedUsersObservable: ObservableObject {
    @Published var blockedUsers: [BlockedUser] = []
    @Published var filteredConnections: [BlockedUser] = []
    @Published var searchText: String = ""
    @Published var showActionSheet: Bool = false
    @Published var userToModify: BlockedUser?
    
    private var currentPage: Int = 1
    private let pageSize: Int = 20
    private var canLoadMore: Bool = true
    private var isLoading: Bool = false
    
    private var searchPage: Int = 1
    private var canLoadMoreSearch: Bool = true
    private var isSearchLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Single unblock User
    @Published var showSingleBlockUserAlert: Bool = false
    var responseMessage : String = ""
    let routeManager = RouteManager.shared
    
    init() {
        setupSearchPipeline()
        loadInitialConnections()
    }
    
    private func setupSearchPipeline() {
        $searchText
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self = self else { return }
                if text.isEmpty {
                    self.filteredConnections = self.blockedUsers
                } else {
                    self.searchPage = 1
                    self.canLoadMoreSearch = true
                    self.filteredConnections = []
                    self.searchBlockedUsers(query: text, page: self.searchPage)
                }
            }
            .store(in: &cancellables)
    }
    
    func loadInitialConnections() {
        currentPage = 1
        canLoadMore = true
        blockedUsers = []
        filteredConnections = []
        fetchConnections()
    }
    
    func loadMoreConnections() {
        guard !isLoading && canLoadMore && searchText.isEmpty else { return }
        currentPage += 1
        fetchConnections()
    }
    
    func loadMoreSearchResults() {
        guard !isSearchLoading && canLoadMoreSearch && !searchText.isEmpty else { return }
        searchPage += 1
        searchBlockedUsers(query: searchText, page: searchPage)
    }
    
    private func fetchConnections() {
        isLoading = true
        Loader.shared.startLoading()
        
        fetchBlockedUsers(page: currentPage) { model in
            guard let users = model.data else {
                self.canLoadMore = false
                Loader.shared.stopLoading()
                return
            }
            
            self.canLoadMore = !users.isEmpty
            self.blockedUsers.append(contentsOf: users)
            self.filteredConnections = self.blockedUsers
            Loader.shared.stopLoading()
            self.isLoading = false
        } failure: { error in
            print("Error fetching blocked users: \(error)")
            self.isLoading = false
            Loader.shared.stopLoading()
        }
    }
    
    @MainActor func navigateToProfile(_ user: BlockedUser) {
        guard user.userId != nil || user.userId != "" else { return }
        let viewModel = ProfileMeAndOthersObservable(
            typeOfProfile: .others,
            userId: user.userId ?? ""
        )
        routeManager.navigate(to: ProfileMeAndOthersRoute(
            viewmodel: viewModel
        ))
    }
    
    private func searchBlockedUsers(query: String, page: Int) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else { return }
        
        let urlString = URLBuilderConstants.URLBuilder(type: .searchTheBlockedUserList)
        let queryParams = [
            "searchQuery": query,
            "page": "\(page)",
            "limit": "\(DeveloperConstants.Network.pageLimit)"
        ]
        
        isSearchLoading = true
        Loader.shared.startLoading()
        
        let publisher: AnyPublisher<BlockedUserListModel, APIError> = apiService.genericPublisher(
            fromURLString: urlString,
            queryParameters: queryParams
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                self.isSearchLoading = false
                Loader.shared.stopLoading()
                if case .failure(let error) = completion {
                    print("Search failed: \(error)")
                }
            }, receiveValue: { response in
                let newResults = response.data ?? []
                self.canLoadMoreSearch = !newResults.isEmpty
                if page == 1 {
                    self.filteredConnections = newResults
                } else {
                    self.filteredConnections.append(contentsOf: newResults)
                }
            })
            .store(in: &cancellables)
    }
    
    func prepareAction(for user: BlockedUser) {
        self.userToModify = user
        self.showActionSheet = true
    }
    
    func clearAction() {
        self.userToModify = nil
        self.showActionSheet = false
    }
    
    func performAction() {
        guard let user = userToModify, let userId = user.userId else { return }
        
        unBlockUserCall(
            receivedUserId: userId,
            completion: {status in
                if status {
                    self.blockedUsers.removeAll { $0.userId == userId }
                    self.filteredConnections.removeAll { $0.userId == userId }
                    self.clearAction()
                }
                Loader.shared.startLoading()
                if self.searchText.isEmpty {
                    self.loadInitialConnections()
                } else {
                    self.searchPage = 1
                    self.canLoadMoreSearch = true
                    self.filteredConnections = []
                    self.searchBlockedUsers(query: self.searchText, page: self.searchPage)
                }
            },
            failure: {error in
                
            })
    }
    
    // MARK: - Fetch Blocked Users
    private func fetchBlockedUsers(
        page: Int,
        completion: @escaping (BlockedUserListModel) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            failure(APIError.apiFailed(underlyingError: nil))
            return
        }
        
        let urlString = URLBuilderConstants.URLBuilder(type: .getTheBlockedUserList)
        let queryParams = [
            "page": "\(page)",
            "limit": "\(DeveloperConstants.Network.pageLimit)"
        ]
        
        let publisher: AnyPublisher<BlockedUserListModel, APIError> = apiService.genericPublisher(
            fromURLString: urlString,
            queryParameters: queryParams
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                if case .failure(let error) = result {
                    failure(error)
                }
            }, receiveValue: { blockedUserListModel in
                completion(blockedUserListModel)
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Unblock Action
    func unBlockUserCall(
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
            
            let publisher: AnyPublisher<UnblockUserResponse, APIError> = apiService.genericPublisher(
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
                }, receiveValue: { [weak self] unBlockSingle in
                    Loader.shared.stopLoading()
                    self?.responseMessage = unBlockSingle.message
                    completion(unBlockSingle.success)
                })
                .store(in: &cancellables)
        }
}
