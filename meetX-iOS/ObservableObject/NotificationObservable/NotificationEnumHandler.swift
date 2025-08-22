//
//  NotificationEnumHandler.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 01-06-2025.
//

// MARK: - Notification Types Enum
enum NotificationType: String, CaseIterable {
    case newPost = "new_post"
    case like = "like"
    case comment = "comment"
    case activityInterestAccept = "activity_interest_accept"
    case activityInterestRequest = "activity_interest_request"
    case followAccepted = "follow_accepted"
    case followRequest = "follow_request"
    case follow = "follow"
    case commentLike = "comment_like"
    case commentReply = "comment_reply"
    case chatConnectionRequest = "chat_connection_request"
    case chatConnectionAccept = "chat_connection_accept"
    
    var displayName: String {
        switch self {
            case .newPost: return "Post"
            case .like: return "Likes"
            case .comment: return "Comments"
            case .activityInterestAccept: return "Activity Accepted"
            case .activityInterestRequest: return "Activity Request"
            case .followAccepted: return "Followed Back"
            case .followRequest: return "Follow Request"
            case .follow: return "Follower"
            case .commentLike: return "Comment Like"
            case .commentReply: return "Reply"
            case .chatConnectionRequest: return "Chat Request"
            case .chatConnectionAccept: return "Chat Accepted"
        }
    }
    
    var needsActionButtons: Bool {
        switch self {
            case .activityInterestRequest, .followRequest, .chatConnectionRequest:
                return true
            default:
                return false
        }
    }
    
    var isActivityType: Bool {
        switch self {
            case .activityInterestRequest, .followRequest, .chatConnectionRequest:
                return true
            default:
                return false
        }
    }
}

// MARK: - Tab Type
enum NotificationTab: String, CaseIterable {
    case all = "All"
    case activity = "Activity"
    
    var displayName: String {
        return rawValue
    }
}

// MARK: - View State
enum ViewState: Equatable {
    case loading
    case loaded
    case empty
    case error(String)
    
    static func ==(lhs: ViewState, rhs: ViewState) -> Bool {
        switch (lhs, rhs) {
            case (.loading, .loading),
                (.loaded, .loaded),
                (.empty, .empty):
                return true
            case (.error(let a), .error(let b)):
                return a == b
            default:
                return false
        }
    }
}
