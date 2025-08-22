//
//  NotificationCodable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-03-2025.
//

import Foundation

// MARK: - Models
struct NotificationResponse: Codable {
    let success: Bool
    let statusCode: Int
    let message: String
    let totalNotification: Int
    let totalPage: Int
    let currentPage: Int
    let notifications: [NotificationItem]
}

struct NotificationItem: Codable, Identifiable {
    let id: String
    let receiverId: String
    let senderId: String?
    let type: String
    let handlingStatus: String?
    let status: String
    let errorInfo: String?
    let message: String
    let imageUrl: String?
    let relatedPostId: String?
    let participationId: String?
    let isRead: Bool?
    let createdAt: String
    let updatedAt: String
    let postId: String?
    let sender: NotificationSender?
    let post: NotificationPost?

    enum CodingKeys: String, CodingKey {
        case id, receiverId, senderId, type, handlingStatus, status, errorInfo, message, relatedPostId, participationId, isRead, createdAt, updatedAt, sender
        case imageUrl = "image_url"
        case postId = "post_id"
        case post = "Post"
    }
}

struct NotificationSender: Codable {
    let profilePicUrl: String
    let userId: String
    let username: String
    let name: String
    let about: String
    let userActivities: [Int]

    enum CodingKeys: String, CodingKey {
        case profilePicUrl, userId, username, name, about
        case userActivities = "user_activities"
    }
}

struct NotificationPost: Codable {
    let mediaFiles: [MediaFileNotification]?
    let userId: String?
    let caption: String?
    let startTime: String?
    let endTime: String?
    let location: String?

    enum CodingKeys: String, CodingKey {
        case userId, caption, location
        case mediaFiles = "media_files"
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

struct MediaFileNotification: Codable {
    let url: String
    let type: String
    let s3Key: String
    let mimetype: String
}
