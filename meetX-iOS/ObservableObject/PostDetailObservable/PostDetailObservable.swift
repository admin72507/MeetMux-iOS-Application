//
//  PostDetailObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-06-2025.
//

import Combine
import Foundation
import UIKit
import SwiftUI

class PostDetailObservable: ObservableObject {
    
    @Published var feedItem: PostItem?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    @Published var showAllPeopleTag: Bool = false
    @Published var peopleTagList: [PeopleTags] = []
    @Published var titlePopUp: String? = "Tagged Users"
    
    @Published var openCommentsPopUp: Bool = false
    
    // Share sheet
    @Published var isShareSheetPresented = false
    @Published var shareItems: [Any] = []
    
    //End activity
    @Published var showEndConfirmation = false
    @Published var showDeletePostConfirmation: Bool = false
    
    var cancellables = Set<AnyCancellable>()
    let postId: String
    private let routeManager = RouteManager.shared
    
    // Binding post
    @Binding var post: [PostItem]
    
    let fromDestination: DeveloperConstants.PostDetailPageNavigation
    
    // Get current User ID
    var getCurrentUserID: String {
        print(UserDataManager.shared.getSecureUserData().userId ?? "")
        return UserDataManager.shared.getSecureUserData().userId ?? ""
    }
    
    var isLiveActivity: Bool {
        feedItem?.postType?.lowercased() == "liveactivity"
    }
    
    init(
        postId: String,
        fromDestination: DeveloperConstants.PostDetailPageNavigation,
        post: Binding<[PostItem]>
    ) {
        self.postId = postId
        self.fromDestination = fromDestination
        self._post = post
    }
    
    // MARK: - Update Count
    func updateCount() {
        guard let updatedFeedItem = feedItem else { return }
        
        if let index = post.firstIndex(where: { $0.postID == updatedFeedItem.postID }) {
            post[index].likeCount = updatedFeedItem.totalLikes ?? 0
            post[index].totalComments = updatedFeedItem.totalComments ?? 0
        }
    }

    
    // MARK: - Get the currently selected post detail
    func getThePostDetail(
        postId: String,
        actiontype: String? = "get"
    ) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            self.errorMessage = "Failed to map API service"
            return
        }
        
        guard !postId.isEmpty else {
            self.errorMessage = "No valid post ID provided"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Loader.shared.startLoading()
        
        let urlString = URLBuilderConstants.URLBuilder(type: .singlePostFetch)
        
        let queryParams: [String: String] = [
            "postId": "\(postId)"
        ]
        
        let publisher: AnyPublisher<PostItem, APIError> = apiService.genericPublisher(
            fromURLString: urlString,
            queryParameters: queryParams,
            httpMethod: actiontype == "get" ? .get : .delete
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                guard let self = self else { return }
                
                self.isLoading = false
                Loader.shared.stopLoading()
                
                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                    print("Error fetching post detail: \(error)")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                if actiontype == "get" {
                    self.feedItem = response
                    self.errorMessage = nil
                }else {
                    self.errorMessage = "Post deleted successfully"
                    routeManager.goBack()
                //    if fromDestination == .fromProfile {
                        post.removeAll { $0.postID == self.feedItem?.postID }
                //    }
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Action Methods
    func toggleInterest() {
        self.showAllPeopleTag.toggle()
    }
    
    func deletePost() {
        guard let _ = feedItem else { return }
        
        showDeletePostConfirmation.toggle()
    }
    
    func endActivity() {
        guard let feedItem = feedItem,
              feedItem.isActive == true,
              let postType = feedItem.postType,
              (postType == "liveactivity" || postType == "plannedactivity") else { return }
        
        // TODO: Implement end activity API call
        print("Ending activity: \(feedItem.postID ?? "")")
    }
    
    func addComment(text: String) {
        guard let feedItem = feedItem,
              feedItem.isActive == true,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // TODO: Implement add comment API call
        print("Adding comment to post: \(feedItem.postID ?? "")")
        print("Comment text: \(text)")
    }
    
    // MARK: - Helper Methods
    func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ" // Adjust based on your API format
        
        guard let date = dateFormatter.date(from: dateString) else {
            return "Unknown date"
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .medium
            outputFormatter.timeStyle = .short
            return outputFormatter.string(from: date)
        }
    }
    
    func shouldShowEndButton() -> Bool {
        guard let feedItem = feedItem,
              let postType = feedItem.postType?.lowercased(),
              (postType == "liveactivity" || postType == "plannedactivity"),
              feedItem.isActive == true,
              let liveDurationStr = feedItem.liveDuration,
              let liveDuration = Double(liveDurationStr),
              let createdAt = feedItem.eventDate else {
            return false
        }
        
        // Calculate hours passed since post creation
        let hoursPassed = HelperFunctions.convertUTCToISTAndCalculateDifference(utcString: createdAt)
        
        // Calculate hours left
        let hoursLeft = liveDuration - (hoursPassed?.hoursFromNow ?? 0.0)
        
        return hoursLeft > 0
    }
    
    @MainActor func moveToTaggedUserProfile(for userId: String) {
        guard userId != "" else { return }
        
        if getCurrentUserID == userId {
            routeManager.goBack()
        }else {
            let viewModel = ProfileMeAndOthersObservable(
                typeOfProfile: .others,
                userId: userId
            )
            routeManager.navigate(
                to: ProfileMeAndOthersRoute(
                    viewmodel: viewModel
                )
            )
        }
    }
    
    // MARK: - Like a post
    @MainActor func handleLikeLivePost(postId: String) {
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
        
        if feedItem?.postID == postId {
            feedItem?.totalLikes = totalLikesR
            feedItem?.userContext?.hasLiked = totalLikesR > 0
        }
    }
    
    // MARK: - Share post
    func sharePost() {
        guard let post = feedItem else { return }
        
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
    
    // MARK: - Interest button Activities
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
                        self.feedItem?.updateFromFollowResponse(response)
                    } else {
                        self.errorMessage = "Failed to handle interest"
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - End Activity
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
                self.feedItem?.isActive = false
            })
            .store(in: &cancellables)
    }


    // MARK: - Cleanup
    deinit {
        cancellables.removeAll()
    }
}
