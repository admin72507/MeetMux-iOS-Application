//
//  ConnectionListModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-05-2025.
//

import Foundation

// MARK: - Root Response
struct ConnectionListModel: Codable {
    let success: Bool?
    let currentPage: Int?
    let limit: Int?
    let totalCount: Int?
    let connectedUsers: [ConnectedUser]?
}

// MARK: - User Model
struct ConnectedUser: Codable, Identifiable, Equatable, Hashable {
    let userId: String?
    let name: String?
    let username: String?
    let email: String?
    let profilePicUrl: String?
    
    var id: String { userId ?? "" }
    
    static func == (lhs: ConnectedUser, rhs: ConnectedUser) -> Bool {
        return lhs.userId == rhs.userId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
    }
}

