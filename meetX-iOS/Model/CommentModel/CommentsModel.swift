//
//  CommentsModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 23-06-2025.
//

struct CommentsModel: Codable {
    let success: Bool?
    let statusCode: Int?
    let message: String?
    let comments: [CommentItem]?
    let currentPage: Int?
    let limit: Int?
    let totalComments: Int?
}
