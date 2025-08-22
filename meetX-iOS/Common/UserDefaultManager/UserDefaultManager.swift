//
//  UserDefaultManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 08-06-2025.
//

import Foundation

class UserDataManager {
    
    // MARK: - Singleton
    static let shared = UserDataManager()
    private init() {}
    
    // MARK: - Essential UserDefaults Keys (App State)
    private let essentialUserDefaultsKeys = [
        DeveloperConstants.UserDefaultsInternal.isApplaunchedBefore,
        DeveloperConstants.UserDefaultsInternal.appInstalledDate,
        DeveloperConstants.UserDefaultsInternal.isLogOutDone
    ]
    
    // MARK: - User Preferences (Non-sensitive, Reset on logout)
    private let userPreferenceKeys = [
        DeveloperConstants.UserDefaultsInternal.userIDName,
        DeveloperConstants.UserDefaultsInternal.themeSelectedByUser,
        DeveloperConstants.UserDefaultsInternal.isAutoPlayVideos,
        DeveloperConstants.UserDefaultsInternal.userRecentLocationSearch,
        DeveloperConstants.UserDefaultsInternal.searchRecentSearchesKey,
        DeveloperConstants.UserDefaultsInternal.menuResponse,
        DeveloperConstants.UserDefaultsInternal.seeOthersLastSeen
    ]
    
    // MARK: - All Keychain Keys (Sensitive data)
    private let allKeychainKeys = [
        DeveloperConstants.Keychain.userTokenKeychainIdentifier,
        DeveloperConstants.Keychain.userMobileNumber,
        DeveloperConstants.Keychain.userID,
        DeveloperConstants.Keychain.userName,
        DeveloperConstants.Keychain.userDisplayName,
        DeveloperConstants.Keychain.userProfilePicture,
        DeveloperConstants.Keychain.userVerifiedProfilePending
    ]
    
