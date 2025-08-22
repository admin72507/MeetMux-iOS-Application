//
//  LocationHandler.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 17-07-2025.
//

import Foundation
import SwiftUI

struct LocationStorage {
    @AppStorage("location_main_name") static var mainName: String = Constants.locateMeText
    @AppStorage("location_entire_name") static var entireName: String = Constants.locateMeDescription
    @AppStorage("location_lat") static var latitude: Double = 0.0
    @AppStorage("location_lon") static var longitude: Double = 0.0
    @AppStorage("is_using_current_location") static var isUsingCurrentLocation: Bool = false

    // Save Method
    static func save(main: String, entire: String, lat: Double?, lon: Double?) {
        mainName = main
        entireName = entire
        latitude = lat ?? 0.0
        longitude = lon ?? 0.0
    }

    // Clear Method
    static func clear() {
        mainName = ""
        entireName = ""
        latitude = 0.0
        longitude = 0.0
        isUsingCurrentLocation = false
    }

    // Computed Properties
    static var mainLocationName: String {
        mainName
    }

    static var entireLocationName: String {
        entireName
    }

    static var locationLatitude: Double {
        latitude
    }

    static var locationLongitude: Double {
        longitude
    }

    static var usingCurrentLocation: Bool {
        isUsingCurrentLocation
    }
}
