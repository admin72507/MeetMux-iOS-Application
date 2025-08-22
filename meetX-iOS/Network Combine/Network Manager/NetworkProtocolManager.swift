//
//  CombineProtocolManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-12-2024.
//
import Combine
import Foundation

protocol NetworkProtocolManager {
    func publisher(
        path: String,
        queryParameters: [String: String]?,
        httpMethod: DeveloperConstants.Network.HTTPMethods,
        httpBody: Data?,
        timeoutInterval: TimeInterval,
        isAuthNeeded: Bool?
    ) -> AnyPublisher<Data, Error>
    
    func publisherImageFetch(fromURLString urlString: String) -> AnyPublisher<Data, Error>
}
