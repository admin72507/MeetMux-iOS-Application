//
//  InterestPostRequestResponseModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 07-06-2025.
//

struct InterestPostRequest: Codable {
    let postId: String
}

struct InterestPostResponse: Codable {
    let success: Bool?
    let statusCode: Int?
    let message: String?
    let participationId: String?
    let totalInterestedUsers: Int?
    let totalApprovedUsers: Int?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case statusCode
        case message
        case participationId = "participation_id"
        case totalInterestedUsers = "total_interested_users"
        case totalApprovedUsers = "total_approved_users"
        case status
    }
}

