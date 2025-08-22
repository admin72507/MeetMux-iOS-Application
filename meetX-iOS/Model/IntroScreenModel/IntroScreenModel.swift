//
//  IntroScreenModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 07-03-2025.
//
import Foundation
import SwiftUI

struct IntroItem {
    let id : UUID = UUID()
    let lightIcon: String
    let darkIcon: String
    let description: String
    let title: String
    
    func icon(for colorScheme: ColorScheme) -> String {
        return colorScheme == .dark ? darkIcon : lightIcon
    }
}

