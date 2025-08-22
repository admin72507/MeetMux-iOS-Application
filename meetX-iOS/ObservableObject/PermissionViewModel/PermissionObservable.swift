//
//  PermissionObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 30-04-2025.
//
import SwiftUI
import Combine
import FirebaseMessaging

class PermissionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var titleText: String = ""
    @Published var subTitleText: String = ""
    @Published var buttonText: String = ""
    @Published var imageName: String = ""
    @Published var detailedExplanation: String = ""
    @Published var privacyNote: String = ""
    @Published var isNeedHelpTapped = false
    @Published var shouldNavigateToHome = false
    @Published var shouldOpenSettings = false
    @Published var currentStep: DeveloperConstants.PermissionStep = .allGranted
    @Published var apiErrors: [APIError] = []

    // MARK: - Private Properties
    private var permissionStatuses: [DeveloperConstants.PermissionStep: DeveloperConstants.PermissionStatus] = [:]
    private var skippedSteps: Set<DeveloperConstants.PermissionStep> = []
    let permissionHelper = PermissionHelper()
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var isProcessing = false
    private var hasNavigatedToHome = false

    // MARK: - Dependencies
    let routeManager = RouteManager.shared

    // MARK: - Constants
    private let orderedSteps: [DeveloperConstants.PermissionStep] = [
        .locationService,
        .notificationService,
        .analytics
    ]

    init() {
        UIApplication.shared.registerForRemoteNotifications()
        loadInitialPermissions()
    }

    // MARK: - Public Methods
    func onAppear() {
        hasNavigatedToHome = false

        if permissionStatuses.isEmpty {
            loadInitialPermissions()
        } else {
            updateUI()
        }
    }

    func handlePermission() {
        guard !isProcessing else { return }
        requestPermissionForCurrentStep()
    }

    func skipCurrentStep() {
        skippedSteps.insert(currentStep)
        moveToNextStepOrComplete()
    }

    func skipAllPermissions() {
        navigateToHomeIfNeeded()
    }

    func handleAppReturnFromSettings() {
        loadPermissionsAndAdvance()
    }

    // MARK: - Private Core Logic
    private func loadInitialPermissions() {
        Task {
            let permissions = await permissionHelper.checkPermissionsHandler()

            await MainActor.run {
                self.permissionStatuses = permissions
                self.determineCurrentStep()
                self.updateUI()
            }
        }
    }

    private func loadPermissionsAndAdvance() {
        Task {
            let permissions = await permissionHelper.checkPermissionsHandler()

            await MainActor.run {
                self.permissionStatuses = permissions
                self.moveToNextStepOrComplete()
            }
        }
    }

    private func determineCurrentStep() {
        currentStep = getNextRequiredStep() ?? .allGranted
    }

    private func getNextRequiredStep() -> DeveloperConstants.PermissionStep? {
        return orderedSteps.first { step in
            // Only show steps that are not determined yet and not skipped
            let status = permissionStatuses[step]
            return status == .notDetermined && !skippedSteps.contains(step)
        }
    }

    private func moveToNextStepOrComplete() {
        if let nextStep = getNextRequiredStep() {
            currentStep = nextStep
            updateUI()
        } else {
            currentStep = .allGranted
            navigateToHomeIfNeeded()
        }
    }

    // MARK: - Navigation Helper
    private func navigateToHomeIfNeeded() {
        guard !hasNavigatedToHome else {
            debugPrint("Navigation to home already triggered, skipping")
            return
        }

        debugPrint("Triggering navigation to home screen")
        shouldNavigateToHome = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.hasNavigatedToHome = true
        }
    }

    // MARK: - Permission Request Logic
    private func requestPermissionForCurrentStep() {
        isProcessing = true

        switch currentStep {
            case .locationService:
                requestLocationPermission()
            case .notificationService:
                requestNotificationPermission()
            case .analytics:
                requestTrackingPermission()
            case .allGranted:
                navigateToHomeIfNeeded()
        }
    }

    private func requestLocationPermission() {
        locationManager.requestLocationPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.handlePermissionResult(for: .locationService, granted: granted)
            }
        }
    }

    private func requestNotificationPermission() {
        permissionHelper.requestNotificationPermission { [weak self] granted in
            if granted {
                self?.handleFCMToken()
            }
            DispatchQueue.main.async {
                self?.handlePermissionResult(for: .notificationService, granted: granted)
            }
        }
    }

    private func requestTrackingPermission() {
        permissionHelper.requestTrackingPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.handlePermissionResult(for: .analytics, granted: granted)
            }
        }
    }

    private func handlePermissionResult(for step: DeveloperConstants.PermissionStep, granted: Bool) {
        isProcessing = false

        // Update the permission status
        permissionStatuses[step] = granted ? .granted : .denied

        debugPrint("Permission \(granted ? "granted" : "denied") for \(step), moving to next step")

        // Always move to next step regardless of whether permission was granted or denied
        moveToNextStepOrComplete()
    }

    // MARK: - FCM Token Handling
    private func handleFCMToken() {
        Messaging.messaging().token { [weak self] token, error in
            guard let token = token else {
                if let error = error {
                    debugPrint("FCM Token Error: \(error.localizedDescription)")
                }
                return
            }

            self?.sendFCMTokenToServer(token)
        }
    }

    private func sendFCMTokenToServer(_ token: String) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            debugPrint("API Service not available")
            return
        }

        let urlString = URLBuilderConstants.URLBuilder(type: .sendUserFCMToken)
        let requestParams = SendFCMModel(fcmToken: token)

        let publisher: AnyPublisher<SendFCMResponse, APIError> = apiService.genericPostPublisher(
            toURLString: urlString,
            requestBody: requestParams,
            isAuthNeeded: true
        )

        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        debugPrint("FCM API failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { response in
                    let success = response.success ?? false
                    debugPrint("FCM Token \(success ? "sent successfully" : "failed to send")")
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - UI Update Logic - UPDATED
    private func updateUI() {
        let config = getUIConfiguration()

        titleText = config.title
        subTitleText = config.subtitle
        buttonText = config.buttonText
        imageName = config.imageName
        detailedExplanation = config.detailedExplanation
        privacyNote = config.privacyNote
    }

    private func getUIConfiguration() -> UIConfiguration {
        // Only show UI for notDetermined permissions
        // If we reach here, the permission should be notDetermined
        switch currentStep {
            case .locationService:
                return UIConfiguration(
                    title: "Enable Location Access",
                    subtitle: "",
                    buttonText: "Next",
                    imageName: DeveloperConstants.systemImage.locationMainPermissionImage,
                    detailedExplanation: "Location access allows you to:\n• Find events and meetups near you\n• Connect with people in your area\n• Get location-based recommendations\n• Tag your posts with locations",
                    privacyNote: "Your location data is kept private and secure"
                )
            case .notificationService:
                return UIConfiguration(
                    title: "Stay Updated with Notifications",
                    subtitle: "",
                    buttonText: "Next",
                    imageName: DeveloperConstants.systemImage.bellIcon,
                    detailedExplanation: "Notifications help you:\n• Stay informed about new messages\n• Get alerts for friend requests\n• Receive updates about events you're interested in\n• Never miss important app updates",
                    privacyNote: "You can customize notification types in Settings"
                )
            case .analytics:
                return UIConfiguration(
                    title: "Help Us Improve Your Experience",
                    subtitle: "",
                    buttonText: "Next",
                    imageName: DeveloperConstants.systemImage.trackingIcon,
                    detailedExplanation: "Analytics data helps us:\n• Improve app performance and reliability\n• Understand which features you use most\n• Fix bugs and crashes faster\n• Develop features you'll love",
                    privacyNote: "All data is anonymized and cannot be traced back to you"
                )
            case .allGranted:
                // This case shouldn't show UI, but providing default values
                return UIConfiguration(
                    title: "",
                    subtitle: "",
                    buttonText: "",
                    imageName: "",
                    detailedExplanation: "",
                    privacyNote: ""
                )
        }
    }
}

// MARK: - Supporting Types
extension PermissionViewModel {
    private struct UIConfiguration {
        let title: String
        let subtitle: String
        let buttonText: String
        let imageName: String
        let detailedExplanation: String
        let privacyNote: String
    }
}
