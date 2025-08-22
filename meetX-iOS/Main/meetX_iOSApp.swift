//
//  meetX_iOSApp.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 03/10/1946 Saka.
//

import SwiftUI
import GoogleMaps
import FirebaseCore
import FirebaseMessaging
import os.log

@main
struct meetX_iOSApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState: AppStateManager
    @StateObject private var appCoordinator: AppCoordinator
    @StateObject private var networkState: NetworkViewModel
    @StateObject private var routeManager = RouteManager.shared
    @State private var isSplashScreenShown: Bool = true
    @StateObject private var themeManager: AppThemeManager

    let persistenceController = PersistenceController.shared

    init() {
        let sharedAppState = AppStateManager.shared
        let sharedNetworkState = NetworkViewModel()
        let sharedRouteManager = RouteManager.shared
        let themeManager = AppThemeManager()

        _appState = StateObject(wrappedValue: sharedAppState)
        _networkState = StateObject(wrappedValue: sharedNetworkState)
        _themeManager = StateObject(wrappedValue: themeManager)

        _appCoordinator = StateObject(wrappedValue: AppCoordinator(
            appState: sharedAppState,
            networkStatus: sharedNetworkState,
            routeManager: sharedRouteManager,
            themeManager: themeManager))

        SwiftInjectDI.shared.register(NetworkManager.self) { _ in NetworkManager() }
        SwiftInjectDI.shared.register(ApiServiceMapper.self) { _ in ApiServiceMapper() }
        SwiftInjectDI.shared.register(AppThemeManager.self) { _ in AppThemeManager() }
        SwiftInjectDI.shared.register(SocketFeedClient.self) { _ in SocketFeedClient() }
    }

    var body: some Scene {
        WindowGroup {
            if isSplashScreenShown {
                SplashScene {
                    withAnimation {
                        isSplashScreenShown = false
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
                .zIndex(1)
                .preferredColorScheme(themeManager.currentScheme.colorScheme)
                .environmentObject(themeManager)
            } else {
                appCoordinator.navigationStackView()
                    .environmentObject(appState)
                    .environmentObject(networkState)
                    .environmentObject(routeManager)
                    .environmentObject(themeManager)
                    .preferredColorScheme(themeManager.currentScheme.colorScheme)
                    .transition(.opacity)
                    .zIndex(0)
                    .onAppear {
                        appCoordinator.observeAppState()
                    }
            }
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    
    static var sharedAPNsToken: Data? = nil
    private var orientationLock = UIInterfaceOrientationMask.portrait
    private let logger = Logger(
        subsystem: DeveloperConstants.BaseURL.subSystemLogger,
        category: "AppDelegate"
    )

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Calling the active socket --> Make user online
        // Create a socket event
        // Socket i will emit from here
        // once socket emited you will make that particular user online
        // active_user_event
        GMSServices.provideAPIKey(DeveloperConstants.googleApiKey)
        AWSManager.shared.configureAWS()
        FirebaseApp.configure()
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        AppDelegate.sharedAPNsToken = deviceToken
        logger.info("FCM token set")
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.error("❌ Failed to register for remote notifications: \(error)")
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return orientationLock
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Make User offline --> user left the application
        
        // Calling the active socket --> Make user offline
        // Disconnect socket event
        // Socket i will emit from here
        // once socket emited you will make that particular user online
        // active_user_event
        // Socket.io
    }
}


