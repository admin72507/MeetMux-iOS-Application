//
//  CustomTabBar.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 25-12-2024.
//

import SwiftUI

// MARK: - Main Tab Container
struct CustomTabBarView: View {
    
    @State private var selectedTab                : Int = 0
    @StateObject private var tabCoordinator       : TabCoordinator
    @State private var isPressed                  = false
    @State private var isTabBarPresented          : Bool = true
    let routeManager = RouteManager.shared
    @EnvironmentObject var themeManager: AppThemeManager
    
    init(selectedTab: Int) {
        self.selectedTab = selectedTab
        _tabCoordinator = StateObject(wrappedValue: TabCoordinator(tabCount: DeveloperConstants.Tab.items.count))
    }
    
    // MARK: - Main Tab Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LoadViewsBasedOnTabSelected(
                    tabCoordinator: tabCoordinator,
                    selectedIndex: $selectedTab,
                    isTabBarPresented: $isTabBarPresented)
                
                if isTabBarPresented {
                    ViewBuilderTab(
                        safeAreaInsets: geometry.safeAreaInsets,
                        isPressed: $isPressed,
                        selectedTab: $selectedTab,
                        themeGradientColour: ThemeManager.gradientBackground,
                        tabItems: DeveloperConstants.Tab.items)
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .preferredColorScheme(themeManager.currentScheme.colorScheme)
        }
    }
}

// MARK: - Navigation
struct LoadViewsBasedOnTabSelected: View {
    
    @ObservedObject var tabCoordinator      : TabCoordinator
    @Binding var selectedIndex              : Int
    @Binding var isTabBarPresented          : Bool
    
    var body: some View {
        tabCoordinator.getContentView(for: selectedIndex, isTabBarPresented: $isTabBarPresented)
    }
}

#Preview {
    Group {
        CustomTabBarView(selectedTab: 3)
            .environment(\.colorScheme, .dark)
    }
}
