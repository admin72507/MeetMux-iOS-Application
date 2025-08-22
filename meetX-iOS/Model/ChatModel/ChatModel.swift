//
//  ChatModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 06-04-2025.
//

import Foundation

// MARK: - Offline Online Users List Response
struct OnlineOfflineUsersList: Codable {
    let users: [UserData]?
    let page: Int?
    let pageSize: Int?
    let total: Int?
    
    enum CodingKeys: String, CodingKey {
        case users = "data"
        case page
        case pageSize
        case total
    }
}

// MARK: - User Data
struct UserData: Codable {
    let isRecentChat: Bool?
    let isUserActive: Bool?
    let name: String?
    let profilePicUrl: String?
    let userId: String?
    let username: String?
    
    enum CodingKeys: String, CodingKey {
        case isRecentChat
        case isUserActive
        case name
        case profilePicUrl
        case userId
        case username
    }
    
    // Custom decoder to handle integer to boolean conversion
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle isRecentChat (can be Int or Bool)
        if let intValue = try? container.decode(Int.self, forKey: .isRecentChat) {
            isRecentChat = intValue != 0
        } else {
            isRecentChat = try container.decodeIfPresent(Bool.self, forKey: .isRecentChat)
        }
        
        // Handle isUserActive (can be Int or Bool)
        if let intValue = try? container.decode(Int.self, forKey: .isUserActive) {
            isUserActive = intValue != 0
        } else {
            isUserActive = try container.decodeIfPresent(Bool.self, forKey: .isUserActive)
        }
        
        // Decode other properties normally
        name = try container.decodeIfPresent(String.self, forKey: .name)
        profilePicUrl = try container.decodeIfPresent(String.self, forKey: .profilePicUrl)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        username = try container.decodeIfPresent(String.self, forKey: .username)
    }
}

// MARK: - RecentChatResponse
struct RecentChatResponse: Codable {
    let recentChats: [RecentChat]?
    let currentPage: Int?
    let totalCount: Int?
    let limit: Int?
}

// MARK: - RecentChat
struct RecentChat: Codable {
    let conversationId: String?
    let createdAt: String?
    var messages: [ChatMessage]? // last 10 messages
    let name: String?
    let profilePicUrl: String?
    let receiverId: String?
    var unreadCount: Int? // This will not come in chat room response
    let username: String?
    var isMuted: Bool? // This will not come in chat room response
    let totalMessages: Int? // Hold total message in the list, if total messages is greater than var messages: [ChatMessage]? // last 10 messages, show the load old messages in UI or else dont
}

// MARK: - General Chat Response
struct ChatHistoryResponse: Codable {
    let messages: [ChatMessage]?
    let totalCount: Int?
    let currentPage: Int?
    let totalPages: Int?
    let hasMore: Bool?

    enum CodingKeys: String, CodingKey {
        case messages
        case totalCount = "total_count"
        case currentPage = "current_page"
        case totalPages = "total_pages"
        case hasMore = "has_more"
    }
}

// MARK: - ChatMessage
struct ChatMessage: Codable, Identifiable {
    let id: String?
    var messageText: String?
    let messageType: String?
    let mediaUrl: String?
    let senderId: String?
    let receiverId: String?
    let roomId: String? // not needed
    let isMessageRead: Bool?
    var deletedAt: String? // if deletedAt is null show the message text or else it has a value then show in UI message is deleted
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case messageText = "message_text"
        case messageType = "message_type"
        case mediaUrl = "media_url"
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case roomId = "room_id"
        case isMessageRead
        case deletedAt = "deleted_at"
        case createdAt
        case updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        messageText = try container.decodeIfPresent(String.self, forKey: .messageText)
        messageType = try container.decodeIfPresent(String.self, forKey: .messageType)
        mediaUrl = try container.decodeIfPresent(String.self, forKey: .mediaUrl)
        senderId = try container.decodeIfPresent(String.self, forKey: .senderId)
        receiverId = try container.decodeIfPresent(String.self, forKey: .receiverId)
        roomId = try container.decodeIfPresent(String.self, forKey: .roomId)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        
        // Custom decoding for isMessageRead - handle both Int and Bool from API
        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: .isMessageRead) {
            isMessageRead = boolValue
        } else if let intValue = try? container.decodeIfPresent(Int.self, forKey: .isMessageRead) {
            isMessageRead = intValue == 1
        } else {
            isMessageRead = nil
        }
    }
}

// MARK: - Type of messages supported
enum MessageType: String {
    case text
    case image
    case video
    case audio
    case unknown
    
    init(rawValue: String) {
        switch rawValue.lowercased() {
            case "text": self = .text
            case "image": self = .image
            case "video": self = .video
            case "audio": self = .audio
            default: self = .unknown
        }
    }
}

// MARK: - Send message to user
extension RecentChat {
    /// Appends a message to the current recent chat's message list
    mutating func appendMessage(_ newMessage: ChatMessage) {
        if messages == nil {
            messages = [newMessage]
        } else {
            messages?.append(newMessage)
        }
    }
}


// MARK: - ChatMessage Extensions for Optimistic Updates
extension ChatMessage {
    init(id: String?, messageText: String?, messageType: String?, mediaUrl: String?,
         senderId: String?, receiverId: String?, roomId: String?, isMessageRead: Bool?,
         deletedAt: String?, createdAt: String?, updatedAt: String?) {
        self.id = id
        self.messageText = messageText
        self.messageType = messageType
        self.mediaUrl = mediaUrl
        self.senderId = senderId
        self.receiverId = receiverId
        self.roomId = roomId
        self.isMessageRead = isMessageRead
        self.deletedAt = deletedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}


// MARK: - General Chat call back response
struct generalCallBackChatResponse: Codable {
    let success: String?
    let message: String?
    let statusCode: Int?
}

extension generalCallBackChatResponse {
    var isSuccess: Bool {
        return success?.lowercased() == "true"
    }
}

  struct generalMuteDeleteResponse: Codable {
    let success: Bool?
    let message: String?
    let statusCode: Int?
}

extension RecentChat {
    mutating func updateIsMuted(to newValue: Bool) {
        self.isMuted = newValue
    }

    mutating func toggleMute() {
        self.isMuted = !(self.isMuted ?? false)
    }
}
