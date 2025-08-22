//
//  AutoPlaySettings.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 18-05-2025.
//

import Foundation

final class AutoPlaySettings {
    static let shared = AutoPlaySettings()
    
    private init() {}
    
    var isAutoPlayEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: DeveloperConstants.UserDefaultsInternal.isAutoPlayVideos) == nil {
                return false
            }
            return UserDefaults.standard.bool(forKey: DeveloperConstants.UserDefaultsInternal.isAutoPlayVideos)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DeveloperConstants.UserDefaultsInternal.isAutoPlayVideos)
        }
    }
}

final class ChatOthersSettings {
    
    static let shared = ChatOthersSettings()
    
    private init() {}
    
    /// Last Seen Enabled for Others - true = Show Last Seen, false = Hide Last Seen
    var isLastSeenEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: DeveloperConstants.UserDefaultsInternal.seeOthersLastSeen) == nil {
                return true // Default is enabled, change to false if needed
            }
            return UserDefaults.standard.bool(forKey: DeveloperConstants.UserDefaultsInternal.seeOthersLastSeen)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DeveloperConstants.UserDefaultsInternal.seeOthersLastSeen)
        }
    }
}
