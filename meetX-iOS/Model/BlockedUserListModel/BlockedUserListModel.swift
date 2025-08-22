//
//  BlockedUserListModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 26-05-2025.
//

// MARK: - Blocked User List Response
struct BlockedUserListModel: Codable {
    let message: String?
    let data: [BlockedUser]?
    let count: Int?
    let page: Int?
    let limit: Int?
}

// MARK: - Blocked User
struct BlockedUser: Codable, Identifiable, Equatable, Hashable {
    let userId: String?
    let username: String?
    let name: String?
    let profilePicUrl: String?
    
    var id: String { userId ?? "" }
    
    static func == (lhs: BlockedUser, rhs: BlockedUser) -> Bool {
        return lhs.userId == rhs.userId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
    }
}
