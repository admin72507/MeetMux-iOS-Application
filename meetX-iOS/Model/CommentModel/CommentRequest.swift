//
//  CommentRequest.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 23-06-2025.
//

struct CommentRequest: Codable {
    var text: String?
    var postId: String?
}


struct CommentEditRequest: Codable {
    var text: String?
    var commentId: String?
}


struct CommentLikeRequest: Codable {
    var commentId: String?
}
