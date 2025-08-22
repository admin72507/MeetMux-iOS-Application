//
//  ExploreDetailRequestResponse.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 08-06-2025.
//

struct ExploreDetailRequestEndPost : Codable {
    var postId : String
    
    enum CodingKeys : String, CodingKey {
        case postId = "post_id"
    }
}
