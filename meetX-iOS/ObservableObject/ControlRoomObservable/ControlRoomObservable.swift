//
//  MenuObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 05-04-2025.
//

import SwiftUI
import Combine
import Kingfisher
import CoreLocation
import UserNotifications
import AppTrackingTransparency

class ControlRoomObservable : ObservableObject {
    
    @Published var showLogOutBottomSheet: Bool              = false
    @Published var contactSupportBottomSheet: Bool          = false
    @Published var menuLoadErrorToast   : Bool              = false
    @Published var shareAppSheetShown   : Bool              = false
    @Published var isInviteLinkCopied   : Bool              = false
    @Published var shouldInitiateCall   : Bool              = false
    @Published var isNeedHelpTapped     : Bool              = false
    @Published var shareLinkCopied      : Bool              = false
    @Published var rateOurAppInAppStore : Bool              = false
    @Published var collectedNewMobileNumber : String        = "" //Change mobilenumber
    @Published var isNeedSupportOverlayShown: Bool = false
    @Published var referAFriendActionTriggerToSettings: Bool = false
    @Published var doubleOTPMobileNumberValidator: Bool      = false
    @Published var moveUserToContactList: Bool = false
    @Published var followFollowersRoute: Bool = false
    @Published var controlCenterObject: ControlRoomModel?
    @Published var errorMessage: String? = nil
    @Published var showToast: Bool = false
    
    let userDataManager: UserDataManager

    // MARK: - Permission State Properties
    @Published var locationPermissionGranted: Bool = false
    @Published var notificationPermissionGranted: Bool = false
    @Published var trackingPermissionGranted: Bool = false

    // MARK: - Alert Properties
    @Published var showPermissionAlert: Bool = false
    @Published var permissionAlertTitle: String = ""
    @Published var permissionAlertMessage: String = ""

    // MARK: - Permission Status Tracking
    private var permissionStatuses: [DeveloperConstants.PermissionStep: DeveloperConstants.PermissionStatus] = [:]

    // Privacy settings
    @Published var isProfilePublic = true {  // true = Public, false = Private
        didSet { checkForChanges() }
    }
    
    @Published var isConnectionVisibleToEveryone = true { // true = Everyone, false = My Connections
        didSet { checkForChanges() }
    }
    @Published var isProfilePictureVisibleToEveryone = true { // true = Everyone, false = My Connections
        didSet { checkForChanges() }
    }
    @Published var isAutoPlayEnabled = false {
        didSet { checkForChanges() }
    }
    @Published var isChatLastSeenEnabled = true { // true = Everyone, false = My Connections
        didSet { checkForChanges() }
    }
    
    @Published var hasChanges: Bool = false
    
    // Store initial values here once loaded from API
    private var initialIsProfilePublic: Bool = true
    private var initialIsConnectionVisibleToEveryone: Bool = true
    private var initialIsProfilePictureVisibleToEveryone: Bool = true
    private var initialIsAutoPlayEnabled: Bool = false
    private var initialIsChatLastSeenEnabled: Bool = true
    
    let permissionHelper = PermissionHelper()
    let routeManager = RouteManager.shared
    let id = UUID()
    private var cancellables = Set<AnyCancellable>()
    
    init(userDataManager: UserDataManager = UserDataManager.shared) {
        self.userDataManager = userDataManager
    }
    
    // MARK: - Privacy settings value handler
    func privacySettingsValueHandler() {
        // MARK: - Public or Private
        isProfilePublic = stringValue(for: "101", subID: "201") == "Public"
        
        // MARK: - See my connections: Everyone / Your Connections
        isConnectionVisibleToEveryone = stringValue(for: "101", subID: "202") == "Everyone"
        
        // MARK: - Profile Picture Visibility
        if let visibility = stringValue(for: "101", subID: "204") {
            isProfilePictureVisibleToEveryone = (visibility == "Everyone")
        } else {
            isProfilePictureVisibleToEveryone = true
        }
        
        // MARK: - Autoplay
        isAutoPlayEnabled = AutoPlaySettings.shared.isAutoPlayEnabled
        
        // MARK: - Chat Preferences - Last seen enabled
//        if let lastSeen = stringValue(for: "101", subID: "205") {
//            isChatLastSeenEnabled = (lastSeen.lowercased() == "true")
//        } else {
//            isChatLastSeenEnabled = true // default
//        }
        isChatLastSeenEnabled = ChatOthersSettings.shared.isLastSeenEnabled
        
        
        // Save initial values to compare later
        initialIsProfilePublic = isProfilePublic
        initialIsConnectionVisibleToEveryone = isConnectionVisibleToEveryone
        initialIsProfilePictureVisibleToEveryone = isProfilePictureVisibleToEveryone
        initialIsAutoPlayEnabled = isAutoPlayEnabled
        initialIsChatLastSeenEnabled = isChatLastSeenEnabled
        
        hasChanges = false
    }
    
