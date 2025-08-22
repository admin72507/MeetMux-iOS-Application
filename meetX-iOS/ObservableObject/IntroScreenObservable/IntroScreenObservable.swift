//
//  IntroScreenObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 06-03-2025.
//

import SwiftUI
import Combine

class IntroScreenObservable: ObservableObject {
    
    @Published var currentPage  = 0
    @Published var animate      = false
    private var timer           : AnyCancellable?
    private let totalPages      : Int
    let userDataManager: UserDataManager
    
    init(
        totalPages: Int,
        userDataManager: UserDataManager = UserDataManager.shared
    ) {
        self.totalPages = totalPages
        self.userDataManager = userDataManager
        startTimer()
    }
    
    /// Starts auto-scroll with smooth animations
    func startTimer() {
        timer = Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.nextPage()
            }
    }
    
    /// Stops the timer when needed
    func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    /// Handle Navigation
    func handleNavigation() {
        DispatchQueue.main.async {
            RouteManager.shared.navigate(to: LoginRegister())
        }
    }
    
    /// Handles the transition to the next page with animation
    func nextPage() {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.animate = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    if self.currentPage < self.totalPages - 1 {
                        self.currentPage += 1
                    } else {
                        self.currentPage = 0
                    }
                    self.animate = false
                }
            }
        }
    }
}
