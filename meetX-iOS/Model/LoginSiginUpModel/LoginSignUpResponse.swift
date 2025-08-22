//
//  LoginSignUpModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 22-04-2025.
//

import Foundation

struct LoginSignUpResponse: Codable {
    let success: Bool
    let message: String
    let phoneDetails: PhoneDetails
}

struct PhoneDetails: Codable {
    let mobileNumber: String
    let countryCode: String
}
