//
//  TabBarCoordinator.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 26-12-2024.
//

import SwiftUI
import Foundation

class TabCoordinator: ObservableObject {
    @Published var paths: [Int: NavigationPath] = [:]
    private var viewCache: [Int: AnyView] = [:]
    
    // NEW: store view models so they live beyond the view struct lifecycle
    private var homeViewModels: [Int: HomeObservable] = [:]
    
    let routeManager = RouteManager.shared
    
    init(tabCount: Int) {
        for tab in 0..<tabCount {
            paths[tab] = NavigationPath()
        }
    }
    
    func getPath(for tab: Int) -> Binding<NavigationPath> {
        Binding(
            get: { self.paths[tab] ?? NavigationPath() },
            set: { self.paths[tab] = $0 }
        )
    }
    
    func getContentView(for tab: Int, isTabBarPresented: Binding<Bool>) -> AnyView {
        switch tab {
            case 0:
                let vm: HomeObservable
                if let existingVM = homeViewModels[tab] {
                    vm = existingVM
                } else {
                    let socketClient = SocketFeedClient()
                    let locationViewModel = LocationObservable()
                    vm = HomeObservable(
                        socketClient: socketClient,
                        locationVM: locationViewModel
                    )
                    homeViewModels[tab] = vm
                }
                
                return AnyView(HomePageScene(
                    isTabBarPresented: isTabBarPresented,
                    viewModel: vm))
                
            case 1:
                let socketClient = SocketFeedClient()
                let viewModel = ExploreViewModel(
                    socketClient: socketClient
                )
                return AnyView(LazyView(ExploreScene(
                    viewModel: viewModel,
                    isTabBarPresented: isTabBarPresented
                )))
            case 2:
                return AnyView(EmptyView())
            case 3:
                return AnyView(LazyView(ChatLandingScene(isTabBarPresented: isTabBarPresented)))
            default:
                return AnyView(LazyView(ControlRoomScene()))
        }
    }
    
    // MARK: - Lazy view wrapper
    struct LazyView<Content: View>: View {
        let content: () -> Content
        
        init(_ content: @autoclosure @escaping () -> Content) {
            self.content = content
        }
        
        var body: Content {
            content()
        }
    }
}
