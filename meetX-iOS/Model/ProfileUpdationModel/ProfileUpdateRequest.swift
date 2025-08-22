//
//  ProfileUpdateRequest.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 27-04-2025.
//

struct ProfileUpdateRequest: Codable {
    let profilePicUrls: [String]
    let fullName: String
    let about: String
    let email: String
    let gender: String
    let dob: String
    let verificationPhotoString: String
    let subActivitiesIds: [Int]
}


struct ConnectionRequest: Codable {
    let targetUserId: String
}


struct EditProfileUpdateRequest: Codable {
    let fullName: String?
    let email: String?
    let profilePicUrls: [String]?
    let about: String?
    let subActivitiesIds: [Int]?
}
