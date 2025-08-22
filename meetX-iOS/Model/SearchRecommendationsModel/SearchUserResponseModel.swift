//
//  SearchUserResponseModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 03-06-2025.
//

import Foundation

struct SearchUserResponseModel: Codable {
    let success: Bool?
    let count: Int?
    let data: [UserSearch]?
}

struct UserSearch: Codable, Identifiable {
    var id: String { userId ?? UUID().uuidString }
    
    let userId: String?
    let name: String?
    let username: String?
    let profilePicUrl: String?
    let profilePicUrls: String?
}
