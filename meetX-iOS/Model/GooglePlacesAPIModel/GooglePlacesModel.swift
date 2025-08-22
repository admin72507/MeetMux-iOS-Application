//
//  GooglePlacesModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 18-05-2025.
//

import Foundation

struct GoogleGeocodeResponse: Decodable {
    let results: [GooglePlacemark]
    let status: String
}

struct GooglePlacemark: Decodable {
    let address_components: [AddressComponent]
    let formatted_address: String
    let geometry: Geometry
    
    struct Geometry: Decodable {
        let location: Location
        
        struct Location: Decodable {
            let lat: Double
            let lng: Double
        }
    }
}

struct AddressComponent: Decodable {
    let long_name: String
    let short_name: String
    let types: [String]
}

