//
//  CommentsBottomSheetObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 09-06-2025.
//
import Combine
import SwiftUI
import Foundation

// MARK: - Comments ViewModel

class CommentsViewModel: ObservableObject {
    
    @Published var comments: [CommentItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var isAddingComment = false
    @Published var isEditingComment = false
    @Published var isDeletingComment = false
    @Published var expandedComments: Set<String> = []
    @Published var showingMenuForComment: String?
    @Published var menuButtonFrame: CGRect = .zero
    
    // MARK: - Post Reference
    @Published var post: PostItem
    
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 1
    private var totalPages = 1
    let userDataManager: UserDataManager
    
    var totalComments: Int {
        comments.count
    }
    
    var hasMoreComments: Bool {
        currentPage < totalPages
    }
    
    var currentUserId: String {
        userDataManager.getSecureUserData().userId ?? ""
    }
    
    var postId: String {
        post.postID ?? ""
    }
    
    // Get current User ID
    var getCurrentUserID: String {
        UserDataManager.shared.getSecureUserData().userId ?? ""
    }
    
    let routeManager = RouteManager.shared
    
    init(
        post: PostItem,
        userDataManager: UserDataManager
    ) {
        self.post = post
        self.userDataManager = userDataManager
    }
    
    // MARK: - API Methods
    
    func loadAllComments() {
        guard !isLoading else { return }
        
        isLoading = true
        currentPage = 1
        
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            isLoading = false
            return
        }
        
        let urlString = URLBuilderConstants.URLBuilder(type: .getAllTheComments)
        
        let queryParams: [String: String] = [
            "postId": "\(postId)",
            "page": "\(currentPage)",
            "limit": "\(DeveloperConstants.Network.pageLimit)"
        ]
        
        let publisher: AnyPublisher<CommentsModel, APIError> = apiService.genericPublisher(
            fromURLString: urlString,
            queryParameters: queryParams
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                self?.isLoading = false
                switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        print("Error loading comments: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                if let comments = response.comments {
                    self.comments = comments
                }
                
                self.currentPage = response.currentPage ?? 1
                self.totalPages = (response.totalComments ?? 0) / (response.limit ?? 10) + 1
                self.isLoading = false
            })
            .store(in: &cancellables)
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
    
    func loadMoreComments() {
        guard !isLoadingMore && hasMoreComments else { return }
        
        isLoadingMore = true
        let nextPage = currentPage + 1
        
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            isLoadingMore = false
            return
        }
        
        let urlString = URLBuilderConstants.URLBuilder(type: .getAllTheComments)
        
        let queryParams: [String: String] = [
            "postId": "\(postId)",
            "page": "\(nextPage)",
            "limit": "\(DeveloperConstants.Network.pageLimit)"
        ]
        
