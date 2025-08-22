//
//  PermissionHelper.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 15-02-2025.
//
import PhotosUI
import AVFoundation
import Foundation
import UserNotifications
import AppTrackingTransparency
import Contacts

final class PermissionHelper {
    
    // MARK: - Photo Library access permission
    func requestPhotoPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
            case .authorized:
                completion(true)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { newStatus in
                    DispatchQueue.main.async {
                        completion(newStatus == .authorized)
                    }
                }
            case .denied:
                completion(false)
                
            default:
                completion(false)
        }
    }
    
    //MARK: - Camera Request Permission
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
            case .authorized:
                completion(true)
                
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
                
            case .denied, .restricted:
                completion(false)
                
            @unknown default:
                completion(false)
        }
    }
    
    //MARK: - Open Settings
    @MainActor func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    //MARK: - Notification Helper
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                DispatchQueue.main.async {
                    completion(granted)
                }
            } catch {
                print("⚠️ Error requesting notification permissions: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    //MARK: - Tracking Permission
    func requestTrackingPermission(completionHandler: @escaping (Bool) -> Void) {
        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                    case .authorized:
                        print("✅ Tracking permission granted")
                        completionHandler(true)
                    case .denied:
                        print("❌ Tracking permission denied")
                        completionHandler(false)
                    case .notDetermined:
                        print("🔄 Tracking permission not determined")
                        completionHandler(false)
                    case .restricted:
                        print("⚠️ Tracking permission restricted")
                        completionHandler(false)
                    @unknown default:
                        completionHandler(false)
                }
            }
        }
    }
    
    func getLocationAuthStatus() -> Bool {
        let locationAuthorizationStatus = CLLocationManager().authorizationStatus
        switch locationAuthorizationStatus {
            case .notDetermined:
                return false
            case .denied, .restricted:
                return false
            case .authorizedAlways, .authorizedWhenInUse:
                return true
            default:
                return false
        }
    }
    
    //MARK: - Permission Handler (Thread-safe sync version)
    func checkPermissionsHandlerSync() -> [DeveloperConstants.PermissionStep: DeveloperConstants.PermissionStatus] {
        // 1. Check Location Permission
        var locationStatus: DeveloperConstants.PermissionStatus = .granted
        let locationAuthorizationStatus = CLLocationManager().authorizationStatus
        switch locationAuthorizationStatus {
            case .notDetermined:
                locationStatus = .notDetermined
            case .denied, .restricted:
                locationStatus = .denied
            default:
                locationStatus = .granted
        }
        
        // 2. Check Tracking Permission
        var trackingStatus: DeveloperConstants.PermissionStatus = .granted
        if #available(iOS 14, *) {
            switch ATTrackingManager.trackingAuthorizationStatus {
                case .notDetermined:
                    trackingStatus = .notDetermined
                case .denied:
                    trackingStatus = .denied
                default:
                    trackingStatus = .granted
            }
        } else {
            trackingStatus = .denied
        }
        
        // 3. Check Notification Permission (Thread-safe with proper timeout)
        var notificationStatus: DeveloperConstants.PermissionStatus = .granted
        let semaphore = DispatchSemaphore(value: 0)
        let timeoutSeconds: Double = 5.0 // Add timeout to prevent indefinite blocking
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
                case .notDetermined:
                    notificationStatus = .notDetermined
                case .denied:
                    notificationStatus = .denied
                default:
                    notificationStatus = .granted
            }
            semaphore.signal()
        }
        
        // Wait with timeout to prevent deadlock
        let result = semaphore.wait(timeout: .now() + timeoutSeconds)
        if result == .timedOut {
            print("⚠️ Warning: Notification permission check timed out")
            notificationStatus = .notDetermined // Default to not determined on timeout
        }
        
        // Collect denied or not determined permissions
        var deniedPermissions: [DeveloperConstants.PermissionStep: DeveloperConstants.PermissionStatus] = [:]
        
        if locationStatus == .denied || locationStatus == .notDetermined {
            deniedPermissions[.locationService] = locationStatus
        }
        if notificationStatus == .denied || notificationStatus == .notDetermined {
            deniedPermissions[.notificationService] = notificationStatus
        }
        if trackingStatus == .denied || trackingStatus == .notDetermined {
            deniedPermissions[.analytics] = trackingStatus
        }
        
        return deniedPermissions
    }

    // MARK: - Check Permissions Async but if it was denied also dont make the user go to settings screen
    func checkPermissionsHandlerSyncLogin() -> [DeveloperConstants.PermissionStep: DeveloperConstants.PermissionStatus] {
        // 1. Check Location Permission
        var locationStatus: DeveloperConstants.PermissionStatus = .granted
        let locationAuthorizationStatus = CLLocationManager().authorizationStatus
        switch locationAuthorizationStatus {
            case .notDetermined:
                locationStatus = .notDetermined
            case .denied, .restricted:
                locationStatus = .denied
            default:
                locationStatus = .granted
        }

        // 2. Check Tracking Permission
        var trackingStatus: DeveloperConstants.PermissionStatus = .granted
        if #available(iOS 14, *) {
            switch ATTrackingManager.trackingAuthorizationStatus {
                case .notDetermined:
                    trackingStatus = .notDetermined
                case .denied:
                    trackingStatus = .denied
                default:
                    trackingStatus = .granted
            }
        } else {
            trackingStatus = .denied
        }

        // 3. Check Notification Permission (Thread-safe with proper timeout)
        var notificationStatus: DeveloperConstants.PermissionStatus = .granted
        let semaphore = DispatchSemaphore(value: 0)
        let timeoutSeconds: Double = 5.0 // Add timeout to prevent indefinite blocking

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
                case .notDetermined:
                    notificationStatus = .notDetermined
                case .denied:
                    notificationStatus = .denied
                default:
                    notificationStatus = .granted
            }
            semaphore.signal()
        }

        // Wait with timeout to prevent deadlock
        let result = semaphore.wait(timeout: .now() + timeoutSeconds)
        if result == .timedOut {
            print("⚠️ Warning: Notification permission check timed out")
            notificationStatus = .notDetermined // Default to not determined on timeout
        }

        // Collect denied or not determined permissions
        var deniedPermissions: [DeveloperConstants.PermissionStep: DeveloperConstants.PermissionStatus] = [:]

        if locationStatus == .notDetermined {
            deniedPermissions[.locationService] = locationStatus
        }
        if notificationStatus == .notDetermined {
            deniedPermissions[.notificationService] = notificationStatus
        }
        if trackingStatus == .notDetermined {
            deniedPermissions[.analytics] = trackingStatus
        }

        return deniedPermissions
    }

    //MARK: - Permission Handler (Async version to fix threading issues)
    func checkPermissionsHandler() async -> [DeveloperConstants.PermissionStep: DeveloperConstants.PermissionStatus] {
        // 1. Check Location Permission
        var locationStatus: DeveloperConstants.PermissionStatus = .granted
        let locationAuthorizationStatus = CLLocationManager().authorizationStatus
        switch locationAuthorizationStatus {
            case .notDetermined:
                locationStatus = .notDetermined
            case .denied, .restricted:
                locationStatus = .denied
            default:
                locationStatus = .granted
        }
        
        // 2. Check Tracking Permission
        var trackingStatus: DeveloperConstants.PermissionStatus = .granted
        if #available(iOS 14, *) {
            switch ATTrackingManager.trackingAuthorizationStatus {
                case .notDetermined:
                    trackingStatus = .notDetermined
                case .denied:
                    trackingStatus = .denied
                default:
                    trackingStatus = .granted
            }
        } else {
            trackingStatus = .denied
        }
        
        // 3. Check Notification Permission (Async)
        let notificationStatus: DeveloperConstants.PermissionStatus = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                let status: DeveloperConstants.PermissionStatus
                switch settings.authorizationStatus {
                    case .notDetermined:
                        status = .notDetermined
                    case .denied:
                        status = .denied
                    default:
                        status = .granted
                }
                continuation.resume(returning: status)
            }
        }
        
        // Collect denied or not determined permissions
        var deniedPermissions: [DeveloperConstants.PermissionStep: DeveloperConstants.PermissionStatus] = [:]
        
        if locationStatus == .notDetermined {
            deniedPermissions[.locationService] = locationStatus
        }
        if notificationStatus == .notDetermined {
            deniedPermissions[.notificationService] = notificationStatus
        }
        if trackingStatus == .notDetermined {
            deniedPermissions[.analytics] = trackingStatus
        }
        
        return deniedPermissions
    }
    
    func checkContactPermission() -> Bool {
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        switch authorizationStatus {
            case .authorized, .limited:
                return true
            case .denied, .restricted, .notDetermined:
                return false
            @unknown default:
                return false
        }
    }
    
    func findContactsPermissionDenied() -> CNAuthorizationStatus {
        return CNContactStore.authorizationStatus(for: .contacts)
    }
    
    // Add this method to your PermissionHelper class
    func requestContactPermission(completion: @escaping (Bool) -> Void) {
        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // Keep your existing method for backward compatibility
    func requestContactPermission() {
        requestContactPermission { _ in }
    }
}

extension PermissionHelper {
    var isContactsDenied: Bool {
        findContactsPermissionDenied() == .denied
    }
    
    var isContactAuthorized: Bool {
        findContactsPermissionDenied() == .authorized
    }
}
