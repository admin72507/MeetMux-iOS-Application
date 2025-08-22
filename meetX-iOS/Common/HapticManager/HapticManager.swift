
//
//  HapticManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 09-06-2025.
//

import UIKit

enum HapticStyle {
    case light, medium, heavy, success, warning, error
}

struct HapticManager {
    static func trigger(_ style: HapticStyle) {
        switch style {
            case .light:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case .medium:
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            case .heavy:
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            case .success:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .warning:
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            case .error:
                UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
