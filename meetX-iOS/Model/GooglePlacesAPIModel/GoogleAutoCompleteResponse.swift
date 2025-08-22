//
//  GoogleAutoCompleteResponse.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 19-05-2025.
//
import Foundation

struct GoogleAutocompleteResponse: Decodable {
    let predictions: [Prediction]
    let status: String
}

struct Prediction: Decodable {
    let description: String
    let place_id: String
    let types: [String]
}

