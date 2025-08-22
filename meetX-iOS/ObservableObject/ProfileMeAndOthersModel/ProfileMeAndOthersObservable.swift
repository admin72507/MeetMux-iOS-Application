//
//  ProfileMeAndOthersObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 14-05-2025.
//
import Foundation
import SwiftUI
import Combine

@MainActor
class ProfileMeAndOthersObservable: ObservableObject {
    @Published var typeOfProfile: DeveloperConstants.ProfileTypes
    @Published var userProfileDetailsModel: UserProfileData?
    @Published var postDetails: [PostItem] = []
    @Published var errorMessage: String = ""

    @Published var actionFollowButtonTypes: PassthroughSubject<DeveloperConstants.FollowActionType, Never> = .init()
    @Published var connectionActionButtonTypes: PassthroughSubject<ConnectionActionType, Never> = .init()
    @Published var chatActionButtonTypes: PassthroughSubject<ConnectionActionType, Never> = .init()

    let id = UUID()
    var userID: String
    var page: Int = 1
    var isLoading: Bool = false
    var hasMorePosts: Bool = true
    private let routeManager = RouteManager.shared

    // Action button for connect
    enum ConnectionActionType {
        case removeConnectionRequest  // Cancel pending connection request
        case sendConnectionRequest    // Send new connection request
        case removeConnection        // Remove existing connection
        case chatRoom
    }

    private var cancellables = Set<AnyCancellable>()

    init(
        typeOfProfile: DeveloperConstants.ProfileTypes,
        userId: String
    ) {
        self.typeOfProfile = typeOfProfile
        self.userID = userId
        setupActionButtonSink()
    }

    func imageFromBase64ToUIImage(_ dataUrlString: String) -> UIImage? {
        guard let base64String = dataUrlString.components(separatedBy: ",").last,
              let imageData = Data(base64Encoded: base64String) else {
            return nil
        }

        return UIImage(data: imageData)
    }

    func imageFromBase64ToSwiftUIImage(_ dataUrlString: String) -> Image? {
        guard let uiImage = imageFromBase64ToUIImage(dataUrlString) else { return nil }
        return Image(uiImage: uiImage)
    }

    // MARK: - Handle Your's and other's title
    func handleTitle(_ title: String) -> String {
        switch typeOfProfile {
            case .others:
                return "\(userProfileDetailsModel?.name ?? "") \(title)"
            default:
                return "Your \(title)"
        }
    }

    // MARK: - Navigate to post Detail page
    @MainActor
    func navigateToPostDetail(postId: String) {
        guard postDetails.firstIndex(where: { $0.postID == postId }) != nil else {
            print("Post not found for ID: \(postId)")
            return
        }

        routeManager.navigate(to:
                                PostDetailPageRoute(
                                    postId: postId,
                                    fromDestination: .fromProfile,
                                    postItem: Binding(
                                        get: { self.postDetails },
                                        set: { self.postDetails = $0 }
                                    )
                                )
        )
    }


    // MARK: - Get the profileDetails
    func getTheProfileDetails() {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            self.errorMessage = "Failed to map"
            return
        }

        guard !isLoading && hasMorePosts else {
            return
        }

        isLoading = true
        errorMessage = ""

        let urlString = URLBuilderConstants.URLBuilder(type: .getTheUserProfileDetails)

        let queryParams: [String: String] = [
            "userId": userID,
            "page": "\(page)",
            "limit": "\(DeveloperConstants.Network.pageLimit)"
        ]

        Loader.shared.startLoading()

        let publisher: AnyPublisher<UserProfileResponse, APIError> = apiService.genericPublisher(
            fromURLString: urlString,
            queryParameters: queryParams
        )

        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    Loader.shared.stopLoading()

                    if case .failure(let error) = completion {
                        self.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    Loader.shared.stopLoading()
                    if let profile = response.user, profile.mobileNumber?.isEmpty == false {
                        self.userProfileDetailsModel = profile
                    }

                    let newPosts = response.posts

                    if self.page == 1 {
                        self.postDetails = newPosts
                    } else {
                        self.postDetails.append(contentsOf: newPosts)
                    }

                    // Pagination state management
                    if newPosts.count < DeveloperConstants.Network.pageLimit {
                        self.hasMorePosts = false
                    } else {
                        self.page += 1
                    }
                }
            )
            .store(in: &cancellables)
    }
}


