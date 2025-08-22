//
//  MyLiveActivitiesModelScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 08-06-2025.
//

// MARK: - Codable Models
struct ActivityResponse: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalItems: Int
    var activities: [PostItem]
}
