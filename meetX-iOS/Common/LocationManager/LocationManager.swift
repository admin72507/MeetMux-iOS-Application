//
//  LocationManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 01-04-2025.
//

//import Foundation
//import CoreLocation
//
//class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
//    private let manager = CLLocationManager()
//    
//    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
//    @Published var userLocation: CLLocation?  // ✅ Track the user's location
//    
//    private var permissionCallback: ((Bool) -> Void)?
//    
//    override init() {
//        super.init()
//        manager.delegate = self
//        authorizationStatus = manager.authorizationStatus
//    }
//    
//    func requestLocationPermission(completion: @escaping (Bool) -> Void) {
//        permissionCallback = completion
//        manager.requestWhenInUseAuthorization()
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        DispatchQueue.main.async {
//            self.authorizationStatus = status
//            let isGranted = (status == .authorizedWhenInUse || status == .authorizedAlways)
//            
//            if isGranted {
//                self.manager.startUpdatingLocation()  // ✅ Start tracking location
//            }
//            
//            self.permissionCallback?(isGranted)
//            self.permissionCallback = nil
//        }
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.last else { return }
//        DispatchQueue.main.async {
//            self.userLocation = location  // ✅ Update user’s current location
//        }
//    }
//}

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var userLocation: CLLocation?
    
    private var permissionCallback: ((Bool) -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
        authorizationStatus = manager.authorizationStatus
    }
    
    func requestLocationPermission(completion: @escaping (Bool) -> Void) {
        permissionCallback = completion
        manager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            let isGranted = (status == .authorizedWhenInUse || status == .authorizedAlways)
            
            if isGranted {
                self.manager.startUpdatingLocation()
            }
            
            self.permissionCallback?(isGranted)
            self.permissionCallback = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }
}