// MARK: - Extension For Follow
extension ProfileMeAndOthersObservable {

    private func setupActionButtonSink() {
        actionFollowButtonTypes
            .sink { [weak self] actionType in
                self?.handleFollowButtonAction(actionType)
            }
            .store(in: &cancellables)

        // Add connection button sink
        connectionActionButtonTypes
            .sink { [weak self] actionType in
                self?.handleConnectionRequestStatus()
            }
            .store(in: &cancellables)

        // Add chat button sink
        chatActionButtonTypes
            .sink { [weak self] actionType in
                self?.handleChatButtonAction()
            }
            .store(in: &cancellables)

    }
}

// MARK: - Extension For Connect Handler
extension ProfileMeAndOthersObservable {

    /// Function handle chat button flow
    @MainActor
    private func handleChatButtonAction() {
        guard let user = userProfileDetailsModel, let userId = user.userId else { return }
        let profilePic = user.profilePicUrls?.first ?? ""
        routeManager.navigate(to: ChatRoomRoute(receiverId: userId, profilePicture: profilePic))
    }

    /// Function to handle the API call and other systems
    private func handleConnectionRequestStatus() {

        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            self.errorMessage = "Failed to map"
            return
        }

        Loader.shared.startLoading()

        guard let userID = userProfileDetailsModel?.userId else { return }

        let urlString = URLBuilderConstants.URLBuilder(type: .connectSystem)
        let requestParams = ConnectionRequest(targetUserId: userID)

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
                    self.userProfileDetailsModel?.updateFromConnectResponse(response)
                }
            )
            .store(in: &cancellables)

    }
}

// MARK: - Extension for Follow Handler
extension ProfileMeAndOthersObservable {

    /// Function to handle the follow button action
    private func handleFollowButtonAction(_ actionType: DeveloperConstants.FollowActionType) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            self.errorMessage = "Failed to map"
            return
        }

        Loader.shared.startLoading()

        guard let userID = userProfileDetailsModel?.userId else { return }

        let urlString = URLBuilderConstants.URLBuilder(type: .unFollowFollowBack)
        let requestParams = ConnectionRequest(targetUserId: userID)

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

                    _ = self.userProfileDetailsModel?.updateFromFollowResponse(response, expectedAction: actionType) ?? false
                }
            )
            .store(in: &cancellables)
    }
}

// NEED TO KNOW THE STATUS OF CONNECT BUTTON AND FOLLOW BUTTON
// IF THE ACCOUNT PRIVATE THE FOLLOW AND CONNECT WILL HAVE A REQUEST SENT TO THE CORRESPONDING USER --WHEN THE USER OPEN THE ACCOUNT OF THE OTHER PERSON AGAIN WE NEED TO TELL THEM ALREADY A REQUEST HAS BEEN SENT
// 1. PROFILE API NEED ---> FOLLOW CURRENT STATUS & CONNECT CURRENT STATUS


// STATUS OF BUTTONS
// BOTH THE USER IS NEW
// CLICK LOGIC
// FOLLOW  |  CONNECT --> 1

// USER CLICKING CONNECT ---> SENDER PROFILE IS PUBLIC
// UNFOLLOW           // REQUEST SENT --> 2

// USER CLICKING CONNECT --> SENDER PROFILE IS PRIVATE
// REQUEST SENT        // REQUEST SENT --> 2

//SENDER ACCEPTED THE CONNECTION
// UNFOLLOW     // REMOVE CONNECTION ---> 3

// SENDER REJECTED
// MOVED TO STEP 1

// MARK: - ProfileMeAndOthersObservable Extension for Button Actions
extension ProfileMeAndOthersObservable {

    // MARK: - Following Button Action
    @MainActor
    func handleFollowingFollowButtonTapped() {
        routeManager.navigate(to: FollowAndFollowersRoute())
    }

    // MARK: - Connections Button Action
    @MainActor
    func handleConnectionsButtonTapped() {
        routeManager.navigate(to:
                                ConnectionListRoute(
                                    viewModel: TagPeopleViewModel(selectedConnections: [])
                                )
        )
    }
}
