//
//  OTPVerificationRequest.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 22-04-2025.
//

import Foundation

struct OTPVerificationRequest: Codable {
    let mobileNumber: String
    let otp: String
}
