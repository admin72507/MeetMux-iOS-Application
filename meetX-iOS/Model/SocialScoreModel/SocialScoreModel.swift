//
//  SocialScoreModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 17-08-2025.
//

import Foundation

struct SocialScore: Codable {
    let totalScore: Int?
    let categoryBreakdown: CategoryBreakdown?
    let rankLabel: String?
    let lastUpdated: String?
    let tips: [String]?
    let profileBreakdown: ProfileBreakdown?
    let activityBreakdown: ActivityBreakdown?
    let networkBreakdown: NetworkBreakdown?
}

struct CategoryBreakdown: Codable {
    let profile: Int?
    let activity: Int?
    let consistency: Int?
    let behavior: Int?
    let network: Int?
}

struct ProfileBreakdown: Codable {
    let profileVerified: Int?
    let allFieldsCompleted: Int?
    let displayPictureUploaded: Int?
}

struct ActivityBreakdown: Codable {
    let plannedActivities: Int?
    let liveActivities: Int?
    let engagement: Int?
}

struct NetworkBreakdown: Codable {
    let acceptedConnections: Int?
    let followers: Int?
}
