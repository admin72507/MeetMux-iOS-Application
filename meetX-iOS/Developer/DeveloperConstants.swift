//
//  DeveloperConstants.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-12-2024.
//

import Foundation
import Combine

enum DeveloperConstants {
    
    // MARK: - App ShareDeeplink
    static let appShareDeeplink = "https://meetmux.com"
    
    // MARK: - API Keys
    static let googleApiKey = "AIzaSyCjEHDaOJnT4ThTEOjqQ9b4Ny7Xj0P2qOg"
    
    // MARK: - AWS Configuration
    static let utilityKey = "S3TransferUtility"
    static let awsRegion = "ap-south-1"
    static let cognitoIdentityPoolId = "ap-south-1:1c38b0d1-4f14-40b2-b5ec-b8c791e03bfb"
    
    // MARK: - Profile Bucket
    static let destinationFolderInsideBucket = "profile-pictures/"
    
    // MARK: - Follow Button Enum
    enum FollowActionType {
        case cancelFollowRequest // --> already status is follow requested so need to cancel the request
        case sendFollowRequest // --> already not following so send a new send request
        case removeFollow // ---> user already following when tappen remove the connection and move to initial
    }
    
    // MARK: - Type of upload
    enum typeOfUpload {
        case profile
        case generalPost
        case livePost
        case plannedPost
    }
    
    // MARK: - Type of page
    enum postDetailType {
        case MyActivities
        case PostDetail
    }
    
    // MARK: - PostDetail PageNavigation
    enum PostDetailPageNavigation {
        case fromHome
        case fromProfile
    }
    
    // MARK: - Upload Type
    enum fileTypeForS3Upload: String {
        case image = "images/"
        case video = "videos/"
    }
    
    // MARK: - App States
    enum AppScreen {
        case splash
        case login
        case profileUpdate
        case home
        case oldLoginDetection
    }

    // MARK: - Chat states
    enum MessageSendingState: Equatable {
        case idle
        case sending
        case sent
        case failed(Error)
    
        static func == (lhs: MessageSendingState, rhs: MessageSendingState) -> Bool {
            switch (lhs, rhs) {
                case (.idle, .idle), (.sending, .sending), (.sent, .sent):
                    return true
                case (.failed, .failed):
                    return true
                default:
                    return false
            }
        }
    }

    // MARK: - Main Content Sizes
    enum mainContentSizesPost {
        static let plannedAndLiveActivityPost : CGFloat = 550
        static let generalPlannedWithImagePost: CGFloat = 670
        static let generalWithImagePost    : CGFloat = 650
        static let generalwithoutImagePost   : CGFloat = 350
    }

    // MARK: - Tab Items
    enum Tab {
        
        enum AppTab: Int, CaseIterable {
            case home = 0, explore, createPost, chat, controlRoom
        }
        
        struct Item {
            let selectedIcon            : String
            let unselectedIcon          : String
            let title                   : String
        }
        
        static let defaultTabBarIndex                   = 0
        static let defaultNotchEdgeInsets   : CGFloat   = 20
        static let defaultNotchEdgeInsetsNo: CGFloat    = 10
        static let items: [Item]                        = [
            Item(selectedIcon: "house.fill", unselectedIcon: "house", title: ""),
            Item(selectedIcon: "map.fill", unselectedIcon: "map", title: ""),
            Item(selectedIcon: "plus", unselectedIcon: "", title: ""),
            Item(selectedIcon: "message.badge.waveform.fill", unselectedIcon: "message.badge.waveform", title: ""),
            Item(selectedIcon: "menucard.fill", unselectedIcon: "menucard", title: "")
        ]
        static let mainTabBarRadius             : CGFloat = 30
        static let mainViewHorizontalTabBarSpacing: CGFloat = 5
        static let mainViewTabBarHeight         : CGFloat = 80
        static let mainViewTabBarShadowRadius   : CGFloat = 20
    }
    
