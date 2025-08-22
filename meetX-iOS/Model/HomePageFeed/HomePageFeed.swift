//
//  HomePageFeed.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 18-05-2025.
//

import Foundation

struct FeedItems: Codable {
    var totalCount: Int?
    let count: Int?
    let limit: Int?
    let page: Int?
    var posts: [PostItem]?
    let currentUserInterests: [SubActivitiesModel]?
}

// MARK: - PostItem
struct PostItem: Codable, Identifiable {
    var id: String { postID ?? UUID().uuidString }
    
    let postID: String?
    let caption: String?
    let latitude: Double?
    let longitude: Double?
    let location: String?
    let eventDate: String?
    let endDate: String?
    let endTime: String?
    let postType: String?
    let mediaFiles: [MediaFile]?
    let locationImageUrl: String?
    let visibility: String?
    var isActive: Bool?
    let approvalStatus: String?
    let genderRestriction: String?
    var likeCount: Int?
    var totalLikes: Int?
    let likedUserIds: [String]?
    let commentLikes: [String]?
    let totalCommentLikes: Int?
    let sharesCount: Int?
    var totalComments: Int?
 //   let interestedUsers: []?
    let peopleTags: [PeopleTags]?
    let activityTags: [ActivityTag]?
    let comments: [CommentItem]?
    let totalInterestedUsers: Int?
    let totalJoinedUsers: Int?
    let joinedUserTags: [PeopleTags]?
    let liveDuration: String?
    let createdAt: String?
    let updatedAt: String?
    let maxparticipants: Int?
    let user: FeedUserDetail?
    var userContext: UserContext?
    
    enum CodingKeys: String, CodingKey {
        case postID = "post_id"
        case caption
        case latitude
        case longitude
        case location
        case eventDate = "event_date"
        case endDate = "end_date"
        case endTime = "end_time"
        case postType = "post_type"
        case mediaFiles = "media_files"
        case locationImageUrl = "locationPhotoURL"
        case visibility
        case isActive = "is_active"
        case approvalStatus = "approval_status"
        case genderRestriction = "gender_restriction"
        case likeCount = "like_count"
        case totalLikes = "total_likes"
        case likedUserIds = "liked_user_ids"
        case commentLikes = "comment_likes"
        case totalCommentLikes = "total_comment_likes"
        case sharesCount = "shares_count"
        case totalComments = "total_comments"
    //    case interestedUsers = "interested_users"
        case peopleTags = "people_tags"
        case activityTags = "activity_tags"
        case comments
        case totalInterestedUsers = "total_interested_users"
        case totalJoinedUsers = "total_joined_users"
        case joinedUserTags = "joined_userTags"
        case liveDuration = "live_duration"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
        case userContext
        case maxparticipants = "max_participants"
    }
}

// MARK: - People Tags
struct PeopleTags: Codable, Identifiable {
    var id: String { userId }
    
    let userId: String
    let name: String
    let username: String
    let profilePicUrl: String
}

// MARK: - MediaFile
struct MediaFile: Codable {
    let type: String?
    let url: String?
    let mimetype: String?
}

// MARK: - ActivityTag
struct ActivityTag: Codable {
    let subcategories: [Subcategory]?
    let mainCategoryId: Int?
    let mainCategoryName: String?
}

// MARK: - Subcategory
struct Subcategory: Codable {
    let id: Int?
    let title: String?
    let platformIos: String?
    let platformAndroid: String?
}

// MARK: - FeedUserDetail
struct FeedUserDetail: Codable {
    let userId: String?
    let username: String?
    let name: String?
    let profilePicUrl: String?
}

// MARK: - UserContext
struct UserContext: Codable {
    var hasLiked: Bool?
    let hasCommented: Bool?
    var hasShownInterest: Bool?
    var isInterestRequested: Bool?
}

