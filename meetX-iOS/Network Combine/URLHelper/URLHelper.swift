//
//  URLHelper.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-12-2024.
//

import Foundation

/// Class will take care of the URL components generation
final class URLHelper {
    
    static func createURLRequest(
        path: String,
        queryParameters: [String: String]? = nil,
        httpMethod: DeveloperConstants.Network.HTTPMethods,
        httpBody: Data?,
        timeoutInterval: TimeInterval,
        headers: [String: String]
    ) -> URLRequest? {
        
        var components          = URLComponents()
        components.scheme       = DeveloperConstants.Network.scheme
        components.host         = DeveloperConstants.BaseURL.baseURL
        components.path         = path
        
        if let queryParameters = queryParameters {
            components.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = components.url else {
            return nil
        }
        
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = httpMethod.rawValue
        request.httpBody = httpBody
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }
}