    // MARK: - Keychain (Sensitive Data)
    enum Keychain {
        static let userTokenKeychainIdentifier   = "userTokenKey"
        static let userMobileNumber              = "userMobileNumber"
        static let userID                        = "userID"
        static let userName                      = "userName"
        static let userDisplayName               = "userDisplayName"
        static let userProfilePicture            = "userProfilePicture"
        static let userVerifiedProfilePending    = "userVerifiedProfilePending"
        static let userGender                    = "userGender"
    }
    
    // MARK: - UserDefaults
    enum UserDefaultsInternal {
        // Essential App State (Never Reset)
        static let isApplaunchedBefore = "hasLaunchedBefore"
        static let appInstalledDate = "installDate"
        static let isLogOutDone = "isLogOutDone"
        static let userNotLoggedIn = "userNotLoggedIn"
        
        // User Preferences (Reset on Logout)
        static let userIDName = "userIDName" // @username for display
        static let themeSelectedByUser = "selectedTheme"
        static let isAutoPlayVideos = "autoPlayEnabled"
        static let seeOthersLastSeen = "othersLastseen"
        
        // User Data Cache (Reset on Logout)
        static let menuResponse = "controlCenterKey"
        static let userRecentLocationSearch = "RecentSearches"
        static let searchRecentSearchesKey = "RecentUserSearches"
    }
    
    static let loaderArray = [
        "https://lottie.host/6734917d-5181-4fe5-99ea-8bdd5a935a5a/mqW4zzqyH9.lottie",
        "https://lottie.host/e3f218af-f35b-42cb-8cba-40b635a46f6d/6L4KzFHQX1.lottie",
        "https://lottie.host/fd25a1f6-3750-4b14-ac84-4f32915af837/EA9i3r66R8.lottie",
        "https://lottie.host/93f3f37e-6100-4c3a-9be9-66c70d57fd48/KXLLPSYdNY.lottie"
    ]
    
    // MARK: - Modules
    enum ModuleName: String {
        case keychain                            = "KeyChain :"
        case networking                          = "Networking :"
    }
    