    // MARK: - Autoplay toggle
    func autoPlayToggled(_ newValue: Bool) {
        AutoPlaySettings.shared.isAutoPlayEnabled = newValue
    }
    
    // MARK: - Chat last seen
    func chatOthersLastseenToggled(_ newValue: Bool) {
        ChatOthersSettings.shared.isLastSeenEnabled = newValue
    }
    
    // MARK: - Handle profile public or private
    func profileVisibilityToggled(_ newValue: Bool) {
        guard let index = controlCenterObject?.userConfigurations.firstIndex(where: { $0.subId == "201" }) else {
            print("UserConfiguration with subId 201 not found")
            return
        }
        
        let menuUpdateRequest: [MenuRequestModel] = [ MenuRequestModel(
            itemId: controlCenterObject?.userConfigurations[index].itemId ?? "101",
            subId: controlCenterObject?.userConfigurations[index].subId ?? "201",
            value: newValue ? "Public" : "Private"
        )]
        
        makeMenuUpdateAPICall(menuUpdateRequest: menuUpdateRequest, newValue: newValue)
    }

    
    func checkForChanges() {
        hasChanges =
        isProfilePublic != initialIsProfilePublic ||
        isConnectionVisibleToEveryone != initialIsConnectionVisibleToEveryone ||
        isProfilePictureVisibleToEveryone != initialIsProfilePictureVisibleToEveryone ||
        isAutoPlayEnabled != initialIsAutoPlayEnabled ||
        isChatLastSeenEnabled != initialIsChatLastSeenEnabled
    }
    
    // MARK: - Helper
    private func stringValue(for itemID: String, subID: String) -> String? {
        controlCenterObject?.userConfigurations.first {
            $0.itemId == itemID && $0.subId == subID
        }.flatMap {
            if case .string(let str) = $0.value { return str } else { return nil }
        }
    }
    
    func loadControlCenterIfNeeded(completion: @escaping () -> Void) {
        if let cached = getCachedControlRoom() {
            self.controlCenterObject = cached
            completion()
        } else {
            fetchControlCenterFromAPI(completion: completion)
        }
    }
    
