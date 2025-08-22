//
//  MenuModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 05-04-2025.
//
import Foundation

// MARK: - Data Models
struct ControlRoomModel: Codable {
    let menus: [MenuSection]
    var userConfigurations: [UserConfiguration]
    let message: String
}

struct MenuSection: Codable {
    let sectionId: String
    let sectionTitle: String
    let sectionOrder: Int
    let items: [MenuItem]
    
    enum CodingKeys: String, CodingKey {
        case sectionId = "section_id"
        case sectionTitle = "section_title"
        case sectionOrder = "section_order"
        case items
    }

}

struct MenuItem: Codable {
    let iosIcon: String
    let id: Int
    let itemId: String
    let itemName: String
    let route: String
    let link: String
    let displayOrder: Int
    let hasSubOptions: Bool
    let subOptions: [SubOption]
    
    enum CodingKeys: String, CodingKey {
        case iosIcon = "ios_icon"
        case id
        case itemId = "item_id"
        case itemName = "item_name"
        case route, link
        case displayOrder = "display_order"
        case hasSubOptions = "has_sub_options"
        case subOptions = "sub_options"
    }
}

struct SubOption: Codable {
    let subId: String?
    let optionName: String?
    let subOptions: [SubOption]
    let defaultValue: DefaultValue?
    let route: String?
    
    enum CodingKeys: String, CodingKey {
        case subId = "sub_id"
        case optionName = "option_name"
        case subOptions = "sub_options"
        case defaultValue = "default_value"
        case route
    }
}

// Handle mixed types for default_value (String, Bool, etc.)
enum DefaultValue: Codable {
    case string(String)
    case bool(Bool)
    case int(Int)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else {
            throw DecodingError.typeMismatch(DefaultValue.self,
                                             DecodingError.Context(codingPath: decoder.codingPath,
                                                                   debugDescription: "Cannot decode DefaultValue"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
            case .string(let value):
                try container.encode(value)
            case .bool(let value):
                try container.encode(value)
            case .int(let value):
                try container.encode(value)
        }
    }
}

struct UserConfiguration: Codable {
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

// Handle mixed types for configuration values
enum ConfigValue: Codable {
    case string(String)
    case bool(Bool)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else {
            throw DecodingError.typeMismatch(ConfigValue.self,
                                             DecodingError.Context(codingPath: decoder.codingPath,
                                                                   debugDescription: "Cannot decode ConfigValue"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
            case .string(let value):
                try container.encode(value)
            case .bool(let value):
                try container.encode(value)
        }
    }
    
    /// Convenient computed property to safely extract Bool
    var boolValue: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }
    
    ///Convinence for string value
    var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }
}


struct UserProfile: Codable {
    let userId: String
    let mobileNumber: String
    let countryCode: String
    let name: String
    let username: String
    let about: String
    let fcmToken: String?
    let email: String
    let userActivities: [Int]
    let verificationPhotoProcessed: Bool
    let gender: String
    let dob: String
    let qrCode: String
    let deepLink: String
    let isVerified: Bool
    let lastLogin: String
    let isProfileCompleted: Bool
    let isPrivate: Bool
    let isDeactivated: Bool
    let latitude: Double
    let longitude: Double
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let followers: Int
    let following: Int
    let isConnected: Bool?
    let isFollowing: Bool?
    let skills: [String]
    let interests: [Interest]
    let postCount: Int
    let profilePicUrls: [String]
    
    enum CodingKeys: String, CodingKey {
        case userId, mobileNumber, countryCode, name, username, about, fcmToken, email
        case userActivities = "user_activities"
        case verificationPhotoProcessed, gender, dob, qrCode, deepLink, isVerified, lastLogin
        case isProfileCompleted, isPrivate, isDeactivated, latitude, longitude
        case createdAt, updatedAt, deletedAt, followers, following, skills, interests
        case postCount, profilePicUrls
        case isConnected,isFollowing
    }
}

struct Interest: Codable {
    let mainCategoryId: Int
    let mainCategoryName: String
    let id: Int
    let title: String
    let platformIos: String
}

// MARK: - Decoding Function
func decodeMenuResponse(from jsonString: String) -> ControlRoomModel? {
    guard let data = jsonString.data(using: .utf8) else {
        print("❌ Failed to convert string to Data")
        return nil
    }
    
    do {
        let decoder = JSONDecoder()
        // Uncomment if your dates are in ISO8601 format
        // decoder.dateDecodingStrategy = .iso8601
        
        let menuResponse = try decoder.decode(ControlRoomModel.self, from: data)
        print("✅ Successfully decoded JSON")
        return menuResponse
        
    } catch let DecodingError.keyNotFound(key, context) {
        print("❌ Key '\(key)' not found:", context.debugDescription)
        print("Coding path:", context.codingPath)
        
    } catch let DecodingError.valueNotFound(value, context) {
        print("❌ Value '\(value)' not found:", context.debugDescription)
        print("Coding path:", context.codingPath)
        
    } catch let DecodingError.typeMismatch(type, context) {
        print("❌ Type '\(type)' mismatch:", context.debugDescription)
        print("Coding path:", context.codingPath)
        
    } catch let DecodingError.dataCorrupted(context) {
        print("❌ Data corrupted:", context.debugDescription)
        
    } catch {
        print("❌ Other decoding error: \(error)")
    }
    
    return nil
}
