//
//  AppThemeObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 16-05-2025.
//

import SwiftUI

class AppThemeManager: ObservableObject {
    // 1. Backed by UserDefaults using AppStorage
    @AppStorage(DeveloperConstants.UserDefaultsInternal.themeSelectedByUser) private var storedTheme: String = AppColorScheme.system.rawValue
    
    // 2. Computed property to expose enum
    var currentScheme: AppColorScheme {
        AppColorScheme(rawValue: storedTheme) ?? .system
    }
    
    // 3. Bindable value for UI
    var selectedTheme: String {
        get { storedTheme }
        set {
            storedTheme = newValue
            objectWillChange.send()
        }
    }
}