    // MARK: - Clear All User Data
    func clearAllUserData(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            // Clear user preferences (keep essential app state)
            self.clearUserPreferences()
            
            // Check if keychain has any data first
            let hasKeychainData = self.checkIfKeychainHasData()
            
            var keychainCleared = true
            
            if hasKeychainData {
                // If keychain has data, clear it
                keychainCleared = self.clearAllKeychainData()
            } else {
                // No keychain data to clear (first-time install) - consider successful
                debugPrint("ℹ️ No keychain data found - skipping keychain clear")
            }
            
            DispatchQueue.main.async {
                completion(keychainCleared)
                if keychainCleared {
                    debugPrint("✅ User data cleared successfully")
                } else {
                    debugPrint("❌ Failed to clear some user data")
                }
            }
        }
    }
    
    // MARK: - Update Profile Data (Profile Completion)
    func updateProfileCompletionData(
        userName: String,
        userDisplayName: String,
        userProfilePicture: String,
        requiresProfileCompletion: Bool = false,
        userGender: String
    ) -> Bool {
        let keychainItems: [(String, String)] = [
            (DeveloperConstants.Keychain.userName, userName),
            (DeveloperConstants.Keychain.userDisplayName, userDisplayName),
            (DeveloperConstants.Keychain.userProfilePicture, userProfilePicture),
            (DeveloperConstants.Keychain.userVerifiedProfilePending, String(requiresProfileCompletion)),
            (DeveloperConstants.Keychain.userGender, userGender)
        ]
        
        var allSuccess = true
        keychainItems.forEach { key, value in
            let success = KeychainMechanism.saveToKeychain(key: key, value: value)
            if !success {
                allSuccess = false
                debugPrint("❌ Failed to update \(key) in Keychain")
            }
        }
        
        if allSuccess {
            debugPrint("🔐 Profile completion data updated in Keychain")
        }
        
        return allSuccess
    }
    
    // MARK: - Store Secure User Data (Keychain)
    func storeSecureUserData(
        token: String,
        mobileNumber: String,
        userId: String,
        userName: String,
        userDisplayName: String,
        userProfilePicture: String,
        requiresProfileCompletion: Bool = false,
        userGender: String
    ) -> Bool {
        let keychainItems: [(String, String)] = [
            (DeveloperConstants.Keychain.userTokenKeychainIdentifier, token),
            (DeveloperConstants.Keychain.userName, userName),
            (DeveloperConstants.Keychain.userDisplayName, userDisplayName),
            (DeveloperConstants.Keychain.userMobileNumber, mobileNumber),
            (DeveloperConstants.Keychain.userID, userId),
            (DeveloperConstants.Keychain.userProfilePicture, userProfilePicture),
            (DeveloperConstants.Keychain.userVerifiedProfilePending, String(requiresProfileCompletion)),
            (DeveloperConstants.Keychain.userGender, userGender)
        ]
        
        var allSuccess = true
        keychainItems.forEach { key, value in
            let success = KeychainMechanism.saveToKeychain(key: key, value: value)
            if !success {
                allSuccess = false
                debugPrint("❌ Failed to save \(key) to Keychain")
            }
        }
        
        if allSuccess {
            // Set login state
            UserDefaults.standard.set(false, forKey: DeveloperConstants.UserDefaultsInternal.isLogOutDone)
            UserDefaults.standard.synchronize()
            debugPrint("🔐 Secure user data stored in Keychain")
        }
        
        return allSuccess
    }
    
    // MARK: - Store User Preferences (UserDefaults)
    func storeUserPreferences(
        username: String? = nil,
        theme: String? = nil,
        autoPlayVideos: Bool? = false
    ) {
        let defaults = UserDefaults.standard
        
        if let username = username {
            defaults.set(username, forKey: DeveloperConstants.UserDefaultsInternal.userIDName)
        }
        
        if let theme = theme {
            defaults.set(theme, forKey: DeveloperConstants.UserDefaultsInternal.themeSelectedByUser)
        }
        
        if let autoPlay = autoPlayVideos {
            defaults.set(autoPlay, forKey: DeveloperConstants.UserDefaultsInternal.isAutoPlayVideos)
        }
        
        defaults.synchronize()
        debugPrint("💾 User preferences updated")
    }
    
    // MARK: - Retrieve Secure Data
    func getSecureUserData() -> (
        token: String?,
        mobileNumber: String?,
        userId: String?,
        userName: String?,
        displayName: String?,
        profilePicture: String?,
        requiresProfileCompletion: Bool,
        userGender: String?
    ) {
        let token = KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userTokenKeychainIdentifier)
        let mobileNumber = KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userMobileNumber)
        let userId = KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userID)
        let userName = KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userName)
        let displayName = KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userDisplayName)
        let profilePicture = KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userProfilePicture)
        let requiresProfileString = KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userVerifiedProfilePending)
        let requiresProfileCompletion = Bool(requiresProfileString ?? "false") ?? false
        let userGender = KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userGender)

        return (token, mobileNumber, userId, userName, displayName, profilePicture, requiresProfileCompletion, userGender)
    }
    
    // MARK: - User State Checks
    func isUserLoggedIn() -> Bool {
        let isLoggedOut = UserDefaults.standard.bool(forKey: DeveloperConstants.UserDefaultsInternal.isLogOutDone)
        return !isLoggedOut && validateUserData()
    }
    
    func isFirstLaunch() -> Bool {
        return !UserDefaults.standard.bool(forKey: DeveloperConstants.UserDefaultsInternal.isApplaunchedBefore)
    }
    
    func setAppLaunched() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: DeveloperConstants.UserDefaultsInternal.isApplaunchedBefore)
        
        // Set install date if not already set
        if defaults.object(forKey: DeveloperConstants.UserDefaultsInternal.appInstalledDate) == nil {
            defaults.set(Date(), forKey: DeveloperConstants.UserDefaultsInternal.appInstalledDate)
        }
        
        defaults.synchronize()
    }
    
    // MARK: - Private Helper Methods
    private func clearUserPreferences() {
        let defaults = UserDefaults.standard
        userPreferenceKeys.forEach { key in
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
        debugPrint("🗑️ User preferences cleared")
    }
    
    private func clearAllKeychainData() -> Bool {
        var allSuccess = true
        allKeychainKeys.forEach { key in
            let success = KeychainMechanism.deleteSingleItemFromKeychain(key: key)
            if !success {
                allSuccess = false
                debugPrint("❌ Failed to delete \(key) from Keychain")
            }
        }
        return allSuccess
    }
    
    // MARK: - Helper method to check if keychain has any data
    private func checkIfKeychainHasData() -> Bool {
        for key in allKeychainKeys {
            if let value = KeychainMechanism.fetchFromKeychain(key: key),
                !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
        }
        return false
    }
    
    // MARK: - Data Validation
    func validateUserData() -> Bool {
        let requiredKeychainKeys = [
            DeveloperConstants.Keychain.userTokenKeychainIdentifier,
            DeveloperConstants.Keychain.userMobileNumber,
            DeveloperConstants.Keychain.userID
        ]
        
        return requiredKeychainKeys.allSatisfy { key in
            if let value = KeychainMechanism.fetchFromKeychain(key: key) {
                return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return false
        }
    }
    
    // MARK: - Debug Helper
    func printUserDataStatus() {
        debugPrint("👤 User Data Status:")
        debugPrint("   - Logged In: \(isUserLoggedIn())")
        debugPrint("   - First Launch: \(isFirstLaunch())")
        debugPrint("   - Valid Data: \(validateUserData())")
    }
}
