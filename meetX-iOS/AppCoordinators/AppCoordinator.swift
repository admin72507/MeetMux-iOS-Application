//
//  AppCoordinator.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-12-2024.
//

import Foundation
import SwiftUI
import Combine
import os.log

class AppCoordinator: ObservableObject {
    
    @Published private var rootView             : AnyView?
    @Published private var showErrorOverlay     : Bool = false
    @ObservedObject private var routeManager    : RouteManager
    @ObservedObject private var themeManager    : AppThemeManager
    
    private var appState                        : AppStateManager
    private var networkStatus                   : NetworkViewModel
    private var cancellables: Set<AnyCancellable> = []
    private var networkCancellables: Set<AnyCancellable> = []
    private var isPlaceHolderView               : Bool = true
    private let logger = Logger(
        subsystem: DeveloperConstants.BaseURL.subSystemLogger,
        category: "AppCoordinator"
    )

    init(
        appState: AppStateManager,
        networkStatus: NetworkViewModel,
        routeManager: RouteManager,
        themeManager: AppThemeManager) {
        self.appState = appState
        self.networkStatus = networkStatus
        self.routeManager = routeManager
        self.themeManager = themeManager
    }
    
    /// Function to decide which root to be passed as rootView
    /// Based on AppState
    func observeAppState() {
        networkStatus.$isNetworkActive
            .removeDuplicates()
            .sink { [weak self] isActive in
                guard let self = self else { return }
                self.showErrorOverlay = !isActive
            }
            .store(in: &networkCancellables)

        if isPlaceHolderView {
            self.updateRootView()
        }
    }
    
    /// Function handles the updation of rootView
    func updateRootView() {
        appState.$currentScreen
            .sink { [weak self] screen in
                guard let self = self else { return }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    switch screen {
                        case .splash:
                            self.routeManager.reset()
                            self.rootView = AnyView(IntroScreenScene())
                        case .login:
                            self.rootView = AnyView(LogInRegisterScene())
                        case .profileUpdate:
                            self.rootView = AnyView(ProfileDetailsUpdation(navigationFromAppCordinator: true))
                        case .home:
                            self.rootView = AnyView(CustomTabBarView(selectedTab: 0))
                        case .oldLoginDetection:
                            self.rootView = AnyView(OldLoginDetectionView())
                        case .permissions:
                            self.rootView = AnyView(PermissionView())
                    }
                    self.isPlaceHolderView.toggle()
                }
            }
            .store(in: &cancellables)
    }
    
    
    func navigationStackView() -> some View {
        return ZStack {
            NavigationStack(path: $routeManager.path) {
                Group {
                    if let rootView = rootView {
                        rootView
                            .transition(.opacity)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ProgressView("Loading...")
                            .transition(.opacity)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .onAppear {
                    self.logger.info(
                        "📌 Current Navigation Path Count: \(self.routeManager.path.count)"
                    )
                }
                .navigationDestination(for: AppRouteWrapper.self) { routeWrapper in
                    routeWrapper.view()
                }
            }
            .preferredColorScheme(themeManager.currentScheme.colorScheme)
            .environmentObject(appState)
            GlobalLoaderOverlay()

            // No Internet View - Full Screen Overlay
            if networkStatus.shouldShowNoInternetView {
                ReachabilityScene()
                    .environmentObject(networkStatus)
                    .environmentObject(themeManager)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(999) // Ensure it appears above everything
            }
        }
        .animation(.easeInOut(duration: 0.3), value: networkStatus.shouldShowNoInternetView)
    }
}

// MARK: - Loading View
struct LoadingViewAppState: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text("Loading State...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
