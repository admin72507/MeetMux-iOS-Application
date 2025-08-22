//
//  KeyboardManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 27-06-2025.
//

import Combine
import UIKit

final class KeyboardManager: ObservableObject {
    @Published var isKeyboardVisible: Bool = false
    private var cancellableSet: Set<AnyCancellable> = []
    
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] _ in self?.isKeyboardVisible = true }
            .store(in: &cancellableSet)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in self?.isKeyboardVisible = false }
            .store(in: &cancellableSet)
    }
}
