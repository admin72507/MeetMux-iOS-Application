//
//  TimerManagerObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-05-2025.
//
import Combine
import Foundation

final class TimerManager: ObservableObject {
    static let shared = TimerManager()
    
    @Published var now: Date = Date()
    private var cancellable: AnyCancellable?
    
    private init() {
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] in
                self?.now = $0
            }
    }
}
