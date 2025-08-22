//
//  UnFollowFollowBackResponse.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 29-05-2025.
//

struct UnFollowFollowBackResponse: Codable {
    let message: String?
    let followed: Bool
    let requestPending: Bool?
}
