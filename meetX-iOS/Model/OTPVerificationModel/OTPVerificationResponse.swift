//
//  OTPVerificationResponse.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 22-04-2025.
//

import Foundation

struct OTPVerificationResponse: Codable {
    let success: Bool?
    let message: String?
    let user: User?
    let requiresProfileCompletion: Bool?
    let token: String?
    let timestamp: String?
}

struct User: Codable {
    let userId: String?
    let mobileNumber: String?
    let isNewUser: Bool?
    let isVerified: Bool?
    let deepLink: String?
    let qrCode: String?
    let username: String?
    let name: String?
    let email: String?
    let gender: String?
    let dob: String?
    let profilePicUrls: [String]?
    
    private enum CodingKeys: String, CodingKey {
        case userId, mobileNumber, isNewUser, isVerified, deepLink, qrCode,
             username, name, email, gender, dob, profilePicUrls
    }
}
