//
//  CombineManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-12-2024.
//

import Combine
import Foundation

class NetworkManager: NetworkProtocolManager {
    
    func publisher(
        path: String,
        queryParameters: [String: String]? = nil,
        httpMethod: DeveloperConstants.Network.HTTPMethods,
        httpBody: Data?,
        timeoutInterval: TimeInterval,
        isAuthNeeded: Bool?
    ) -> AnyPublisher<Data, any Error> {
        
        guard let request = URLHelper.createURLRequest(
            path: path,
            queryParameters: queryParameters,
            httpMethod: httpMethod,
            httpBody: httpBody,
            timeoutInterval: timeoutInterval,
            headers: isAuthNeeded ?? false
            ? DeveloperConstants.Network.urlHeadersWithAuthorization(contentType: .json)
            : DeveloperConstants.Network.urlHeaders
        ) else {
            return Fail(outputType: Data.self, failure: APIError.apiFailed(underlyingError: URLError(.badURL)))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { error in
                APIError.apiFailed(underlyingError: error)
            }
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    /// Used for image-related API calls
    func publisherImageFetch(fromURLString urlString: String) -> AnyPublisher<Data, any Error> {
        guard let url = URL(string: urlString) else {
            return Fail(outputType: Data.self, failure: APIError.apiFailed(underlyingError: URLError(.badURL)))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .receive(on: DispatchQueue.main)
            .mapError { error in
                APIError.imageFetchFailed(underlyingError: error)
            }
            .map { $0.data }
            .eraseToAnyPublisher()
    }
}

