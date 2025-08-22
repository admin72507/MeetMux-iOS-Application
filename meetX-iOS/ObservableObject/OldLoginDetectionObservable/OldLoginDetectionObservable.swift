//
//  OldLoginDetectionObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 26-04-2025.
//

import Foundation
import SwiftUI

final class OldLoginDetectionViewModel: ObservableObject {
    @Published var route: OldLoginRoute? = nil
    @Published var needHelpTapped: Bool = false
    
    private let userDataManager = UserDataManager.shared
    
    let mobileNumber: String
    let userDisplayName: String
    let userProfilePicture: String
    
    init() {
        mobileNumber = userDataManager.getSecureUserData().mobileNumber ?? ""
        userDisplayName = userDataManager.getSecureUserData().displayName ?? ""
        userProfilePicture = userDataManager.getSecureUserData().profilePicture ?? ""
    }

    func continuePreviousLogin() {
        userDataManager.setAppLaunched()
        UserDefaults.standard.set(false, forKey: DeveloperConstants.UserDefaultsInternal.isLogOutDone)
        route = .continueLogin
        handleNavigation()
    }
    
    func loginOrSignup() {
        route = .loginSignup
        handleNavigation()
    }
    
    func isProfilePendingInKeychain() -> Bool {
        guard let value = KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userVerifiedProfilePending),
              let isPending = Bool(value) else {
            return false
        }
        return isPending
    }
    
    func handleNavigation() {
        switch route {
            case .continueLogin:
                LocationStorage.isUsingCurrentLocation = true
                if isProfilePendingInKeychain() {
                    RouteManager.shared.navigate(to: ProfileUpdationScene())
                    
                } else {
                    let permissionsStatus = PermissionHelper().checkPermissionsHandlerSync()
                    
                    if permissionsStatus.isEmpty {
                        RouteManager.shared.navigate(to: HomePageRoute())
                    } else {
                        RouteManager.shared.navigate(to: PermissionStepScene())
                    }
                }
            case .loginSignup, .none:
                RouteManager.shared.navigate(to: IntroSceneRoute())
        }
    }
    
    func cleanMobileNumberWithCountryCode(_ number: String) -> String {
        var cleaned = number.replacingOccurrences(of: " ", with: "")
        
        if cleaned.hasPrefix("+91") {
            cleaned = String(cleaned.dropFirst(3))
        } else if cleaned.hasPrefix("91") {
            cleaned = String(cleaned.dropFirst(2))
        }
        
        return cleaned
    }
}

enum OldLoginRoute: Hashable {
    case continueLogin
    case loginSignup
}
