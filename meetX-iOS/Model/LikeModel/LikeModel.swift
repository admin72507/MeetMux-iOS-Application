//
//  LikeModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 23-06-2025.
//

struct LikeResponse: Codable {
    let postId: String?
    let totalLikes: Int?
    let success: Bool?
    var statusCode: Int? = 200
    let message: String?
}
