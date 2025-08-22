//
//  FollowingFollowersModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 26-05-2025.
//

// MARK: - Blocked User List Response
struct FollowingFollowersModel: Codable {
    let message: String?
    let data: [FollowingFollowersItem]?
    let totalCount: Int?
    let count: Int?
    let currentPage: Int?
    let limit: Int?
}

// MARK: - Blocked User
struct FollowingFollowersItem: Codable, Identifiable, Equatable, Hashable {
    let userId: String?
    let username: String?
    let name: String?
    let profilePicUrls: String?
    let isFollowing: Bool?
    
    var id: String { userId ?? "" }
    
    static func == (lhs: FollowingFollowersItem, rhs: FollowingFollowersItem) -> Bool {
        return lhs.userId == rhs.userId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
    }
}
