//
//  Reachability.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 30-12-2024.
//

import Network
import Combine

class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    private let subject = CurrentValueSubject<Bool, Never>(false) // Assume disconnected initially
    private var lastPathStatus: NWPath.Status = .requiresConnection // Default to an invalid state
    
    /// Publisher to listen to network status updates
    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        subject
            .removeDuplicates()
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            // Check if the path status has genuinely changed
            if path.status != self.lastPathStatus {
                self.lastPathStatus = path.status
                
                // Update the state based on path.status
                let isConnected = path.status == .satisfied
                debugPrint("Path Status: \(path.status), Network State: \(isConnected)")
                
                // Emit the updated state
                self.subject.send(isConnected)
            } else {
                debugPrint("No change in Path Status: \(path.status)")
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
