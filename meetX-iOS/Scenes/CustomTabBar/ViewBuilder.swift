//
//  ViewBuilder.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 29-12-2024.
//

import SwiftUI
import Foundation

public struct ViewBuilderTab: View {
    
    var safeAreaInsets                : EdgeInsets
    @Binding var isPressed            : Bool
    @Binding var selectedTab          : Int
    var themeGradientColour           : LinearGradient
    var tabItems                      : [DeveloperConstants.Tab.Item]
    
    public var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 0) {
                ForEach(0..<tabItems.count, id: \.self) { index in
                    tabButton(for: index)
                }
            }
            .padding(
                .horizontal, DeveloperConstants.Tab.mainViewHorizontalTabBarSpacing)
            .frame(
                height: 50)
            .background(
                ThemeManager.tabBarColor
                    .clipShape(
                        HelperFunctions.CustomTabBarShape(
                            cornerRadius: DeveloperConstants.Tab.mainTabBarRadius)))
            .shadow(
                color: ThemeManager.tabBarShadowColor,
                radius: DeveloperConstants.Tab.mainViewTabBarShadowRadius,
                x: 0,
                y: 0
            )
            .padding()
            .padding(.bottom, 5)
        }
    }
    
    @ViewBuilder
    public func tabButton(for index: Int) -> some View {
        if index == 2 {
            Button(action: {
                withAnimation(
                    .spring(
                        response: 0.3,
                        dampingFraction: 0.5,
                        blendDuration: 0)) {
                            RouteManager.shared.navigate(to: CreatePostRoute())
                        }
//                Task {
//                    try await Task.sleep(nanoseconds: 200_000_000)
//                    isPressed = false
//                    if selectedTab != index {
//                        selectedTab = index
//                    }
//                }
            }) {
                    ZStack {
                        Circle()
                            .fill(themeGradientColour)
                            .frame(width: isPressed ? 70 : 50, height: isPressed ? 70 : 50)
                        Image(systemName: DeveloperConstants.Tab.items[index].selectedIcon)
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                    }}
                .offset(y: -25)
                .accessibilityLabel("Tab \(index)")
        } else {
            TabBarButtonStyle(
                selected: DeveloperConstants.Tab.items[index].selectedIcon,
                notSelected: DeveloperConstants.Tab.items[index].unselectedIcon,
                title: DeveloperConstants.Tab.items[index].title,
                isSelected: selectedTab == index)
            .onTapGesture {
                if selectedTab != index {
                    selectedTab = index
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Each Tab Bar Element
struct TabBarButtonStyle: View {
    let selected    : String
    let notSelected : String
    let title       : String
    let isSelected  : Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        VStack(spacing: title.isEmpty ? 0 : 3) {
            Image(systemName: isSelected ? selected : notSelected)
                .font(.system(size: isSelected ? 28 : 22))
                .foregroundColor(isSelected ? .clear : ThemeManager.unselectedTabColor)
                .background(isSelected ? gradientMask : nil)
                .scaleEffect(scale)
                .opacity(opacity)
                .onChange(of: isSelected) { oldValue, newValue in
                    withAnimation(.bouncy(duration: 0.3)) {
                        scale = newValue ? 1.2 : 1.0
                        opacity = newValue ? 1.0 : 0.7
                    }
                }
                .symbolEffect(
                    .bounce,
                    options: AnimationHelper.bounce(repeating: false),
                    isActive: isSelected)
            
            
            if !title.isEmpty {
                Text(title)
                    .font(.caption)
                    .fontWeight(.thin)
                    .foregroundColor(isSelected ? .clear : ThemeManager.unselectedTabColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .opacity(isSelected ? 1.0 : 0.6)
                    .padding(.top, isSelected ? 10 : 3)
                    .animation(.easeInOut(duration: 0.3), value: isSelected)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            scale = isSelected ? 1.2 : 1.0
            opacity = isSelected ? 1.0 : 0.7
        }
    }
    
    private var gradientMask: some View {
        ThemeManager.gradientBackground
            .mask(
                Image(systemName: selected)
                    .font(.system(size: 26)))
    }
}

#Preview() {
    ViewBuilderTab(safeAreaInsets: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10),
                   isPressed: .constant(true), selectedTab: .constant(0), themeGradientColour: ThemeManager.gradientBackground, tabItems: DeveloperConstants.Tab.items)
}
