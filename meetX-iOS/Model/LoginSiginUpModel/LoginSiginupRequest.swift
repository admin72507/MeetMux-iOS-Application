//
//  LoginSiginupRequest.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 22-04-2025.
//

import Foundation

struct LoginSignupRequest: Codable {
    let mobileNumber: String
    let countryCode: String
    let enableSmsOTP: Bool
}
