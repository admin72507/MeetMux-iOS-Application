//
//  SubmitFeebbackResponse.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 25-05-2025.
//

import Foundation

// MARK: - Root Response
struct FeedbackResponse: Codable {
    let message: String
    let userFeedback: UserFeedback
    
    enum CodingKeys: String, CodingKey {
        case message
        case userFeedback = "user_feedback"
    }
}

// MARK: - User Feedback
struct UserFeedback: Codable, Identifiable {
    let id: String
    let optionalComments: String?
    let feedbackEmoji: String
    let feedbackUserId: String
    let feedbackUserName: String
    
    enum CodingKeys: String, CodingKey {
        case id = "User_FeedbackId"
        case optionalComments = "Optional_Comments"
        case feedbackEmoji = "Feedback_Emoji"
        case feedbackUserId
        case feedbackUserName
    }
}
