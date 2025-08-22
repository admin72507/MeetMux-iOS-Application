//
//  SendFCMModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 08-06-2025.
//

struct SendFCMModel: Codable {
    let fcmToken: String
}

struct SendFCMResponse: Codable {
    let success: Bool?
    let message: String?
    let updatedToken: String?
}
