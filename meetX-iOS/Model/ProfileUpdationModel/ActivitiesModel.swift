//
//  InterestModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 13-02-2025.
//

import Foundation

struct ActivitiesModel: Codable {
    var categories: [Activities]
}

// MARK: - Main Category Model
struct Activities: Codable, Identifiable {
    let id: Int
    let name: String
    let subcategories: [SubActivitiesModel]
}

// MARK: - Subcategory Model
struct SubActivitiesModel: Codable, Identifiable {
    let mainCategoryId: Int?
    let mainCategoryName: String?
    let count: Int?
    let id: Int
    let title: String
    let icon: String?
    let iconIOS: String?
    
    enum CodingKeys: String, CodingKey {
        case mainCategoryId
        case mainCategoryName
        case count
        case id
        case title
        case icon = "platformIcon"
        case iconIOS = "platformIos"
    }
}
