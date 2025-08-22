//
//  ApiError.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-12-2024.
//

import Foundation

struct IdentifiableAPIError: Identifiable {
    let id = UUID()
    let error: APIError
}

public enum APIError: Error {
    case apiFailed(underlyingError: Error?)
    case modelSerialisationFailed(underlyingError: Error?)
    case imageFetchFailed(underlyingError: Error?)
    case encodingFailure(underlyingError: Error?)
    case serverErrorDictionary([String: Any])
}

extension APIError: LocalizedError {
    var localizedDescription: String {
        switch self {
            case .apiFailed(underlyingError: let error):
                return underlyingErrorDescription(error)
            case .modelSerialisationFailed(underlyingError: let error):
                return underlyingErrorDescription(error)
            case .imageFetchFailed(underlyingError: let error):
                return underlyingErrorDescription(error)
            case .encodingFailure(underlyingError: let error):
                return underlyingErrorDescription(error)
            case .serverErrorDictionary(let dict):
                return parseErrorDictionary(dict)
        }
    }
    
    private func underlyingErrorDescription(_ error: Error?) -> String {
        guard let error = error else { return "" }
        return "\(DeveloperConstants.General.error) \(error.localizedDescription)"
    }
    
    private func parseErrorDictionary(_ dict: [String: Any]) -> String {
        if let message = dict["message"] as? String {
            return message
        } else if let error = dict["error"] as? String {
            return error
        } else {
            return DeveloperConstants.General.error + " Unknown server error."
        }
    }
}