    private func fetchControlCenterFromAPI(completion: @escaping () -> Void) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            menuLoadErrorToast = true
            completion()
            return
        }
        
        let publisher: AnyPublisher<ControlRoomModel, APIError> = apiService.genericPublisher(
            fromURLString: URLBuilderConstants.URLBuilder(type: .controlCenterConfiguration)
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                switch result {
                    case .finished:
                        break
                    case .failure:
                        self?.menuLoadErrorToast = true
                }
                completion()
            }, receiveValue: { [weak self] model in
                self?.controlCenterObject = model
                self?.saveToCache(model)
            })
            .store(in: &cancellables)
    }
    
    private func saveToCache(_ model: ControlRoomModel) {
        if let data = try? JSONEncoder().encode(model) {
            UserDefaults.standard.set(data, forKey: DeveloperConstants.UserDefaultsInternal.menuResponse)
        }
    }
    
    private func getCachedControlRoom() -> ControlRoomModel? {
        guard let data = UserDefaults.standard.data(forKey: DeveloperConstants.UserDefaultsInternal.menuResponse),
              let model = try? JSONDecoder().decode(ControlRoomModel.self, from: data) else {
            return nil
        }
        return model
    }
    
    // MARK: - Navigate to contact screen
    func naviagteToContactPermission() {
        routeManager.navigate(to: contactPermissionScreenRoute())
    }
    
    // MARK: - Navigate to contacts selection
    func contactSelectionHandlerRoute() {
        routeManager.navigate(to: referAFriendContactSelectionRoute())
    }
    
    //MARK: - Handle logout action
    func logOutHandler() {
        //Remove network
        URLCache.shared.removeAllCachedResponses()
        
        //Kingfisher cache clearing
        ImageCache.default.clearMemoryCache()
        
        // Clear disk cache
        ImageCache.default.clearDiskCache {
            debugPrint("Disk cache cleared")
        }
        
        // Clear app cache
        let tempDirectory = FileManager.default.temporaryDirectory
        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
            for file in tempFiles {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            debugPrint("Error clearing app cache: \(error)")
        }
        
        // USER LOOGED IN HOME SCREEN
        UserDefaults.standard.set(false, forKey: "UserLoggedInNoOldLoginScreen")

        // Set logout flag
        UserDefaults.standard.set(true, forKey: DeveloperConstants.UserDefaultsInternal.isLogOutDone)
        UserDefaults.standard.synchronize()
        
        routeManager.navigate(to: oldLoginRoute())
    }
    
    //MARK: - Submit Feedback
    func submitFeedbackHandler() {
        routeManager.navigate(to: SubmitFeedbackViewRoute())
    }
    
    //MARK: - Copy Invite Link
    func copyInviteLinkHandler() {
        UIPasteboard.general.string = DeveloperConstants.appShareDeeplink
    }
    
    //MARK: - Terms and condition
    func privacyTermsConditionHandler(link : String,
                                      title: String,
                                      subtitle : String,
                                      image : String) {
        routeManager.navigate(to: PrivacyTermsConditontionRoute(link: link,
                                                                title: title,
                                                                image: image,
                                                                subtitle: subtitle))
    }
    
    //MARK: - Report a problem
    func reportAProblem(title: String,
                        subtitle : String,
                        image : String) {
        routeManager.navigate(to: reportAProblemRoute(title: title, image: image, subtitle: subtitle))
    }
    
    // MARK: - Delete or Deactivate
    func deleteOrDeactivateHandler() {
        routeManager.navigate(to: DeleteOrDeactivateRoute(title: "Delete / Deactivate Account",
                                                          image: "nosign.app.fill",
                                                          subtitle: "Need a break? We’ll miss you!"))
    }
    
    //MARK: - Move to OTP
    func moveToChangeMobileNumber() {
        routeManager.navigate(to: ChangeMobileNumberRoute(viewModel: (self)))
    }
    
    // MARK: - MobileNumber cleaner
    func cleanMobileNumberWithCountryCode(_ number: String) -> String {
        var cleaned = number.replacingOccurrences(of: " ", with: "")
        
        if cleaned.hasPrefix("+91") {
            cleaned = String(cleaned.dropFirst(3))
        } else if cleaned.hasPrefix("91") {
            cleaned = String(cleaned.dropFirst(2))
        }
        
        return cleaned
    }
    
    // MARK: - Copy to clipboard
    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
    
    // MARK: - Theme Switcher
    func themeSwitcher() {
        routeManager.navigate(to: themeSwitcherRoute())
    }
    
    // MARK: - Version Info
    func versionInfoNavigation() {
        routeManager.navigate(to: versionInfoRoute())
    }
    
    // MARK: - Profile Settings
    func PrivacySettingsnaviagtionRoute() {
        routeManager.navigate(to: PrivacySettingsNavRoute(viewModel: self))
    }
    
    // MARK: - Navigate To Follow and Followers
    func followAndFollowersNavigation() {
        routeManager.navigate(to: FollowAndFollowersRoute())
    }
    
    // MARK: - Navigate to conection list
    func connectionListNavigation() {
        routeManager.navigate(to:
                                ConnectionListRoute(
                                    viewModel: TagPeopleViewModel(selectedConnections: [])
                                )
        )
    }
    
    // MARK: - Navigate to blocked list
    func blockedListNavigation() {
        routeManager.navigate(to: BlockedListRoute())
    }
    
    // MARK: - Navigate to live activities
    func navigateToLiveActivities() {
        routeManager.navigate(to: MyLiveActivitiesRoute())
    }
}

//MARK: - Menu update API Call
extension ControlRoomObservable {
    
    private func makeMenuUpdateAPICall(menuUpdateRequest: [MenuRequestModel], newValue: Bool) {
        
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            self.errorMessage = "Failed to map"
            return
        }
        
        Loader.shared.startLoading()
        
        let urlString = URLBuilderConstants.URLBuilder(type: .controlCenterConfiguration)
        
