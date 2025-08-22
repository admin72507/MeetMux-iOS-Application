//
//  ApiServiceProtocol.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-12-2024.
//

import Foundation
import Combine


/// Protocol will add all kinds of API needed
/// Keep on increasing when new API hit is needed
 protocol ApiServiceProtocol {
     func imageDataPublisher(fromURLString urlString: String) -> DeveloperConstants.APIService.PublisherTypes.ImageDataPublisher
    
     func genericPublisher<T: Decodable>(
        fromURLString urlString: String,
        queryParameters: [String: String]?,
        httpMethod: DeveloperConstants.Network.HTTPMethods?
     ) -> DeveloperConstants.APIService.PublisherTypes.GenericPublisher<T>
     
     func genericPostPublisher<T: Decodable, U: Encodable>(
        toURLString urlString: String,
        requestBody: U,
        isAuthNeeded: Bool,
        queryParameters: [String: String]?,
        httpMethod: DeveloperConstants.Network.HTTPMethods?
     ) -> DeveloperConstants.APIService.PublisherTypes.GenericPublisher<T>
}

// Making generic protocol optional
extension ApiServiceProtocol {
    
    func genericPublisher<T>(fromURLString urlString: DeveloperConstants.Network.Endpoints) -> DeveloperConstants.APIService.PublisherTypes.GenericPublisher<T> {
        return Fail<T, APIError>(error: .apiFailed(underlyingError: nil))
            .eraseToAnyPublisher()
    }
}
