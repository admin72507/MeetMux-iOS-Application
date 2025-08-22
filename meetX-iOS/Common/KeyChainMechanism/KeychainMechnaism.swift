//
//  KeychainMechnaism.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-12-2024.
//
import Security
import Foundation

// MARK: - KeychainMechanism class
/// Keychain mechanism to safely handle data persistence in the keychain.
final class KeychainMechanism {
    
    /// Save a single value to Keychain.
    /// - Parameters:
    ///   - key: The key used to store the value in Keychain.
    ///   - value: The value to be stored.
    /// - Returns: A `Bool` indicating whether the operation was successful.
    @discardableResult
    static func saveToKeychain(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            debugPrint(DeveloperConstants.General.conversionError)
            return false
        }
        
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data
        ]
        
        // Check if the item already exists
        var status = SecItemCopyMatching(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            // If item exists, update it
            status = SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary)
        } else if status == errSecItemNotFound {
            // If item doesn't exist, add it
            status = SecItemAdd(query as CFDictionary, nil)
        }
        
        if status == errSecSuccess {
            debugPrint("\(DeveloperConstants.General.savedSuccessfully) \(key)")
            return true
        } else {
            debugPrint("\(DeveloperConstants.General.savedUnsuccessfully) \(key), \(DeveloperConstants.General.error) \(status)")
            return false
        }
    }
    
    /// Fetch a single value from Keychain.
    /// - Parameter key: The key used to fetch the value from Keychain.
    /// - Returns: The value as a `String` if found, or `nil` if not found.
    static func fetchFromKeychain(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
            debugPrint("\(DeveloperConstants.General.errorFetchingItem) \(key), \(DeveloperConstants.General.status) \(status)")
            return nil
        }
        
        return value
    }
    
    /// Delete a single value from Keychain.
    /// - Parameter key: The key of the item to be deleted.
    /// - Returns: A `Bool` indicating whether the deletion was successful.
    static func deleteSingleItemFromKeychain(key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            debugPrint("\(DeveloperConstants.General.successfullyDeleted) \(key)")
            return true
        } else if status == errSecItemNotFound {
            debugPrint("\(DeveloperConstants.General.noItemFound) \(key)")
            return false
        } else {
            debugPrint("\(DeveloperConstants.General.deleteUnsuccessfully) \(key), \(DeveloperConstants.General.error) \(status)")
            return false
        }
    }
    
    /// Delete all Keychain items related to the app.
    /// - Returns: A `Bool` indicating whether the deletion was successful for all items.
    static func deleteAllKeychainItems() -> Bool {
        let keychainClasses: [CFString] = [kSecClassGenericPassword, kSecClassInternetPassword, kSecClassCertificate, kSecClassKey, kSecClassIdentity]
        var deletionSuccess = true
        
        for keychainClass in keychainClasses {
            let query: [CFString: Any] = [kSecClass: keychainClass]
            let status = SecItemDelete(query as CFDictionary)
            
            if status != errSecSuccess && status != errSecItemNotFound {
                debugPrint("\(DeveloperConstants.General.combinedDeleteUnSuccessfully) \(keychainClass), \(DeveloperConstants.General.error) \(status)")
                deletionSuccess = false
            } else {
                debugPrint("\(DeveloperConstants.General.combinedDeleteSuccessfully) \(keychainClass)")
            }
        }
        
        return deletionSuccess
    }
}
