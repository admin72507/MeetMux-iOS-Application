//
//  PlannedActivityPostRequest.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 30-05-2025.
//

import Foundation

struct PlannedActivityPostRequest : Codable {
    let action: String
    let visibility: String
    let latitude: Double
    let longitude: Double
    let caption: String
    let peopleTags: [String]
    let activityTags: [Int]
    let maxParticipants: Int?
    let genderRestriction: String
    let mediaUrls: [String]
    let startTime: String
    
    enum CodingKeys: String, CodingKey {
        case action = "action"
        case visibility = "visibility"
        case latitude
        case longitude
        case maxParticipants = "max_participants"
        case caption = "caption"
        case peopleTags = "people_tags"
        case activityTags = "activity_tags"
        case mediaUrls = "media_urls"
        case startTime = "start_time"
        case genderRestriction = "gender_restriction"
    }
}
