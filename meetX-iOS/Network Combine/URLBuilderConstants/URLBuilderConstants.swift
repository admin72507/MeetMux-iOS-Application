//
//  URLBuilderConstants.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 22-04-2025.
//

import Foundation

struct URLBuilderConstants {
    
    enum ClientPathAppender: String {
        case loginSignup = "otp"
        case getActivitiesList = "activity"
        case needSupport = "support"
        case profileUpdate = "profile"
        case controlCenterConfiguration = "menus"
        case deleteDeactiveAccount = "account-action"
        case homePageFeed = "homepage-feed"
        case tagConnectionList = "chat/connection/connectionlist"
        case submitFeedback = "feedback"
        case getTheBlockedUserList = "block/blockedUsers"
        case searchTheBlockedUserList = "block/blockedUsers/search"
        case blockUser = "block"
        case followList = "followlist"
        case unFollowFollowBack = "follow"
        case getTheUserProfileDetails = "profile/getProfile"
        case generalPostCreation = "posts/generalactivity"
        case plannedPostCreation = "posts/plannedactivity"
        case livePostCreation = "posts/liveactivity"
        case recommendedProfiles = "suggestedUsers"
        case notificationList = "notifications"
        case searchUser = "search/profile"
        case connectSystem = "connect"
        case acceptConnection = "connect/accept"
        case declineConnection = "connect/decline"
        case handleFollowAcceptAndDecline = "manage-request"
        case exploreActivities = "activities/explore"
        case handleInterestInPost = "posts/interest"
        case handleActivityInvitePost = "posts/manageInterest"
        case endLiveActivity = "posts/end"
        case fetchAllUserActivities = "posts/getActivePosts"
        case sendUserFCMToken = "notifications/update-fcm-token"
        case editProfile = "editProfile"
        case getAllTheComments = "comment/commentAction"
        case toggleLikeandDislike = "like/toggleLike"
        case singlePostFetch = "posts/getSinglePost"
        
        //Chat API
        case onlineOfflineUserList = "active"
        case searchConnectionUser = "chat/searchUser"
        case loadMoreMessages = "chat"
        case reportChat = "chat/reportChat"
    }
    
    static func URLBuilder(type : ClientPathAppender, value: String? = "") -> String {
        let appendTheBase = DeveloperConstants.Network.urlBaseAppender + type.rawValue
        return value == "" ? appendTheBase : appendTheBase + value!
    }
    
}

// MARK: - HomePage FeedURL Builder
extension URLBuilderConstants {

    static func appendQueryParameters(
        to urlString: String,
        parameters: [String: String]
    ) -> String? {
        guard var components = URLComponents(string: urlString) else {
            return nil
        }
        
        var queryItems = components.queryItems ?? []
        for (key, value) in parameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        components.queryItems = queryItems
        
        return components.url?.absoluteString
    }


    enum ActivityType: String {
        case all = "0"
        case general = "1"
        case planned = "2"
        case liveActivity = "3"
    }
    
    static func homeFeedAppender(
        activityType: ActivityType = .all,
        page: Int = 1,
        limit: Int = 10,
        latitude: Double? = nil,
        longitude: Double? = nil,
        interest: [Int]? = nil
    ) -> String? {
        
        let base = DeveloperConstants.Network.socketSchema
        + DeveloperConstants.BaseURL.baseURL
        + DeveloperConstants.Network.urlBaseAppender
        + ClientPathAppender.homePageFeed.rawValue
        
        var components = URLComponents(string: base)
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "type", value: activityType.rawValue),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        if let lat = latitude {
            queryItems.append(URLQueryItem(name: "lat", value: String(lat)))
        }
        if let long = longitude {
            queryItems.append(URLQueryItem(name: "long", value: String(long)))
        }
        if let interestList = interest, !interestList.isEmpty {
            let interestValue = interestList.map(String.init).joined(separator: ",")
            queryItems.append(URLQueryItem(name: "interest", value: interestValue))
        }
        
        components?.queryItems = queryItems
        return components?.url?.absoluteString
    }
}