        let publisher: AnyPublisher<MenuUpdateResponse, APIError> = apiService.genericPostPublisher(
            toURLString: urlString,
            requestBody: menuUpdateRequest,
            isAuthNeeded: true,
            httpMethod: .patch
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    Loader.shared.stopLoading()
                    
                    if case .failure(let error) = completion {
                        self.errorMessage = error.localizedDescription
                        self.isProfilePublic.toggle()
                        self.showToast.toggle()
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    Loader.shared.stopLoading()
                    
                    // Update controlCenterObject from API response
                    guard let updatedConfigs = response.data.first else { return }
                    
                    for config in updatedConfigs {
                        if let index = self.controlCenterObject?.userConfigurations.firstIndex(where: { $0.subId == config.subId }) {
                            self.controlCenterObject?.userConfigurations[index] = UserConfiguration(
                                value: config.value,
                                subId: config.subId,
                                itemId: config.itemId,
                                parentSubId: config.parentSubId
                            )
                        }
                    }
                    
                    // Save updated controlCenterObject to UserDefaults
                    if let updatedControlRoom = self.controlCenterObject,
                       let encoded = try? JSONEncoder().encode(updatedControlRoom) {
                        UserDefaults.standard.set(encoded, forKey: DeveloperConstants.UserDefaultsInternal.menuResponse)
                    }
                    
                    self.errorMessage = response.message
                    self.showToast.toggle()
                }
            )
            .store(in: &cancellables)
    }

}
// MARK: - Permission Extension for ControlRoomObservable
extension ControlRoomObservable {
    // MARK: - Location Status Helper
    func getLocationAuthStatus() -> Bool {
        let locationAuthorizationStatus = CLLocationManager().authorizationStatus
        switch locationAuthorizationStatus {
            case .notDetermined:
                return false
            case .denied, .restricted:
                return false
            case .authorizedAlways, .authorizedWhenInUse:
                return true
            default:
                return false
        }
    }

    // MARK: - Initialize Permission States
    func initializePermissionStates() {
        let permissions = permissionHelper.checkPermissionsHandlerSync()

        // Update UI state based on current permissions
        locationPermissionGranted = getLocationAuthStatus()
        notificationPermissionGranted = !permissions.keys.contains(.notificationService)
        trackingPermissionGranted = !permissions.keys.contains(.analytics)

        // Store current statuses
        permissionStatuses = permissions
    }

    // MARK: - Permission Toggle Handlers
    func locationPermissionToggled(_ isEnabled: Bool) {
        if isEnabled {
            // Check current status using your helper function
            if getLocationAuthStatus() {
                locationPermissionGranted = true
            } else {
                let currentStatus = CLLocationManager().authorizationStatus
                if currentStatus == .denied || currentStatus == .restricted {
                    showPermissionDeniedAlert(for: "Location")
                } else {
                    // .notDetermined - request permission
                    requestLocationPermission()
                }
            }
        } else {
            // User turned off - show alert to go to settings
            showSettingsAlert(for: "Location", message: "To disable Location access, please go to Settings > Privacy & Security > Location Services > meetX and select 'Never'.")
        }
    }