        let publisher: AnyPublisher<CommentsModel, APIError> = apiService.genericPublisher(
            fromURLString: urlString,
            queryParameters: queryParams
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                self?.isLoadingMore = false
                switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        print("Error loading more comments: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                if let newComments = response.comments {
                    self.comments.append(contentsOf: newComments)
                }
                
                self.currentPage = nextPage
                self.isLoadingMore = false
            })
            .store(in: &cancellables)
    }
    
    @MainActor
    func refreshComments() async {
        currentPage = 1
        
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else { return }
        
        let urlString = URLBuilderConstants.URLBuilder(type: .getAllTheComments)
        
        let queryParams: [String: String] = [
            "postId": "\(postId)",
            "page": "\(currentPage)",
            "limit": "\(DeveloperConstants.Network.pageLimit)"
        ]
        
        do {
            let publisher: AnyPublisher<CommentsModel, APIError> = apiService.genericPublisher(
                fromURLString: urlString,
                queryParameters: queryParams
            )
            
            let response = try await publisher.async()
            
            if let comments = response.comments {
                self.comments = comments
            }
            
            self.currentPage = response.currentPage ?? 1
            self.totalPages = (response.totalComments ?? 0) / (response.limit ?? 10) + 1
            
        } catch {
            print("Error refreshing comments: \(error.localizedDescription)")
        }
    }
    
    func addNewComment(addedComment: String) {
        guard !addedComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isAddingComment else { return }
        
        isAddingComment = true
        
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            isAddingComment = false
            return
        }
        
        let urlString = URLBuilderConstants.URLBuilder(type: .getAllTheComments)
        
        // Using your existing request model instead of the duplicate
        let requestBody = CommentRequest(
            text: addedComment,
            postId: postId
        )
        
        let publisher: AnyPublisher<CommentsModel, APIError> = apiService.genericPostPublisher(
            toURLString: urlString,
            requestBody: requestBody,
            isAuthNeeded: true
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                self?.isAddingComment = false
                switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        print("Error adding comment: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                if let newComments = response.comments,
                   let serverComment = newComments.first {
                    self.comments.insert(serverComment, at: 0)
                }
                
                self.isAddingComment = false
            })
            .store(in: &cancellables)
    }
    
    func editComment(commentId: String, editedComment: String) {
        guard !editedComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isEditingComment else { return }
        
        isEditingComment = true
        
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            isEditingComment = false
            return
        }
        
        let urlString = URLBuilderConstants.URLBuilder(type: .getAllTheComments)
        
        // Using your existing request model
        let requestBody = CommentEditRequest(
            text: editedComment,
            commentId: commentId
        )
        
        let publisher: AnyPublisher<CommentsModel, APIError> = apiService.genericPostPublisher(
            toURLString: urlString,
            requestBody: requestBody,
            isAuthNeeded: true,
            httpMethod: .put
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                self?.isEditingComment = false
                switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        print("Error editing comment: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                if let updatedComments = response.comments,
                   let updatedComment = updatedComments.first(where: { $0.id == commentId }),
                   let index = self.comments.firstIndex(where: { $0.id == commentId }) {
                    self.comments[index] = updatedComment
                }
                
                self.isEditingComment = false
            })
            .store(in: &cancellables)
    }
    
    func likeAComment(commentId: String) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else { return }
        
        let originalComment = comments.first { $0.id == commentId }
        
        // Optimistic update
        if let index = comments.firstIndex(where: { $0.id == commentId }) {
            let comment = comments[index]
            var likedUserIds = comment.likedUserIds ?? []
            var likeCount = comment.likeCount ?? 0
            
            if likedUserIds.contains(currentUserId) {
                likedUserIds.removeAll { $0 == currentUserId }
                likeCount = max(0, likeCount - 1)
            } else {
                likedUserIds.append(currentUserId)
                likeCount += 1
            }
            
            let updatedComment = CommentItem(
                id: comment.id,
                text: comment.text,
                userId: comment.userId,
                createdAt: comment.createdAt,
                postId: comment.postId,
                likedUserIds: likedUserIds,
                likeCount: likeCount,
                replyCount: comment.replyCount,
                profilePicUrl: comment.profilePicUrl,
                userName: comment.userName,
                commentOwner: comment.commentOwner
            )
            comments[index] = updatedComment
        }
        
        let urlString = URLBuilderConstants.URLBuilder(type: .getAllTheComments)
        
        // Using your existing request model
        let requestBody = CommentLikeRequest(commentId: commentId)
        
        let publisher: AnyPublisher<CommentsModel, APIError> = apiService.genericPostPublisher(
            toURLString: urlString,
            requestBody: requestBody,
            isAuthNeeded: true,
            httpMethod: .patch
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        print("Error liking comment: \(error.localizedDescription)")
                        // Revert optimistic update on failure
                        if let originalComment = originalComment,
                           let index = self?.comments.firstIndex(where: { $0.id == commentId }) {
                            self?.comments[index] = originalComment
                        }
                }
            }, receiveValue: { [weak self] response in
                if let updatedComments = response.comments,
                   let serverComment = updatedComments.first(where: { $0.id == commentId }),
                   let index = self?.comments.firstIndex(where: { $0.id == commentId }) {
                    self?.comments[index] = serverComment
                }
            })
            .store(in: &cancellables)
    }
    
    func deleteAComment(commentId: String) {
        guard !isDeletingComment else { return }
        
        isDeletingComment = true
        
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            isDeletingComment = false
            return
        }
        
        let urlString = URLBuilderConstants.URLBuilder(type: .getAllTheComments)
        
        let queryParams: [String: String] = [
            "commentId": "\(commentId)",
            "postId": "\(postId)"
        ]
        
        let publisher: AnyPublisher<CommentsModel, APIError> = apiService.genericPublisher(
            fromURLString: urlString,
            queryParameters: queryParams,
            httpMethod: .delete
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                self?.isDeletingComment = false
                switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        print("Error deleting comment: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                self.comments.removeAll { $0.id == commentId }
                self.expandedComments.remove(commentId)
                self.showingMenuForComment = nil
                self.isDeletingComment = false
            })
            .store(in: &cancellables)
    }
    
    func reportComment(commentId: String) {
//        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else { return }
//        
//        let urlString = URLBuilderConstants.URLBuilder(type: .reportComment)
//        
//        // Using your existing request model
//        let requestBody = CommentReportRequest(
//            commentId: commentId,
//            reason: "Inappropriate content"
//        )
//        
//        let publisher: AnyPublisher<CommentsModel, APIError> = apiService.genericPostPublisher(
//            toURLString: urlString,
//            requestBody: requestBody,
//            isAuthNeeded: true
//        )
//        
//        publisher
//            .receive(on: DispatchQueue.main)
//            .sink(receiveCompletion: { [weak self] result in
//                switch result {
//                    case .finished:
//                        print("Comment reported successfully")
//                    case .failure(let error):
//                        print("Error reporting comment: \(error.localizedDescription)")
//                }
//                self?.showingMenuForComment = nil
//            }, receiveValue: { response in
//                print("Report submitted successfully")
//            })
//            .store(in: &cancellables)
    }
}

// MARK: - Helper Extensions

extension CommentItem {
    init(id: String?, text: String?, userId: String?, createdAt: String?, postId: String?,
         likedUserIds: [String]?, likeCount: Int?, replyCount: Int?,
         profilePicUrl: String?, userName: String?, commentOwner: Bool?) {
        self.id = id
        self.text = text
        self.userId = userId
        self.createdAt = createdAt
        self.postId = postId
        self.likedUserIds = likedUserIds
        self.likeCount = likeCount
        self.replyCount = replyCount
        self.profilePicUrl = profilePicUrl
        self.userName = userName
        self.commentOwner = commentOwner
    }
}

// MARK: - Combine Publisher Extension for Async/Await

extension AnyPublisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = first()
                .sink(receiveCompletion: { completion in
                    switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                }, receiveValue: { value in
                    continuation.resume(returning: value)
                })
        }
    }
}
