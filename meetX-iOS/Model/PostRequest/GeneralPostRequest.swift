//
//  GeneralPostRequest.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 30-05-2025.
//

struct GeneralPostRequest: Codable {
    let action: String
    let visibility: String
    let latitude: Double
    let longitude: Double
    let caption: String
    let peopleTags: [String]
    let activityTags: [Int]
    let mediaUrls: [String]
    
    enum CodingKeys: String, CodingKey {
        case action = "action"
        case visibility = "visibility"
        case latitude
        case longitude
        case caption = "caption"
        case peopleTags = "people_tags"
        case activityTags = "activity_tags"
        case mediaUrls = "media_urls"
    }
}
