//
//  BlockSingleUser.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 26-05-2025.
//

import Foundation

struct BlockSingleUser: Codable {
    let success: Bool
    let message: String
    let blockedEntry: BlockedEntry
}

struct BlockedEntry: Codable {
    let id: String
    let blockerUserID: String
    let blockedUserID: String
    let updatedAt: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case blockerUserID = "blocker_user_id"
        case blockedUserID = "blocked_user_id"
        case updatedAt
        case createdAt
    }
}
