//
//  PlannedActivityFeedItem.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 31-03-2025.
//

import SwiftUI
import Kingfisher

struct PlannedActivityFeedItemScene: View {
    
    @ObservedObject var viewModel: HomeObservable
    @State private var localIndex: Int = 0
    @Binding var isLive: Bool
    let postId: String
    
    private var postItem: PostItem? {
        return viewModel.feedItemsObjects?.posts?.first { $0.postID == postId }
    }
    
    var body: some View {
        VStack {
            
            if let postItem = postItem {
                PlannedActivityHeaderScene(
                    feedItem: postItem,
                    isLive: $isLive,
                    viewModel: viewModel
                )
                .padding(.horizontal, 10)
                
                LocationSectionScene(
                    feedItem: postItem,
                    viewModel: viewModel,
                    actionForJoinedUser: { joinedUserTags in
                        viewModel.selectedJoinedUserList = joinedUserTags
                        viewModel.showJoinedUserList.toggle()
                    }
                )
                .padding(.top, 5)
                
                ZStack(alignment: .bottom) {
                    mediaTabView()
                        .id(postItem.postID)
                    
                    BottomView(
                        viewModel: viewModel,
                        localIndex: $localIndex,
                        showBootomView: .constant(false), feedItem: postItem,
                        viewHeight: 250,
                        likesCount: "\(postItem.totalLikes ?? 0)",
                        commentsCount: "\(postItem.totalComments ?? 0)", 
                        postId: postItem.postID ?? ""
                    )
                }
            }
        }
        .onAppear {
            if let firstMediaIndex = postItem?.mediaFiles?.indices.first {
                localIndex = firstMediaIndex
            }
        }
        .sheet(isPresented: $viewModel.showJoinedUserList) {
            PeopleTagsDetailView(
                peopleTags: viewModel.selectedJoinedUserList,
                onUserTapAction: { receivedUser in
                    viewModel.showJoinedUserList.toggle()
                    viewModel.moveToTaggedUserProfile(for: receivedUser.userId)
                }, title: Constants.joinUserTitle)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .frame(maxWidth: .infinity, maxHeight: DeveloperConstants.mainContentSizesPost.generalPlannedWithImagePost)
        .padding(.bottom, 20)
        .padding(.top, 20)
    }
    
    private func getActivityStatus() -> String {
        if postItem?.feedType == .live {
            if let timeLeft = HelperFunctions.calculateLiveTimeLeft(
                startDate: postItem?.eventDate,
                endDate: postItem?.endDate,
                liveDuration: postItem?.liveDuration
            ) {
                return timeLeft
            }
            return ""
        }
        return ""
    }
}


// MARK: - Planned Activity Header
struct PlannedActivityHeaderScene: View {
    
    let feedItem: PostItem
    @State private var interestState: InterestState
    @Binding var isLive: Bool
    var viewModel: HomeObservable
    
    enum InterestState {
        case none
        case requested
        case accepted
    }
    
    init(feedItem: PostItem, isLive: Binding<Bool>, viewModel: HomeObservable) {
        self.feedItem = feedItem
        self._isLive = isLive
        self.viewModel = viewModel
        
        // Initialize state based on current data
        if feedItem.userContext?.hasShownInterest == true {
            self._interestState = State(initialValue: .accepted)
        } else if feedItem.userContext?.isInterestRequested == true {
            self._interestState = State(initialValue: .requested)
        } else {
            self._interestState = State(initialValue: .none)
        }
    }
    
    var body: some View {
        HStack {
            ProfileFeedImageView(
                imageUrl: feedItem.user?.profilePicUrl ?? "",
                userName: feedItem.user?.name ?? "")
            .onTapGesture {
                viewModel.moveToUserProfileHome(for: feedItem)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 10) {
                    if viewModel.getCurrentUserID == feedItem.user?.userId {
                        Text("You")
                            .fontStyle(size: 16, weight: .semibold)
                            .foregroundColor(ThemeManager.foregroundColor)
                    } else {
                        Text(feedItem.user?.name ?? "")
                            .fontStyle(size: 16, weight: .semibold)
                            .foregroundColor(ThemeManager.foregroundColor)
                    }
                    
                    if isLive {
                        LiveIndicatorView()
                    }
                }
                .onTapGesture {
                    viewModel.moveToUserProfileHome(for: feedItem)
                }
                
                HStack(spacing: 8) {
                    Text(feedItem.user?.username ?? "")
                    
                    Text("•")
                    
                    TimeAgoText(utcString: feedItem.createdAt ?? "")
                }
                .fontStyle(size: 12, weight: .light)
                .foregroundColor(ThemeManager.foregroundColor.opacity(0.7))
            }
            
            Spacer()
            
            if viewModel.getCurrentUserID != feedItem.user?.userId,
               feedItem.isActive == true {
                InterestButton(
                    title: buttonTitle,
                    icon: buttonIcon,
                    isSelected: buttonIsSelected
                ) {
                    guard viewModel.getUserGender
                        .lowercased() != feedItem.genderRestriction?.lowercased() else {
                        viewModel.errorMessage = "The preferred gender for this post doesn't match your profile. Please consider showing interest for a different post."
                        return
                    }
                    handleInterestAction()
                }
                .frame(width: 120)
            }
        }
    }
    
