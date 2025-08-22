//
//  AppStateManager.swift
//  meetX-iOS
//
//  Created on 27-06-2025.
//

import Foundation
import SwiftUI
import Combine
import os.log

// MARK: - App State Enum
enum AppScreen: CaseIterable {
    case splash                 // Fresh Install + No Token
    case oldLoginDetection     // Fresh Install + Has Token OR Has Token + Logged Out
    case profileUpdate         // Has Token + Profile Pending
    case permissions          // Has Token + Profile Complete + Not Logged Out + Permission Not Completed
    case home                 // Has Token + Profile Complete + Not Logged Out + Permission Completed
    case login                // No Token + Visited Before
    
    var description: String {
        switch self {
            case .splash:
                return "Splash Screen"
            case .oldLoginDetection:
                return "Old Login Detection"
            case .profileUpdate:
                return "Profile Update Required"
            case .permissions:
                return "Permissions Setup"
            case .home:
                return "Home Screen"
            case .login:
                return "Login Screen"
        }
    }
}

// MARK: - App State Manager (ObservableObject for SwiftUI)
class AppStateManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentScreen: AppScreen = .splash
    @Published var isLoading: Bool = false
    
    // MARK: - Singleton
    static let shared = AppStateManager()
    private init() {
        determineInitialAppState()
    }
    
    // MARK: - Dependencies
    private let userDataManager = UserDataManager.shared
    
    // MARK: - Permission Status Key
    private let permissionCompletedKey = "PermissionSetupCompleted"
    
    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Log
    private let logger = Logger(
        subsystem: DeveloperConstants.BaseURL.subSystemLogger,
        category: "AppState"
    )
    
    // MARK: - Public Methods
    
    /// Determines the initial app state on app launch
    func determineInitialAppState() {
        currentScreen = evaluateAppState()
        logCurrentState()
    }
    
    /// Refreshes the current app state
    func refreshAppState() {
        let newState = evaluateAppState()
        if newState != currentScreen {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentScreen = newState
            }
        }
        logCurrentState()
    }
    
    /// Marks the app as launched (call this after splash screen)
    func markAppAsLaunched() {
        userDataManager.setAppLaunched()
        refreshAppState()
    }
    
    /// Marks permission setup as completed
    func markPermissionSetupCompleted() {
        UserDefaults.standard.set(true, forKey: permissionCompletedKey)
        UserDefaults.standard.synchronize()
        refreshAppState()
        logger.info("✅ Permission setup marked as completed")
    }
    
    /// Resets permission setup status
    func resetPermissionSetup() {
        UserDefaults.standard.removeObject(forKey: permissionCompletedKey)
        UserDefaults.standard.synchronize()
        refreshAppState()
        logger.info("🔄 Permission setup status reset")
    }
    
    /// Handles user logout
    func handleUserLogout() {
        isLoading = true
        
        userDataManager.clearAllUserData { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                if success {
                    self.resetPermissionSetup()
                    self.refreshAppState()
                    self.logger.info("✅ User logged out successfully")
                } else {
                    self.logger.error("❌ Logout failed")
                }
            }
        }
    }
    
    /// Handles successful login
    func handleSuccessfulLogin() {
        refreshAppState()
    }
    
    /// Handles profile completion
    func handleProfileCompletion() {
        refreshAppState()
    }
    
    /// Handles successful token storage (for old login detection)
    func handleTokenRestoration() {
        refreshAppState()
    }
    
    // MARK: - Private Helper Methods
    
    private func evaluateAppState() -> AppScreen {
        let isFreshInstall = userDataManager.isFirstLaunch()
        let hasToken = hasValidToken()
        let isProfilePending = isProfileCompletionPending()
        let isLoggedOut = isUserLoggedOut()
        let isPermissionCompleted = isPermissionSetupCompleted()
        
#if PREPRODUCTION_STAGE
        logAppStateDebugInfo(
            isFreshInstall: isFreshInstall,
            hasToken: hasToken,
            isProfilePending: isProfilePending,
            isLoggedOut: isLoggedOut,
            isPermissionCompleted: isPermissionCompleted
        )
#endif
        
        // App State Logic
        if isFreshInstall {
            if hasToken {
                // Fresh Install + Has Token → Old Login Detection
                UserDefaults.standard.set(true, forKey: DeveloperConstants.UserDefaultsInternal.isLogOutDone)
                return .oldLoginDetection
            } else {
                // Fresh Install + No Token → Splash
                return .splash
            }
        } else {
            // Not a fresh install
            if hasToken {
                if isLoggedOut == true {
                    // Has Token + Logged Out → Old Login Detection
                    return .oldLoginDetection
                } else {
                    // User is logged in with token
                    if isProfilePending {
                        // Has Token + Profile Pending → Profile Update
                        return .profileUpdate
                    } else {
                        // Profile is complete
                        if isPermissionCompleted {
                            // Has Token + Profile Complete + Not Logged Out + Permission Completed → Home
                            return .home
                        } else {
                            // Has Token + Profile Complete + Not Logged Out + Permission Not Completed → Permissions
                            // by passed to home even though permission is not completed
                            //return .permissions
                            return .home
                        }
                    }
                }
            } else {
                // No Token + Visited Before → Login
                return .login
            }
        }
    }
    
    private func hasValidToken() -> Bool {
        let secureData = userDataManager.getSecureUserData()
        return secureData.token != nil && !secureData.token!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func isProfileCompletionPending() -> Bool {
        let secureData = userDataManager.getSecureUserData()
        return secureData.requiresProfileCompletion
    }
    
    private func isUserLoggedOut() -> Bool {
        return UserDefaults.standard.bool(forKey: DeveloperConstants.UserDefaultsInternal.isLogOutDone)
    }
    
    private func isPermissionSetupCompleted() -> Bool {
        return PermissionHelper().checkPermissionsHandlerSync().isEmpty
    }
    
    private func logAppStateDebugInfo(
        isFreshInstall: Bool,
        hasToken: Bool,
        isProfilePending: Bool,
        isLoggedOut: Bool,
        isPermissionCompleted: Bool
    ) {
        debugPrint("🔍 App State Debug Info:")
        debugPrint("   - Fresh Install: \(isFreshInstall)")
        debugPrint("   - Has Token: \(hasToken)")
        debugPrint("   - Profile Pending: \(isProfilePending)")
        debugPrint("   - Logged Out: \(isLoggedOut)")
        debugPrint("   - Permission Completed: \(isPermissionCompleted)")
    }
    
    private func logCurrentState() {
        logger.info("📱 Current App State: \(self.currentScreen.description)")
    }
    
    // MARK: - Computed Properties for SwiftUI
    
    /// Quick check if user needs to complete onboarding
    var needsOnboarding: Bool {
        switch currentScreen {
            case .splash, .login, .oldLoginDetection:
                return true
            case .profileUpdate, .permissions, .home:
                return false
        }
    }
    
    /// Quick check if user is authenticated
    var isAuthenticated: Bool {
        switch currentScreen {
            case .profileUpdate, .permissions, .home:
                return true
            case .splash, .login, .oldLoginDetection:
                return false
        }
    }
    
    /// Quick check if app is ready for main functionality
    var isReadyForMainApp: Bool {
        return currentScreen == .home
    }
}