// MARK: - CommentItem
struct CommentItem: Codable {
    let id: String?
    let text: String?
    let userId: String?
    let createdAt: String?
    let postId: String?
    let likedUserIds: [String]?
    let likeCount: Int?
    let replyCount: Int?
    let profilePicUrl: String?
    let userName: String?
    let commentOwner: Bool?
    var name: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case userId
        case createdAt = "created_at"
        case postId = "post_id"
        case likedUserIds = "liked_user_ids"
        case likeCount
        case replyCount
        case profilePicUrl
        case userName
        case commentOwner
        case user
        case name = "name"
    }
    
    // Custom decode to flatten 'user'
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        postId = try container.decodeIfPresent(String.self, forKey: .postId)
        likedUserIds = try container.decodeIfPresent([String].self, forKey: .likedUserIds)
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount)
        replyCount = try container.decodeIfPresent(Int.self, forKey: .replyCount)
        commentOwner = try container.decodeIfPresent(Bool.self, forKey: .commentOwner)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        
        if let user = try container.decodeIfPresent(UserComment.self, forKey: .user) {
            profilePicUrl = user.profilePicUrl
            userName = user.username
            name = user.name
        } else {
            profilePicUrl = ""
            userName = ""
            name = ""
        }
    }
    
    // Manual encode to flatten 'user' fields
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(postId, forKey: .postId)
        try container.encodeIfPresent(likedUserIds, forKey: .likedUserIds)
        try container.encodeIfPresent(likeCount, forKey: .likeCount)
        try container.encodeIfPresent(replyCount, forKey: .replyCount)
        try container.encodeIfPresent(commentOwner, forKey: .commentOwner)
        try container.encodeIfPresent(name, forKey: .name)
        
        // Reconstruct nested 'user' object if profilePicUrl or userName exists
        if profilePicUrl != nil || userName != nil {
            let user = UserComment(
                userId: userId,
                name: name,
                username: userName,
                profilePicUrl: profilePicUrl
            )
            try container.encode(user, forKey: .user)
        }
    }
}

// MARK: - Nested User Model
struct UserComment: Codable {
    let userId: String?
    let name: String?
    let username: String?
    let profilePicUrl: String?
}


// MARK: - Extension for PostType
extension PostItem {
    var feedType: DeveloperConstants.FeedTypes {
        DeveloperConstants.FeedTypes(from: postType ?? "")
    }
}


// MARK: - Extension of post
extension PostItem {
    
    mutating func updateFromFollowResponse(_ response: InterestPostResponse) {
        if let status = response.status {
            if status.lowercased() == "pending" {
                self.userContext?.isInterestRequested = true
                self.userContext?.hasShownInterest = false
            } else {
                self.userContext?.hasShownInterest = true
                self.userContext?.isInterestRequested = false
            }
        } else if response.message?.lowercased() == "Interest revoked successfully".lowercased() {
            self.userContext?.hasShownInterest = false
            self.userContext?.isInterestRequested = false
        }
    }
}

// MARK: - PostItem Like Extension
extension PostItem {
    /// Keep this for backward compatibility or other use cases
    mutating func updateLikeStatus(success: Bool, totalLikesR: Int) {
        guard success else {
            debugPrint("❌ Like operation failed, not updating post")
            return
        }
        
        // Get current like status
        let currentLikeStatus = userContext?.hasLiked ?? false
        
        // Initialize userContext if nil
        if userContext == nil {
            userContext = UserContext(
                hasLiked: !currentLikeStatus,
                hasCommented: false,
                hasShownInterest: false,
                isInterestRequested: false
            )
        } else {
            // Toggle like status
            userContext?.hasLiked = !currentLikeStatus
        }
        
        // Update total likes count
        totalLikes = totalLikesR
        debugPrint("📊 Total likes updated to \(totalLikes!) for post \(postID ?? "unknown")")
        debugPrint("✅ Post \(postID ?? "unknown") like status updated: \(!currentLikeStatus)")
    }
}

extension PostItem {
    
    /// Removes the current post from a mutable array in-place
    /// - Parameter posts: In-out array of `PostItem`
    func removePostItemSingle(from posts: inout [PostItem]) {
        posts.removeAll { $0.id == self.id }
    }
}

// MARK: - Comment Increasing count
extension PostItem {
    
    /// Increments the total comment count for the post by 1
    mutating func incrementCommentCount(updatedCount: Int) {
            totalComments = updatedCount
    }
}

extension PostItem: Equatable {
    static func == (lhs: PostItem, rhs: PostItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Location updation model
struct SelectedLocation: Codable, Equatable, Hashable {
    let mainName: String
    let entireName: String
    let latitude: Double?
    let longitude: Double?
}

