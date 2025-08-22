//
//  ConnectActionResponseModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 02-06-2025.
//

import Foundation

struct ConnectActionResponse: Codable {
    let success: Bool?
    let action: String?
    let accountType: String?
    let follow: FollowStatus?
    let chat: ChatStatus?
    let message: String?
}

struct FollowStatus: Codable {
    let reverted: Bool?
    let status: String?
    let message: String?
}

struct ChatStatus: Codable {
    let reverted: Bool?
    let status: String?
    let message: String?
}
