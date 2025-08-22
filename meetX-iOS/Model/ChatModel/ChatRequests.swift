//
//  ChatRequests.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 16-07-2025.
//

struct DeleteConversationRequest: Codable {
    let conversationId: String
}

struct ReportChatConversationRequest: Codable {
    let receiverId: String
    let reportReason: String
    let description: String?
}
