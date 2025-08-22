//
//  SocketIOManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 18-05-2025.
//
import Foundation
import SocketIO

final class SocketIOManager {
    static let shared = SocketIOManager()
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private let userDetails = UserDataManager.shared.getSecureUserData()

    private init() {}
    
    // MARK: - Configuration
    // Sending the base URL with Auth headers
    func configure(baseURL: String) {
        let url = URL(string: baseURL)! 
        manager = SocketManager(socketURL: url, config: [
            .log(true),
            .compress,
            .forceWebsockets(true),
            .connectParams([
                "contentType": "application/json",
                "platformType": "ios",
                "acceptLanguage": "en",
                "token": KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userTokenKeychainIdentifier) ?? ""
            ])
        ])
        socket = manager?.defaultSocket
    }
    
    // MARK: - Connection
    func connect(completion: @escaping (Bool) -> Void) {
        guard let socket = socket else {
            print("⚠️ Socket not configured. Call configure(baseURL:) first.")
            completion(false)
            return
        }
        
        socket.on(clientEvent: .connect) { _, _ in
            print("✅ Socket connected")
            completion(true)
        }
        
        socket.on(clientEvent: .error) { data, _ in
            print("❌ Socket error: \(data)")
            completion(false)
        }
        
        socket.on(clientEvent: .disconnect) { data, _ in
            print("🔌 Socket disconnected: \(data)")
            completion(false)
        }
        
        socket.connect()
    }

    func disconnect() {
        socket?.disconnect()
        socket?.off(clientEvent: .disconnect)
    }
    
    // MARK: - Emit & Listen
    func emit(event: String, data: [String: Any]) { // Running seperate background
        socket?.emit(event, data)
    }
    
    func onlistenEvent(event: String, callback: @escaping ([Any], SocketAckEmitter) -> Void) {
        socket?.on(event, callback: callback)
    }
    
    func off(event: String) {
        socket?.off(event)
    }

    func emitWithAck<T: Decodable>(
        event: String,
        data: [String: Any],
        timeout: Double = 5,
        decodeTo type: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        socket?.emitWithAck(event, data).timingOut(after: timeout) { response in
            guard let first = response.first else {
                completion(.failure(NSError(domain: "SocketAck", code: 408, userInfo: [NSLocalizedDescriptionKey: "No response from server."])))
                return
            }

            do {
                let jsonData: Data

                // Handle different response types
                switch first {
                    case let dict as [String: Any]:
                        // Already a dictionary - can serialize directly
                        jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                    case let array as [Any]:
                        // Already an array - can serialize directly
                        jsonData = try JSONSerialization.data(withJSONObject: array, options: [])
                    case let string as String:
                        // String response - encode as UTF-8
                        jsonData = string.data(using: .utf8) ?? Data()
                    default:
                        // For other primitive types, wrap in a dictionary
                        let wrappedResponse = ["value": first]
                        jsonData = try JSONSerialization.data(withJSONObject: wrappedResponse, options: [])
                }

                let decoded = try JSONDecoder().decode(T.self, from: jsonData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