    // MARK: - Chat Filters
    enum ConversationFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        
        var title: String {
            return rawValue
        }
    }
    
    // MARK: - ProfileTypes
    enum ProfileTypes {
        case personal
        case others
    }
    
    // MARK: - Mute Duration Enum
    enum MuteDuration {
        case hours(Int)
        case days(Int)
        
        var timeInterval: TimeInterval {
            switch self {
                case .hours(let hours):
                    return TimeInterval(hours * 3600)
                case .days(let days):
                    return TimeInterval(days * 24 * 3600)
            }
        }
        
        var displayText: String {
            switch self {
                case .hours(let hours):
                    return "\(hours) hour\(hours > 1 ? "s" : "")"
                case .days(let days):
                    return "\(days) day\(days > 1 ? "s" : "")"
            }
        }
        
    }
    
    // MARK: - Delete action
    enum DeleteDeactivateAccount: String {
        case delete = "delete"
        case deactivate = "deactivate"
    }
    
    // MARK: - Profile Naming
    static let elementsInProfile = ["Post", "Following", "Followers", "Connections"]
    
    // MARK: - General Constants
    enum General {
        static let numberOfCharactersNeeded      = 7
        static let targetedScreenWidth           = 390.0
        static let targetScreenHeight            = 300
        static let maximumVideoDuration          = 60.0
        static let postCharacterLimit            = 150
        static let error                         = "Reason:"
        static let status                        = "Status:"
        static let conversionError               = "\(ModuleName.keychain.rawValue) Unable to convert string to data"
        static let savedSuccessfully             = "\(ModuleName.keychain.rawValue) Successfully saved item with key:"
        static let savedUnsuccessfully           = "\(ModuleName.keychain.rawValue) Unable to save item with key:"
        static let errorFetchingItem             = "\(ModuleName.keychain.rawValue) Unable to fetch item with key:"
        static let successfullyDeleted           = "\(ModuleName.keychain.rawValue) Successfully deleted item with key:"
        static let noItemFound                   = "\(ModuleName.keychain.rawValue) No item found with key:"
        static let deleteUnsuccessfully          = "\(ModuleName.keychain.rawValue) Unable to delete item with key:"
        static let combinedDeleteUnSuccessfully  = "\(ModuleName.keychain.rawValue) Unable to delete items with combined keys:"
        static let combinedDeleteSuccessfully    = "\(ModuleName.keychain.rawValue) Successfully deleted items with combined keys:"
        static let mainHeadingSize               = CGFloat(16)
        static let dateFormat                    = "dd/MM/yyyy"
        static let emailRegex                    = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        static let supportEmail                  = "support@altrodav.com"
        static let supportMobileNumber           = "+91 7022665938"
        static let numberWithoutCode             = "7022665938"
    }
    
    // MARK: - Network
    enum Network {
        static let scheme                         = "https"
        static let urlBaseAppender                = "/api/v1/"
        static let socketSchema                   = "https://"
        static let defaultTimeout: TimeInterval   = 5
        static let pageLimit: Int                 = 25
        static let urlHeaders = [
            "Content-Type": "application/json",
            "platformType": "ios",
            "Accept-Language": "en"
        ]
        
        enum ContentType: String {
            case json = "application/json"
            case multipartFormData = "multipart/form-data"
        }
        
        static func urlHeadersWithAuthorization(contentType: ContentType) -> [String: String] {
            return [
                "Content-Type": contentType.rawValue,
                "platformType": "ios",
                "Accept-Language": "en",
                "Authorization": KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userTokenKeychainIdentifier) ?? ""
            ]
        }
        
        static func urlHeadersWithAuthorizationForSockets(contentType: ContentType) -> [String: String] {
            return [
                "contentType": contentType.rawValue,
                "platformType": "ios",
                "acceptLanguage": "en",
                "authorization": KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userTokenKeychainIdentifier) ?? ""
            ]
        }

        enum HTTPMethods: String {
            case get                              = "GET"
            case post                             = "POST"
            case patch                            = "PATCH"
            case put                              = "PUT"
            case delete                           = "DELETE"
        }
        
        struct Endpoints {
            static let imageURL                   = "https://www.datade.com/api/images"
        }
        
        static let networkErrorMessage            = "\(ModuleName.networking.rawValue) Network request failed with error:"
    }
    
    enum FeedTypes: String {
        case live = "liveactivity"
        case activityPlaned = "plannedactivity"
        case general = "generalactivity"
        
        init(from rawValue: String) {
            self = FeedTypes(rawValue: rawValue) ?? .general
        }
    }
    
    enum MediaType: String {
        case image
        case video
        case unknown
        
        init(rawValue: String) {
            switch rawValue.lowercased() {
                case "image": self = .image
                case "video": self = .video
                default: self = .unknown
            }
        }
    }
    
    enum BaseURL {
        
#if PREPRODUCTION_STAGE
        static let deepLinkPostURL = "https://test.zexmeet.com/post/"
        static let baseURL = "test.zexmeet.com"
        static let socketBaseURL = "https://test.zexmeet.com"
        static let termsAndConditionsURL = "https://www.meetmux.com/terms-of-use/"
        static let subSystemLogger = "com.zexmeet.subsystem.stage"
        static let bucketName = "phase2-meetmux-asia"
#elseif PRODUCTION
        static let deepLinkPostURL = "https://meetmux.com/post/"
        static let baseURL = "api.meetmux.com"
        static let socketBaseURL = "https://api.meetmux.com"
        static let termsAndConditionsURL = "https://www.meetmux.com/terms-of-use/"
        static let subSystemLogger = "com.meetmux.subsystem.production"
        static let bucketName = "production-meetmux-asia"
#else
        static let deepLinkPostURL = "test.zexmeet.com"
        static let baseURL = "test.zexmeet.com"
        static let socketBaseURL = "https://test.zexmeet.com"
#endif
        
        // Socket Endpoints
        static var socketHomePageURL: String {
            return "\(socketBaseURL)/api/v1/homepage-feed"
        }
        
        static var socketHomeFallBackURL: String {
            return "\(socketBaseURL)/api/v1/homepage-feed?page=1&limit=10&type=0"
        }
        
        static var socketLikeURL: String {
            return "\(socketBaseURL)/api/v1/like/toggleLike?postId="
        }
        
        // Helper to check current environment
        static var currentEnvironment: String {
#if PREPRODUCTION_STAGE
            return "PreProductionStage"
#elseif PRODUCTION
            return "Production"
#else
            return "Unknown"
#endif
        }
    }

    
    // MARK: - API Service
    enum APIService {
        
        struct PublisherTypes {
            typealias GenericPublisher<T>          = AnyPublisher<T, APIError>
            typealias ImageData                    = Data
            typealias ImageDataPublisher           = AnyPublisher<ImageData, APIError>
        }
    }
    
    // MARK: - Login Register
    enum LoginRegister {
        static let logoImage                        = "Logo"
        static let logoImageFull                    = "LogoFull"
        static let logoFullDarkMode                 = "LogoFullDarkMode"
        static let logoOnlyImage                    = "OnlyLogoImage"
        static let conservativeImage                = "LoginMainImage"
        static let conservativeBlackImage           = "LoginBlack"
        static let debounceImageTimer : UInt64      = 500_000_000
        static let permissionCameraDeied            = "Permission denied for camera"
        static let permissionDeniedMessage          = "Permission denied for photo library"
        static let dateFormat                       = "DD/MM/YYYY"
        static let indiaCountryCode                 = "+91"
        static let bioCharacterLimt                 = 150
    }
    
    // MARK: - System Image
    enum systemImage {
        static let recommendationImage              = "mail.and.text.magnifyingglass"
        static let upArrowImage                     = "chevron.up"
        static let downArrowImage                   = "chevron.down"
        static let checkMarkImageFill               = "checkmark.seal.fill"
        static let checkMarkImage                   = "checkmark.seal"
        static let alertToastErrorImage             = "ev.plug.dc.chademo"
        static let connectSpotlightImage            = "signpost.right"
        static let backButtonImage                  = "chevron.left"
        static let photoLibraryImage                = "photo.on.rectangle"
        static let cameraIcon                       = "camera"
        static let photoUploadErrorImage            = "person.crop.square.on.square.angled"
        static let closeXmark                       = "xmark.circle.fill"
        static let closeXmarkNormal                 = "xmark"
        static let plusImage                        = "plus"
        static let personImage                      = "person.2"
        static let menuBarArrowUp                   = "menubar.arrow.up.rectangle"
        static let calenderImage                    = "calendar"
        static let personFillImage                  = "person.fill"
        static let chevronRight                     = "chevron.right"
        static let genderMenuFemale                 = "figure.stand.dress"
        static let genderMenuMale                   = "figure.stand"
        static let genderMenuOthers                 = "figure.2"
        static let filterButtonTabBar               = "slider.horizontal.2.square.on.square"
        static let maginifyingGlassImage            = "exclamationmark.magnifyingglass"
        static let circleImage                      = "checkmark.circle.fill"
        static let justCircleImage                  = "circle"
        static let largeCircleImage                 = "checkmark.circle.fill"
        static let circleHexagonal                  = "checkmark.circle"
        static let paperPlaneImage                  = "paperplane.fill"
        static let phoneImage                       = "phone.fill"
        static let singleStepSkip                   = "arrow.right.circle"
        static let skipAllImage                     = "rectangle.portrait.and.arrow.forward"
        static let locationMainPermissionImage      = "location.fill"
        static let simpleLocationIcon               = "location"
        static let bellIcon                         = "bell"
        static let trackingIcon                     = "lock.shield"
        static let bellWithNotification             = "bell.badge"
        static let bellWithoutNotification          = "bell"
        static let searchIcon                       = "magnifyingglass"
        static let locationPinHome                  = "location.north.line.fill"
        static let rightArrow                       = "arrow.right"
        static let checkMark                        = "checkmark"
        static let plusCircleFill                   = "plus.circle.fill"
        static let editOptionForPostAction          = "ellipsis.circle"
        static let arrowClockwise                   = "arrow.clockwise"
        static let exclamationMarkTriangleFill      = "exclamationmark.triangle.fill"
        static let placeHolderProfilePic            = "person.circle.fill"
        static let figureWalking                    = "figure.walk"
        static let mapCircleFill                    = "mappin.circle.fill"
        static let personFill                       = "person.2.fill"
        static let imageSafari                      = "globe.central.south.asia.fill"
        static let filterImage                      = "slider.horizontal.3"
        static let chatMainBubble                   = "bubble.left.and.text.bubble.right.fill"
        static let generalToastImage                = "lightbulb"
        static let loginDetectedScreenImage         = "person.badge.clock.fill"
        static let hourGlassFill                    = "hourglass.circle.fill"
        static let arrowForward                     = "arrow.forward"
        static let photoFill                        = "photo.fill"
        static let squareAndUpArow                  = "square.and.arrow.up"
        static let qrcodeImage                      = "qrcode"
        static let squareAndPencil                  = "square.and.pencil"
        static let shareIcon                        = "sharedwithyou"
        static let copyLink                         = "link"
        static let qrcodeLinkFinder                 = "qrcode.viewfinder"
        static let saveTray                         = "tray.and.arrow.down.fill"
        static let locationCircleFill               = "location.circle.fill"
        static let postCreationTitleImage           = "signpost.and.arrowtriangle.up.fill"
        static let postButton                       = "signpost.right.and.left.fill"
        static let tagPeopleImage                   = "person.crop.circle.badge.plus"
        static let figureWalkMotion                 = "figure.walk.motion"
        static let locationNorth                    = "location.north"
        static let selectDataAnTime                 = "calendar"
        static let liveDuration                     = "livephoto"
        static let genderIcon                       = "person.2.fill"
        static let photoOnRectangleAngled          = "photo.on.rectangle.angled"
        static let locationMagnifyingglass          = "location.magnifyingglass"
        static let fofoImage                       = "person.fill.and.arrow.left.and.arrow.right.outward"
        static let bubbleRight                     = "bubble.right"
        static let heartFill                       = "heart.fill"
        static let heartnotfilled                  = "heart"
        static let trashCan                        = "trash"
        static let hourGlassFillMenu               = "hourglass.fill"
        static let pencilFill                      = "pencil.circle.fill"
        static let clockFill                       = "clock.fill"
        static let blockedUserList                 = "stop.fill"
        static let personUnblockImage              = "person.fill.xmark"
        static let personUnFollowImage             = "person.fill.badge.minus"
        static let personRemoveFromFollers         = "person.crop.circle.badge.minus"
        static let personFollowBack                = "person.crop.circle.badge.plus"
        static let videoCamera                     = "video"
        static let playCircleFill                  = "play.circle.fill"
        static let clockArrowCirclePath            = "clock.arrow.circlepath"
        static let arrowUpRight                    = "arrow.up.right"
        static let questionMark                    = "person.crop.circle.badge.questionmark"
        static let docText                         = "doc.text"
    }
    
    // MARK: - People Image Set
    static let imageNames = [
        // Basic person symbols
        "person",
        "person.fill",
        "person.circle",
        "person.circle.fill",
        "person.crop.circle",
        "person.crop.circle.fill",
        "person.crop.square",
        "person.crop.square.fill",
        "person.crop.rectangle",
        "person.crop.rectangle.fill",
        "person.crop.artframe",
        "person.crop.rectangle.stack",
        "person.crop.rectangle.stack.fill",
        "person.crop.square.filled.and.at.rectangle",
        "person.crop.square.filled.and.at.rectangle.fill",
        "person.text.rectangle",
        "person.text.rectangle.fill",
        
        // Person with badges
        "person.badge.plus",
        "person.fill.badge.plus",
        "person.badge.minus",
        "person.fill.badge.minus",
        "person.badge.clock",
        "person.badge.clock.fill",
        "person.badge.key",
        "person.badge.key.fill",
        "person.badge.shield.checkmark",
        "person.badge.shield.checkmark.fill",
        "person.badge.shield.exclamationmark",
        "person.badge.shield.exclamationmark.fill",
        
        // Person crop circle with badges
        "person.crop.circle.badge.plus",
        "person.crop.circle.fill.badge.plus",
        "person.crop.circle.badge.minus",
        "person.crop.circle.fill.badge.minus",
        "person.crop.circle.badge.checkmark",
        "person.crop.circle.fill.badge.checkmark",
        "person.crop.circle.badge.xmark",
        "person.crop.circle.fill.badge.xmark",
        "person.crop.circle.badge.questionmark",
        "person.crop.circle.badge.questionmark.fill",
        "person.crop.circle.badge.exclamationmark",
        "person.crop.circle.badge.exclamationmark.fill",
        "person.crop.circle.badge.moon",
        "person.crop.circle.badge.moon.fill",
        "person.crop.circle.badge.clock",
        "person.crop.circle.badge.clock.fill",
        
        // Person crop square with badges
        "person.crop.square.badge.camera",
        "person.crop.square.badge.camera.fill",
        "person.crop.square.badge.video",
        "person.crop.square.badge.video.fill",
        "person.crop.square.on.square.angled",
        "person.crop.square.on.square.angled.fill",
        
        // Person groups
        "person.2",
        "person.2.fill",
        "person.2.circle",
        "person.2.circle.fill",
        "person.2.slash",
        "person.2.slash.fill",
        "person.2.badge.plus",
        "person.2.badge.plus.fill",
        "person.2.badge.minus",
        "person.2.badge.minus.fill",
        "person.2.badge.gearshape",
        "person.2.badge.gearshape.fill",
        "person.2.badge.key",
        "person.2.badge.key.fill",
        "person.2.crop.square.stack",
        "person.2.crop.square.stack.fill",
        "person.2.wave.2",
        "person.2.wave.2.fill",
    ]

    //MARK: - No Result Array Images
    static let noResultImages: [String] = [
        "magnifyingglass",
        "doc.text.magnifyingglass",
        "magnifyingglass.circle",
        "text.magnifyingglass",
        "folder.badge.questionmark",
        "questionmark.magnifyingglass",
        "exclamationmark.magnifyingglass"
    ]
    
    // MARK: - Options for Media
    enum MediaOptions {
        static func options(
            onPhotoLibraryTap: @escaping () -> Void,
            onCameraTap: @escaping () -> Void
        ) -> [
            (
                title: String,
                icon: String,
                action: () -> Void
            )
        ] {
            return [
                (title: Constants.choosePhotoTitle, icon: systemImage.photoLibraryImage, action: onPhotoLibraryTap),
                (title: Constants.cameraClick, icon: systemImage.cameraIcon, action: onCameraTap)
            ]
        }
    }
    
    enum MediaOptionsCreatePost {
        static func options(
            onPhotoLibraryTap: @escaping () -> Void,
            onCameraTap: @escaping () -> Void,
            onVideoRecordTap: @escaping () -> Void
        ) -> [
            (
                title: String,
                icon: String,
                action: () -> Void
            )
        ] {
            return [
                (title: Constants.choosePhotoOrVideo, icon: systemImage.photoLibraryImage, action: onPhotoLibraryTap),
                (title: Constants.cameraClick, icon: systemImage.cameraIcon, action: onCameraTap),
                (title: Constants.recordVideo, icon: systemImage.videoCamera, action: onVideoRecordTap)
            ]
        }
    }

    enum PermissionStep: String {
        case locationService = "Location"
        case notificationService = "Notification"
        case analytics = "App Tracking"
        case allGranted = ""
    }

    enum PermissionStatus {
        case granted, denied, notDetermined
    }
    
    enum MenuOptions {
        
        static let countryOptions = [
            PickerOption(value: "+91", displayText: "+91 - India")
        ]
        
    }
    
    enum NotificationSegmentType: String,CaseIterable {
        case all
        case activity
        
        var title: String {
            switch self {
                case .all:
                    return Constants.notificationSegmentOne
                case .activity:
                    return Constants.notificationSegmentTwo
            }
        }
    }
    
    enum HomePageSegmentControlList: String,CaseIterable {
        case all
        case plannedActivity
        case liveActivity
        
        var title: String {
            switch self {
                case .all:
                    return Constants.notificationSegmentOne
                case .plannedActivity:
                    return Constants.homepageSegmentTwo
                case .liveActivity:
                    return Constants.homepageSegmentThree
            }
        }
    }
    
    
    enum MyLiveActivitisSegments: String,CaseIterable {
        case plannedActivity
        case liveActivity
        
        var title: String {
            switch self {
                case .plannedActivity:
                    return Constants.homepageSegmentTwo
                case .liveActivity:
                    return Constants.homepageSegmentThree
            }
        }
    }
    
    enum PostSegmentControlList: String,CaseIterable {
        case GeneralPost
        case plannedActivity
        case liveActivity
        
        var title: String {
            switch self {
                case .GeneralPost:
                    return Constants.generalPost
                case .plannedActivity:
                    return Constants.plannedAct_title
                case .liveActivity:
                    return Constants.liveActivity_title
            }
        }
    }
    
    enum FollowFollowersList: String,CaseIterable {
        case Following
        case Followers
        
        var title: String {
            switch self {
                case .Following:
                    return Constants.followingText
                case .Followers:
                    return Constants.followersText
            }
        }
    }
    
    enum ChatSegmentControl: String,CaseIterable {
        case Messages
        case ExploreConnections
        
        var title: String {
            switch self {
                case .Messages:
                    return Constants.messagesPast
                case .ExploreConnections:
                    return Constants.exploreConnections
            }
        }
    }
    
    enum FeedAction {
        case like, comment, share, moreOptions
    }
    
    //MARK: - Menu items enum
    enum MenuItemID: String {
        
        // My Profile
        case aboutMe = "item1_aboutme"
        case privacySettings = "101"
        case accountSecurity = "102"
        
        // Connection History
        case recentConnections = "item2_recentconnections"
        case blockedUsers = "item2_blockedusers"
        case pendingRequests = "item2_pendingrequests"
        
        // Help Center
        case faqs = "item3_faqs"
        case contactSupport = "item3_contactsupport"
        case reportAProblem = "item3_reportaproblem"
        
        // My Account
        case personalDetails = "item4_personaldetails"
        case changeMobileNumber = "item4_changepassword"
        case deleteAccount = "item4_deleteaccount"
        case themesLightDarkMode = "item4_themeslightdarkmode"
        
        // Chat Settings
        case enableDisableChat = "item5_enabledisablechat"
        case chatPrivacy = "item5_chatprivacy"
        case blockedContacts = "item5_blockedcontacts"
        
        // Notification Settings
        case pushNotifications = "item6_pushnotifications"
        case emailNotifications = "item6_emailnotifications"
        case soundVibration = "item6_soundvibration"
        
        // About App
        case versionInfo = "item7_versioninfo"
        case termsConditions = "item7_termsconditions"
        case privacyPolicy = "item7_privacypolicy"
        
        // Share App
        case shareApp = "item8_share"
        case copyInviteLink = "item8_copyinvitelink"
        
        // App Feedback & Ratings
        case rateUs = "item9_rateus"
        case submitFeedback = "item9_submitfeedback"
        
        // Log Out
        case logOut = "701"
    }
    
    static let logoutLabelOptions: [String] = [
        "Sign Out",
        "Exit Account",
        "End Session",
        "Log Off",
        "Disconnect",
        "Peace Out 👋",
        "Catch You Later ✌️",
        "Bounce Out 🚪",
        "See Ya! 👋",
        "Power Down 🔌",
        "Take a Break 💤",
        "Outta Here 🚶‍♂️",
        "Time to Go 🕒",
        "Wrap It Up",
        "Done for Today",
        "Heading Out",
        "Rest Mode",
        "Clocking Out",
        "Save & Exit",
        "End Game",
        "Quit Mission",
        "Exit Portal",
        "Ctrl+Alt+Bye 💻"
    ]
    
    static let playfulFeedbackPrompts = [
        "Spill the tea on your app experience ☕",
        "We’re all ears! How did we do?",
        "Be honest... how’s it going?",
        "Your feedback = our superpower 💥",
        "Help us make your experience even better!",
        "Got thoughts? We’re listening 🎧",
        "Swipe us some feedback magic ✨",
        "Rate us like you rate memes 😂",
        "Tell us what made you smile (or frown) 😇😈",
        "Don’t hold back — we can take it 💪",
        "Your opinion fuels our updates 🔧",
        "Help us glow up this app 💅",
        "Is this app a yay or nay? 📱",
        "You + Feedback = Better Us ❤️",
        "Give it to us straight, no chaser 😎"
    ]
    
    static let bioSegmentTitles: [String] = [
        ("About Me 🧍"),
        ("My Story 📖"),
        ("Who I Am 🧠"),
        ("A Little About Me ✨"),
        ("This Is Me 🙋‍♂️"),
        ("Get to Know Me 👋"),
        ("Behind the Profile 🎭"),
        ("What I Love ❤️"),
        ("Fun Facts 🤓"),
        ("In a Nutshell 🥜"),
        ("Personal Vibes 🌈"),
        ("Quick Intro ⚡️"),
        ("Bio Snapshot 📸"),
        ("My Journey 🛤️"),
        ("The Basics 📌")
    ]
    
    static let hobbiesAndInterestsTitles: [String] = [
        ("My Hobbies 🎨"),
        ("What I Love Doing 💖"),
        ("Passions & Interests 🔥"),
        ("Things I Enjoy 😌"),
        ("Free Time Favorites 🌿"),
        ("Off-Duty Vibes 😎"),
        ("Beyond Work 🌍"),
        ("Weekend Rituals 📅"),
        ("Creative Outlets 🎭"),
        ("My Favorite Activities 🏄"),
        ("When I Unplug 🔌"),
        ("Joyful Moments 😊"),
        ("Leisure Time 🛋️"),
        ("Let’s Talk Fun 🥳"),
        ("What Keeps Me Going ⚡️")
    ]

    static let noNetworkArray: [String] = [
        "space",
        "world",
        "cycle",
        "person"
    ]

    static let loginAnimations: [String] = [
        "MenWomen",
        "Car"
    ]

    static let noInternetTitle = [
        "Internet? Never Heard of It!",
        "Oops! Wi-Fi Went on Vacation",
        "404: Connection Not Found",
        "The Wi-Fi Giveth and Taketh Away",
        "Signal Missing: Send Snacks",
        "You’re on the Internet Diet",
        "Even Your Internet Ghosted You",
        "No Net. Just Chill.",
        "Oopsie, Your Wi-Fi Tripped",
        "Internet's Out Party – BYOR (Bring Your Own Router)"
    ]

    static let noInternetDescriptions = [
        "Your connection took a coffee break ☕️. Try again once it’s back from vacation.",
        "No signal, no cry... well, maybe a little.",
        "The internet is playing hide and seek. And it’s winning.",
        "We tried connecting. The internet swiped left.",
        "Even the router is socially distancing.",
        "Your Wi-Fi went out for milk and never came back.",
        "Offline is the new online, right?",
        "Lost connection — found peace?",
        "Our servers are confused. So is your internet.",
        "Try again later, or try begging your router nicely."
    ]

    static let noChatAnimations = [
        "NoMessages",
        "Dancecat",
        "BottleRock"
    ]
}
