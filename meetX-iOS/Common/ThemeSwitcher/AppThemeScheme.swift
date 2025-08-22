//
//  AppThemeScheme.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 16-05-2025.
//

import SwiftUI
import Foundation

enum AppColorScheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
        }
    }
    
    var displayName: String {
        switch self {
            case .system: return "System Default"
            case .light: return "Light"
            case .dark: return "Dark"
        }
    }
}
