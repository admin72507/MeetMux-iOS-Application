//
//  ControlRoomObservableOptionExtension.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 25-05-2025.
//

import Foundation

extension ControlRoomObservable {
    
    /// Function handle the MenuSelection
    @MainActor func handleMenuSelection(_ item: MenuItem) {
        switch item.id {
                // About Me
            case 30:
                let viewModel = ProfileMeAndOthersObservable(
                    typeOfProfile: .personal,
                    userId: "\(KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userID) ?? "")"
                )
                routeManager.navigate(to: ProfileMeAndOthersRoute(
                    viewmodel: viewModel
                ))
                
                // My Live Activites
            case 62:
                navigateToLiveActivities()
                
                // Connection List
            case 12:
                connectionListNavigation()
                
                // Follow and Followers
            case 31:
                followAndFollowersNavigation()
                
                // Block user list
            case 13:
                blockedListNavigation()
                
                // Privacy settings
            case 6:
                PrivacySettingsnaviagtionRoute()
                
                // Theme Switcher
            case 11:
                themeSwitcher()
                
                // Version info
            case 15:
                versionInfoNavigation()
                
                // Terms and condition
            case 16:
                privacyTermsConditionHandler(
                    link: item.link,
                    title: Constants.termsConsitionText,
                    subtitle: "The rules of the road",
                    image: "scroll.fill"
                )
                
                // Privacy Policy
            case 17:
                privacyTermsConditionHandler(
                    link: item.link,
                    title: Constants.privacyPolicy,
                    subtitle: "How we protect your data",
                    image: "hand.raised.fill"
                )
                
                // Rate us
            case 18:
                rateOurAppInAppStore = true
                
                // Submit Feedback
            case 19:
                submitFeedbackHandler()
                
                // change mobile number
            case 24:
                moveToChangeMobileNumber()
                
                // Deactive Account
            case 25:
                deleteOrDeactivateHandler()
                
                // Share link
            case 26:
                copyToClipboard(DeveloperConstants.appShareDeeplink)
                shareLinkCopied = true
                
                // Refer a friend
            case 27:
                if permissionHelper.checkContactPermission() {
                    contactSelectionHandlerRoute()
                }else {
                    naviagteToContactPermission()
                }
                
                // Report a problem
            case 28:
                isNeedHelpTapped = true
                
                // Contact Support
            case 29:
                contactSupportBottomSheet = true
                
                // Log Out Action
            case 20:
                showLogOutBottomSheet = true
                
            default:
                break
        }
    }
}