    func notificationPermissionToggled(_ isEnabled: Bool) {
        if isEnabled {
            // Check current status first
            UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
                DispatchQueue.main.async {
                    switch settings.authorizationStatus {
                        case .authorized, .provisional, .ephemeral:
                            self?.notificationPermissionGranted = true
                        case .denied:
                            self?.showPermissionDeniedAlert(for: "Notifications")
                        case .notDetermined:
                            self?.requestNotificationPermission()
                        @unknown default:
                            self?.showPermissionDeniedAlert(for: "Notifications")
                    }
                }
            }
        } else {
            // User turned off - show alert to go to settings
            showSettingsAlert(for: "Notifications", message: "To disable Push Notifications, please go to Settings > Notifications > meetX and turn off 'Allow Notifications'.")
        }
    }

    func trackingPermissionToggled(_ isEnabled: Bool) {
        if isEnabled {
            if #available(iOS 14, *) {
                let currentStatus = ATTrackingManager.trackingAuthorizationStatus
                switch currentStatus {
                    case .authorized:
                        trackingPermissionGranted = true
                    case .denied, .restricted:
                        showPermissionDeniedAlert(for: "Tracking")
                    case .notDetermined:
                        requestTrackingPermission()
                    @unknown default:
                        showPermissionDeniedAlert(for: "Tracking")
                }
            } else {
                trackingPermissionGranted = false
            }
        } else {
            // User turned off - show alert to go to settings
            showSettingsAlert(for: "Analytics & Tracking", message: "To disable Analytics & Tracking, please go to Settings > Privacy & Security > Tracking > meetX and turn off 'Allow meetX to Track'.")
        }
    }

    // MARK: - Permission Request Methods
    private func requestLocationPermission() {
        let locationManager = CLLocationManager()
        let currentStatus = locationManager.authorizationStatus

        switch currentStatus {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()

                // Poll for status change with timeout
                pollLocationPermissionStatus()

            case .denied, .restricted:
                showPermissionDeniedAlert(for: "Location")

            case .authorizedWhenInUse, .authorizedAlways:
                locationPermissionGranted = true

            @unknown default:
                showPermissionDeniedAlert(for: "Location")
        }
    }

    private func pollLocationPermissionStatus() {
        var pollCount = 0
        let maxPolls = 20 // Max 10 seconds (20 * 0.5s)

        func checkStatus() {
            let isGranted = getLocationAuthStatus()
            let currentStatus = CLLocationManager().authorizationStatus

            // If status is determined (not .notDetermined), stop polling
            if currentStatus != .notDetermined {
                DispatchQueue.main.async {
                    self.locationPermissionGranted = isGranted
                    if !isGranted {
                        self.showPermissionDeniedAlert(for: "Location")
                    }
                }
                return
            }

            // Continue polling if still not determined and haven't exceeded max polls
            pollCount += 1
            if pollCount < maxPolls {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    checkStatus()
                }
            } else {
                // Timeout - assume denied
                DispatchQueue.main.async {
                    self.locationPermissionGranted = false
                    self.showPermissionDeniedAlert(for: "Location")
                }
            }
        }

        // Start polling after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            checkStatus()
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.notificationPermissionGranted = granted
                if !granted && error == nil {
                    // Only show alert if user explicitly denied (no error)
                    self?.showPermissionDeniedAlert(for: "Notifications")
                }
            }
        }
    }

    private func requestTrackingPermission() {
        if #available(iOS 14, *) {
            switch ATTrackingManager.trackingAuthorizationStatus {
                case .notDetermined:
                    ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                        DispatchQueue.main.async {
                            let granted = (status == .authorized)
                            self?.trackingPermissionGranted = granted
                            if !granted && status == .denied {
                                // Only show alert if explicitly denied
                                self?.showPermissionDeniedAlert(for: "Tracking")
                            }
                        }
                    }

                case .denied:
                    showPermissionDeniedAlert(for: "Tracking")

                case .authorized:
                    trackingPermissionGranted = true

                case .restricted:
                    trackingPermissionGranted = false

                @unknown default:
                    trackingPermissionGranted = false
            }
        } else {
            // iOS 13 and below - tracking not available
            trackingPermissionGranted = false
        }
    }

    // MARK: - Helper Methods
    private func showPermissionDeniedAlert(for permissionType: String) {
        // Reset the toggle state
        switch permissionType {
            case "Location":
                locationPermissionGranted = false
            case "Notifications":
                notificationPermissionGranted = false
            case "Tracking":
                trackingPermissionGranted = false
            default:
                break
        }

        // Show alert to direct user to settings
        let message: String
        switch permissionType {
            case "Location":
                message = "meetX needs location access to show you nearby events and connect you with people in your area. Please enable it in Settings."
            case "Notifications":
                message = "meetX needs notification access to keep you updated with messages and friend requests. Please enable it in Settings."
            case "Tracking":
                message = "meetX uses analytics to improve your experience. This helps us understand how to make the app better for you."
            default:
                message = "\(permissionType) permission is needed for the best meetX experience. Please enable it in Settings."
        }

        DispatchQueue.main.async {
            self.showSettingsAlert(for: permissionType, message: message)
        }
    }

    private func showSettingsAlert(for permissionType: String, message: String) {
        permissionAlertTitle = "\(permissionType) Permission"
        permissionAlertMessage = message
        showPermissionAlert = true
    }

    func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }

    // MARK: - Additional Helper Methods
    func refreshPermissionStates() {
        // Called when returning from Settings app
        initializePermissionStates()
    }

    func resetToggleStates() {
        // Reset toggles to their actual permission state when user cancels
        initializePermissionStates()
    }
}
