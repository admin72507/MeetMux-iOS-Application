//
//  ReachabilityViewModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 05-05-2025.
//

import Combine
import Foundation

// MARK: - Updated NetworkViewModel with Better State Management
class NetworkViewModel: ObservableObject {
    @Published var isNetworkActive: Bool = true
    @Published var shouldShowNoInternetView: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let networkMonitor = NetworkMonitor()
    private var connectionLostTimer: Timer?

    init() {
        setupNetworkMonitoring()
    }

    private func setupNetworkMonitoring() {
        networkMonitor.isConnectedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                guard let self = self else { return }

                self.isNetworkActive = isConnected

                if isConnected {
                    // Connection restored - hide the no internet view
                    self.shouldShowNoInternetView = false
                    self.connectionLostTimer?.invalidate()
                    self.connectionLostTimer = nil
                } else {
                    // Connection lost - show no internet view after a brief delay
                    // This prevents flickering during brief network interruptions
                    self.connectionLostTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                        if !self.isNetworkActive {
                            self.shouldShowNoInternetView = true
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        connectionLostTimer?.invalidate()
    }
}
