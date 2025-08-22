//
//  ApiClientViewModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-12-2024.
//

import Foundation
import Combine
import OSLog

final class ApiServiceMapper: ApiServiceProtocol {
    private let networkManager: NetworkProtocolManager?
    
    init() {
        networkManager = SwiftInjectDI.shared.resolve(NetworkManager.self)
    }
    
    // MARK: - Fetch Image
    func imageDataPublisher(
        fromURLString urlString: String
    ) -> DeveloperConstants.APIService.PublisherTypes.ImageDataPublisher {
        
        guard let networkManager = networkManager else {
            return Fail(outputType: Data.self, failure: APIError.apiFailed(underlyingError: nil))
                .eraseToAnyPublisher()
        }
        
        return Just(urlString)
            .flatMap { path in
                networkManager.publisherImageFetch(fromURLString: path)
                    .handleEvents(receiveOutput: { _ in
                        // Optional: process received data here if needed (e.g., logging, updating state)
                    })
            }
            .handleEvents(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        debugPrint("\(DeveloperConstants.Network.networkErrorMessage) \(error)")
                }
            })
            .mapError { error in
                APIError.imageFetchFailed(underlyingError: error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Generic API Call -- GET
    func genericPublisher<T: Decodable>(
        fromURLString urlString: String,
        queryParameters: [String: String]? = nil,
        httpMethod: DeveloperConstants.Network.HTTPMethods? = .get
    ) -> DeveloperConstants.APIService.PublisherTypes.GenericPublisher<T> {
        
        guard let networkManager = networkManager else {
            return Empty<T, APIError>().eraseToAnyPublisher()
        }
        
        return networkManager.publisher(
            path: urlString,
            queryParameters: queryParameters,
            httpMethod: httpMethod ?? .get,
            httpBody: nil,
            timeoutInterval: 30,
            isAuthNeeded: true
        )
        .tryMap { data -> T in
            do {
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    debugPrint("Unexpected response format: \(json)")
                }
                return try JSONDecoder().decode(T.self, from: data)
            } catch let DecodingError.keyNotFound(key, context) {
                print("❌ Key '\(key.stringValue)' not found at path: \(context.codingPath.map(\.stringValue).joined(separator: " -> "))")
                print("Debug info: \(context.debugDescription)")
                throw DecodingError.keyNotFound(key, context)
            } catch let DecodingError.typeMismatch(type, context) {
                print("❌ Type mismatch for type '\(type)' at path: \(context.codingPath.map(\.stringValue).joined(separator: " -> "))")
                print("Debug info: \(context.debugDescription)")
                throw DecodingError.typeMismatch(type, context)
            } catch let DecodingError.valueNotFound(type, context) {
                print("❌ Value not found for type '\(type)' at path: \(context.codingPath.map(\.stringValue).joined(separator: " -> "))")
                print("Debug info: \(context.debugDescription)")
                throw DecodingError.valueNotFound(type, context)
            } catch let DecodingError.dataCorrupted(context) {
                print("❌ Data corrupted at path: \(context.codingPath.map(\.stringValue).joined(separator: " -> "))")
                print("Debug info: \(context.debugDescription)")
                throw DecodingError.dataCorrupted(context)
            } catch {
                print("❌ Other decoding error: \(error)")
                throw error
            }
        }
        .mapError { error in
            error as? APIError ?? APIError.apiFailed(underlyingError: error)
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Generic API Call -- POST
    func genericPostPublisher<T, U>(
        toURLString urlString: String,
        requestBody: U,
        isAuthNeeded: Bool,
        queryParameters: [String: String]? = nil,
        httpMethod : DeveloperConstants.Network.HTTPMethods? = .post
    ) -> DeveloperConstants.APIService.PublisherTypes.GenericPublisher<T> where T: Decodable, U: Encodable {
        
        guard let networkManager = networkManager else {
            return Empty<T, APIError>().eraseToAnyPublisher()
        }
        
        guard case let .success(httpBody) = JSONEncoder.encodeBody(requestBody) else {
            return Fail(error: APIError.encodingFailure(underlyingError: nil)).eraseToAnyPublisher()
        }
        
        return networkManager.publisher(
            path: urlString,
            queryParameters: queryParameters,
            httpMethod: httpMethod ?? .post,
            httpBody: httpBody,
            timeoutInterval: 30,
            isAuthNeeded: isAuthNeeded
        )
        .tryMap { data -> T in
            do {
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    debugPrint("Unexpected response format: \(json)")
                }
                return try JSONDecoder().decode(T.self, from: data)
            } catch let DecodingError.keyNotFound(key, context) {
                print("❌ Key '\(key.stringValue)' not found at path: \(context.codingPath.map(\.stringValue).joined(separator: " -> "))")
                print("Debug info: \(context.debugDescription)")
                throw DecodingError.keyNotFound(key, context)
            } catch let DecodingError.typeMismatch(type, context) {
                print("❌ Type mismatch for type '\(type)' at path: \(context.codingPath.map(\.stringValue).joined(separator: " -> "))")
                print("Debug info: \(context.debugDescription)")
                throw DecodingError.typeMismatch(type, context)
            } catch let DecodingError.valueNotFound(type, context) {
                print("❌ Value not found for type '\(type)' at path: \(context.codingPath.map(\.stringValue).joined(separator: " -> "))")
                print("Debug info: \(context.debugDescription)")
                throw DecodingError.valueNotFound(type, context)
            } catch let DecodingError.dataCorrupted(context) {
                print("❌ Data corrupted at path: \(context.codingPath.map(\.stringValue).joined(separator: " -> "))")
                print("Debug info: \(context.debugDescription)")
                throw DecodingError.dataCorrupted(context)
            } catch {
                print("❌ Other decoding error: \(error)")
                throw error
            }
        }
        .mapError { error in
            error as? APIError ?? APIError.apiFailed(underlyingError: error)
        }
        .eraseToAnyPublisher()
    }
}
