//
//  ProfileUpdateResponse.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 27-04-2025.
//

import Foundation

struct ProfileUpdateResponse: Codable {
    let success: Bool
    let message: String
    let user: UserUpdate?
}

struct UserUpdate: Codable {
    let userId: String
    let name: String
    let username: String
    let email: String
    let about: String?
    let isPrivate: Bool
    let profilePicUrls: [String]
    let gender: String
    let dob: String
    let profession: String?
}