    // MARK: - Computed Properties for Button State
    private var buttonTitle: String {
        switch interestState {
            case .none:
                return Constants.interestedText
            case .requested:
                return "Interest Requested"
            case .accepted:
                return Constants.interestedText
        }
    }
    
    private var buttonIcon: String {
        switch interestState {
            case .none:
                return DeveloperConstants.systemImage.plusImage
            case .requested:
                return "hand.raised.fill"
            case .accepted:
                return DeveloperConstants.systemImage.checkMark
        }
    }
    
    private var buttonIsSelected: Bool {
        switch interestState {
            case .none:
                return false
            case .requested, .accepted:
                return true
        }
    }
    
    // MARK: - Action Handler
    private func handleInterestAction() {
        // Update local state immediately for UI responsiveness
        switch interestState {
            case .none:
                interestState = .requested
            case .requested:
                interestState = .none
            case .accepted:
                interestState = .none
        }
        
        // Then call the view model to handle the backend logic
        viewModel.handleShowInterest(feedItem: feedItem)
    }
}


// MARK: - Location Section
struct LocationSectionScene: View {
    
    let feedItem: PostItem
    @ObservedObject var viewModel: HomeObservable
    
    let actionForJoinedUser: ([PeopleTags]) -> Void
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            if let firstTag = feedItem.activityTags?.first,
               let subcategory = firstTag.subcategories?.first {
                
                HStack(spacing: 8) {
                    Image(systemName: subcategory.platformIos ?? "")
                        .foregroundColor(ThemeManager.staticPurpleColour)
                    
                    Text(subcategory.title ?? "")
                        .fontStyle(size: 14, weight: .light)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(ThemeManager.foregroundColor)
                }
                .padding(.horizontal, 10)
            }
            
            HStack(spacing: 8) {
                
                Image(systemName: DeveloperConstants.systemImage.mapCircleFill)
                    .foregroundColor(ThemeManager.staticPurpleColour)
                
                Text(feedItem.location ?? "Undetermined Location")
                    .fontStyle(size: 14, weight: .light)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(ThemeManager.foregroundColor)
            }
            .padding(.horizontal, 10)
            
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: DeveloperConstants.systemImage.calenderImage)
                        .foregroundColor(ThemeManager.staticPurpleColour)
                        .frame(width: 16)
                    
                    let formattedDateAndTime = formatDateStringForPlannedActivity(feedItem.endDate ?? "")
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Constants.activityEndOn)
                            .fontStyle(size: 14, weight: .light)
                            .foregroundColor(ThemeManager.foregroundColor)
                        
                        Text("\(formattedDateAndTime.formattedDateExtracted) \(Constants.atText) \(formattedDateAndTime.formattedTime)")
                            .fontStyle(size: 14, weight: .medium)
                            .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                    }
                    Spacer()
                }
                
                Rectangle()
                    .frame(width: 1, height: 20)
                    .foregroundColor(.gray)
                
                Image(systemName: DeveloperConstants.systemImage.personFill)
                    .foregroundColor(ThemeManager.staticPurpleColour)
                
                HStack(spacing: 0) {
                    Text("\(feedItem.totalJoinedUsers ?? 0)")
                        .fontStyle(size: 16, weight: .semibold)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(
                            ThemeManager.gradientNewPinkBackground
                        )
                    
                    Text(Constants.joinedText)
                        .fontStyle(size: 14, weight: .light)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(ThemeManager.foregroundColor)
                }
                .onTapGesture {
                    //TODO:- Add the flow for user list
                    guard feedItem.joinedUserTags?.count ?? 0 > 0 else { return }
                    actionForJoinedUser(feedItem.joinedUserTags ?? [])
                }
            }
            .padding(.horizontal, 10)
        }
    }
}


// MARK: - Subviews
extension PlannedActivityFeedItemScene {
    
    private func mediaTabView() -> some View {
        TabView(selection: $localIndex) {
            if let mediaFiles = postItem?.mediaFiles {
                ForEach(Array(mediaFiles.enumerated()), id: \.0) { index, media in
                    let mediaType = DeveloperConstants.MediaType(rawValue: media.type ?? "unknown")
                    mediaView(for: mediaType, at: index)
                        .tag(index)
                }
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(width: UIScreen.main.bounds.width, height: DeveloperConstants.mainContentSizesPost.plannedAndLiveActivityPost)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 5)
        .id(localIndex)
    }
    
    private func mediaView(for mediaType: DeveloperConstants.MediaType, at index: Int) -> some View {
        let content: AnyView
        
        switch mediaType {
            case .image:
                if let urlString = postItem?.mediaFiles?[index].url,
                   let url = URL(string: urlString) {
                    content = AnyView(
                        KFImage(url)
                            .resizable()
                            .placeholder {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .scaleEffect(1.5)
                            }
                            .retry(maxCount: 3, interval: .seconds(3))
                            .scaledToFill()
                    )
                } else {
                    content = AnyView(Color.gray)
                }
                
            case .video:
                if let urlString = postItem?.mediaFiles?[index].url,
                   let url = URL(string: urlString) {
                    content = AnyView(VideoPlayerView(videoURL: url, isActive: localIndex == index, videoFromGeneral: false))
                } else {
                    content = AnyView(Color.black)
                }
                
            case .unknown:
                content = AnyView(Color.red)
        }
        
        return content
            .frame(width: UIScreen.main.bounds.width, height: DeveloperConstants.mainContentSizesPost.plannedAndLiveActivityPost)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
