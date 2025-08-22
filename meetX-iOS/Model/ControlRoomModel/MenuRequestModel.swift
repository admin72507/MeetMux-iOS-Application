//
//  MenuRequestModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 02-07-2025.
//

struct MenuRequestModel: Codable {
    let itemId: String
    let subId: String
    let value: String
    
    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case subId = "sub_id"
        case value
    }
}


struct MenuUpdateResponse: Codable {
    let message: String
    let data: [[MenuConfiguration]]
}

struct MenuConfiguration: Codable {
    let value: ConfigValue
    let subId: String
    let itemId: String
    let parentSubId: String
    
    enum CodingKeys: String, CodingKey {
        case value
        case subId = "sub_id"
        case itemId = "item_id"
        case parentSubId = "parent_sub_id"
    }
}
