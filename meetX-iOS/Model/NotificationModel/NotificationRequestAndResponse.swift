//
//  NotificationRequestAndResponse.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 05-06-2025.
//

struct ConnectionAcceptRequest: Codable {
    var requesterId: String
    var type: String // or "follow" or "chat"
}


struct ConnectAcceptResponse: Codable {
    var success: Bool
    var message: String
}

// MARK: - Follow Codable for Accept and Decline
struct FollowAcceptDeclineRequest: Codable {
    var senderId: String
    var action: String // accept / decline
}

struct FollowAcceptResponse: Codable {
    var message: String
}

// MARK: - Activity invite
struct ActivityRequest: Codable {
    var action: String
    var postId: String
    var participationId: String
    
    enum CodingKeys: String, CodingKey {
        case action
        case postId = "post_id"
        case participationId
    }
}

struct InterestResponse: Codable {
    let success: Bool?
    let statusCode: Int?
    let message: String?
    let updatedApprovedCount: Int?
}

struct LikeResponseExplore: Codable {
    let message: String?
    let postId: String?
    let totalLikes: Int?
    let success: Bool?
    let statusCode: Int?
}
