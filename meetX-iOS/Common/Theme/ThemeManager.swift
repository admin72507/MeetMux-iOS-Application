//
//  ThemeManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 25-12-2024.
//

import SwiftUI

// MARK: - ThemeManager
struct ThemeManager {
    static var backgroundColor: Color {
        return Color(UIColor.systemBackground) // Dynamic background for light/dark mode
    }
    
    static var foregroundColor: Color {
        return Color(UIColor.label) // Dynamic text color for light/dark mode
    }
    
    static var tabBarColor: Color {
        return Color(UIColor.systemBackground) // Use this for the tab bar background
    }
    
    static var tabBarShadowColor: Color {
        return Color.gray.opacity(1) // Shadow color for tab bar
    }
    
    static var gradientBackground: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 7 / 255, green: 0 / 255, blue: 224 / 255, opacity: 1.0),  // First color
                Color(red: 142 / 255, green: 45 / 255, blue: 226 / 255, opacity: 1.0) // Second color
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var gradientNewPinkBackground: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 140 / 255, green: 45 / 255, blue: 225 / 255, opacity: 1.0),  // First color
                Color(red: 255 / 255, green: 199 / 255, blue: 70 / 255, opacity: 1.0) // Second color
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var gradientGreyColour: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color(.lightGray), Color.white]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var unselectedTabColor: Color {
        return .gray // Default color for unselected tabs
    }
    
    // static purple color
    static var staticPurpleColour : Color {
        return Color(red: 111 / 255, green: 19 / 255, blue: 245 / 255, opacity: 1.0)
    }
    
    static var softPinkBackground: Color {
        return Color(red: 248 / 255, green: 231 / 255, blue: 246 / 255, opacity: 1.0)
    }
    
    static var lightGrayBackground: Color {
        return Color(red: 241 / 255, green: 240 / 255, blue: 245 / 255, opacity: 1.0)
    }

    //Static pink colour
    static var staticPinkColour : Color {
        return Color(red: 142 / 255, green: 45 / 255, blue: 226 / 255, opacity: 1.0)
    }
    
    static var darkBackground: Color {
        return Color(red: 17 / 255, green: 18 / 255, blue: 21 / 255, opacity: 1.0)
    }
    
    static var purpleCAGradient: CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 7 / 255, green: 0 / 255, blue: 224 / 255, alpha: 1.0).cgColor,   // First color
            UIColor(red: 142 / 255, green: 45 / 255, blue: 226 / 255, alpha: 1.0).cgColor // Second color
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5) // Leading
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)   // Trailing
        return gradientLayer
    }

}
