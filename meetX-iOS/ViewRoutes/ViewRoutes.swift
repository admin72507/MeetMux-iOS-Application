//
//  ViewRoutes.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 06-03-2025.
//
import SwiftUI

// MARK: - Intro page
struct IntroSceneRoute: AppRoute {
    
    func view() -> some View {
        IntroScreenScene()
            .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Old Login Detected
struct oldLoginRoute: AppRoute {
    
    func view() -> some View {
        OldLoginDetectionView()
            .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Login Register Route
struct LoginRegister: AppRoute {
    
    func view() -> some View {
        LogInRegisterScene()
            .navigationBarBackButtonHidden(true)
    }
}

// MARK: - OTP Route
struct OTPVerificationScene: AppRoute {
    
    let mobileNumber : String
    
    func view() -> some View {
        OTPVerificationView(mobileNumber: mobileNumber)
            .navigationBarBackButtonHidden(true)
    }
}

//MARK: - PRofileUpdation
struct ProfileUpdationScene: AppRoute {
    
    func view() -> some View {
        ProfileDetailsUpdation()
    }
}

//MARK: - Application Permission
/// Location, Network, Tracking
struct PermissionStepScene: AppRoute {

    func view() -> some View {
        PermissionView()
    }
}

//MARK: - Activity Screen
struct ProfessionalSceneRoute : AppRoute {
    
    func view() -> some View {
        ProfessionalDetailScene()
            .navigationBarBackButtonHidden(true)
            .navigationTitle(Constants.profesionalDetailsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .customBackButtonNavToolBar {
                RouteManager.shared.goBack()
            }
    }
}

// MARK: - Create post
struct CreatePostRoute: AppRoute {
    
    func view() -> some View {
        CreatePostScene(isTabBarPresented: .constant(false))
            .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Create Recommended Section
struct CreateRecommendedRoute: AppRoute {
    func view() -> some View {
        
        RecommendedUsersGridView()
            .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Navigate to edit profile
struct navigateToEditProfile: AppRoute {
    
    let fullName : String
    let email: String
    let bio: String
    let selectedActivities: Set<Int>
    let s3ImageUrls: [String]
    let signedProfileImageUrl: [String]
    
    func view() -> some View {
        let viewModel = EditProfileObservable(
            fullName: fullName,
            bio: bio,
            email: email,
            selectedActivities: selectedActivities,
            s3ImageUrls: s3ImageUrls,
            signedProfileImageUrl: signedProfileImageUrl
        )
        EditProfileScene(viewModel: viewModel)
            .navigationBarBackButtonHidden(true)
    }
}


//MARK: - Notification View
struct NotificationSceneRoute : AppRoute {
    
    func view() -> some View {
        NotificationView()
            .navigationBarBackButtonHidden(true)
            .navigationTitle(Constants.notificationTitle)
            .navigationBarTitleDisplayMode(.large)
            .customBackButtonNavToolBar {
                RouteManager.shared.goBack()
            }
    }
}

//MARK: - Home Page
struct HomePageRoute: AppRoute {
    
    func view() -> some View {
        CustomTabBarView(selectedTab: 0)
            .navigationBarBackButtonHidden(true)
    }
}

////MARK: - HomePage Scene
//struct HomePageRouteFromTabBar: AppRoute {
//    
//    let isTabBarPresented: Bool
//    
//    func view() -> some View {
//        let view
//        
//        HomePageScene(
//            isTabBarPresented: .constant(isTabBarPresented),
//            viewModel: socketClient
//        )
//            .navigationBarBackButtonHidden(true)
//    }
//}


//MARK: - Chat Room Route
struct ChatRoomRoute: AppRoute {
    let receiverId: String
    let profilePicture: String

    func view() -> some View {
        ChatRoomScene(
            receiverId: receiverId,
            profilePicture: profilePicture
        )
        .navigationBarBackButtonHidden(true)
    }
}

//MARK: - Chat Scene
struct ChatMessageSectionFromTabBar: AppRoute {
    
    let isTabBarPresented: Bool
    
    func view() -> some View {
//        ChatLandingScene(isTabBarPresented: .constant(isTabBarPresented))
//            .navigationBarBackButtonHidden(true)
    }
}

//MARK: - Control Room Scene
struct ControlRoomRoute: AppRoute {
    
    func view() -> some View {
        ControlRoomScene()
    }
}

// MARK: - BlockedListRoute
struct BlockedListRoute: AppRoute {
    
    func view() -> some View {
        BlockedUserListScene()
            .navigationBarBackButtonHidden(true)
    }
}

// MARK: - My live Activities Route
struct MyLiveActivitiesRoute: AppRoute {
    
    func view() -> some View {
        MyLiveActivitiesScene()
            .navigationBarBackButtonHidden(true)
    }
}

//MARK: - Control Room Views

struct ProfileMeAndOthersRoute: AppRoute, Equatable, Hashable {
    let viewmodel: ProfileMeAndOthersObservable
    
    static func == (lhs: ProfileMeAndOthersRoute, rhs: ProfileMeAndOthersRoute) -> Bool {
        lhs.viewmodel.id == rhs.viewmodel.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(viewmodel.id)
    }
    
    func view() -> some View {
        let socketClient = SocketFeedClient()
        let locationViewModel = LocationObservable()

        let homeViewModel = HomeObservable(
            socketClient: socketClient,
            locationVM: locationViewModel
        )
        ProfileMeAndOtherScene(
            viewModel: viewmodel,
            viewModelHome: homeViewModel
        )
            .navigationBarBackButtonHidden(true)
    }
}


struct SubmitFeedbackViewRoute: AppRoute {
    
    func view() -> some View {
        SubmitFeedbackView()
            .navigationBarBackButtonHidden(true)
    }
}

//MARK: - ViewROutes
struct PrivacyTermsConditontionRoute : AppRoute {
    
    let link : String
    let title : String
    let image : String
    let subtitle : String
    
    func view() -> some View {
        WebContentView(urlString: link)
            .navigationBarBackButtonHidden(true)
            .generalNavBarInControlRoom(title: title, subtitle: subtitle, image: image, onBacktapped: {
                RouteManager.shared.goBack()
            })
    }
}

// MARK: - Version info Navigator
struct versionInfoRoute: AppRoute {
    
    func view() -> some View {
        VersionInfoScene()
            .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Theme Switcher
struct themeSwitcherRoute: AppRoute {
    
    func view() -> some View {
        ThemeSwitcherScene()
            .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Refer a friend contacts selection
struct referAFriendContactSelectionRoute: AppRoute {
    
    func view() -> some View {
        ReferFriendView()
            .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Contact Permission Screen
struct contactPermissionScreenRoute: AppRoute {

    func view() -> some View {
        ReferAFriendView()
            .navigationBarBackButtonHidden(true)
    }
}

// MARk: - Change Mobile Number screen
struct ChangeMobileNumberRoute: AppRoute, Equatable, Hashable {
    let viewModel: ControlRoomObservable
    
    static func == (lhs: ChangeMobileNumberRoute, rhs: ChangeMobileNumberRoute) -> Bool {
        lhs.viewModel.id == rhs.viewModel.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(viewModel.id)
    }
    
    func view() -> some View {
        ChangeMobileNumberScene(viewModel: viewModel)
            .navigationBarBackButtonHidden(true)
    }
}

//MARK: - Profile Settings
struct PrivacySettingsNavRoute: AppRoute, Equatable, Hashable {
    let viewModel: ControlRoomObservable
    
    static func == (lhs: PrivacySettingsNavRoute, rhs: PrivacySettingsNavRoute) -> Bool {
        lhs.viewModel.id == rhs.viewModel.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(viewModel.id)
    }
    
    func view() -> some View {
        PrivacySettingsScene(viewModel: viewModel)
            .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Follow Follwers Route
struct FollowAndFollowersRoute: AppRoute {
    
    func view() -> some View {
        FollowAndFollowersScene()
            .navigationBarBackButtonHidden(true)
    }
}

//MARK: - Report a problem
struct reportAProblemRoute : AppRoute {
    
    let title : String
    let image : String
    let subtitle : String
    
    
    func view() -> some View {
        NeedSupportScene(retrivedMobileNumber: "")
            
            .generalNavBarInControlRoom(title: title, subtitle: subtitle, image: image, onBacktapped: {
                RouteManager.shared.goBack()
            })
    }
}

//MARK: - Delete or deactivate
struct DeleteOrDeactivateRoute : AppRoute {
    
    let title : String
    let image : String
    let subtitle : String
    
    func view() -> some View {
        DeleteAccountView()
            .navigationBarBackButtonHidden(true)
            .generalNavBarInControlRoom(title: title, subtitle: subtitle, image: image, onBacktapped: {
                RouteManager.shared.goBack()
            })
    }
}

// MARK: - Connection list route
struct ConnectionListRoute: AppRoute, Equatable, Hashable {
    
    let viewModel: TagPeopleViewModel
    
    static func == (lhs: ConnectionListRoute, rhs: ConnectionListRoute) -> Bool {
        lhs.viewModel.id == rhs.viewModel.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(viewModel.id)
    }
    
    func view() -> some View {
        TagPeopleScene(
            viewModel: viewModel,
            isNavigationFromMenu: true)
            .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Handle Post Detail page

struct PostDetailPageRoute: AppRoute, Hashable {
    
    let postId: String
    let fromDestination: DeveloperConstants.PostDetailPageNavigation
    @Binding var postItem: [PostItem]
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(postId)
    }
    
    static func == (lhs: PostDetailPageRoute, rhs: PostDetailPageRoute) -> Bool {
        lhs.postId == rhs.postId
    }
    
    func view() -> some View {
        let viewModel = PostDetailObservable(
            postId: postId,
            fromDestination: fromDestination,
            post: Binding(
                get: { postItem },
                set: { postItem = $0 }
            )
        )
        
        PostDetailScene(
            viewModel: viewModel
        )
        .navigationBarBackButtonHidden(true)
    }
}

