//
//  ConnectAndFollowModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 05-06-2025.
//

import Foundation

// MARK: - Main Response Model
struct ConnectAndFollowModel: Codable {
    let success: Bool
    let action: String
    let accountType: String
    let follow: FollowDetails
    let chat: ChatDetails
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case action
        case accountType
        case follow
        case chat
        case message
    }
}

// MARK: - Follow Details Model
struct FollowDetails: Codable {
    let sent: Bool?
    let status: String
    let message: String
    let reverted: Bool?
    
    enum CodingKeys: String, CodingKey {
        case sent
        case status
        case message
        case reverted
    }
}

// MARK: - Chat Details Model
struct ChatDetails: Codable {
    let sent: Bool?
    let status: String
    let message: String
    let reverted: Bool?
    
    enum CodingKeys: String, CodingKey {
        case sent
        case status
        case message
        case reverted
    }
}
