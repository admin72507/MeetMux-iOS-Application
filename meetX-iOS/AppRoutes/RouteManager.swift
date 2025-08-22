//
//  RouteManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 06-03-2025.
//
import SwiftUI

class RouteManager: ObservableObject {
    
    static let shared           = RouteManager()
    @Published var path         = NavigationPath()
    var pathArray       : [AppRouteWrapper] = []
    
    private init() {}
    
    /// Navigate to a new screen
    func navigate<T: AppRoute>(to destination: T) {
        let wrappedRoute = AppRouteWrapper(destination)
        
        if pathArray.last == wrappedRoute {
            return
        }
        
        pathArray.append(wrappedRoute)
        path.append(wrappedRoute)
    }
    
    /// Go back to the previous screen
    func goBack() {
        if !path.isEmpty {
            pathArray.removeLast()
            path.removeLast()
        }
    }
    
    /// Go back N screens
    func goBackMultiple(_ count: Int) {
        guard count > 0 else { return }
        
        let popCount = min(count, path.count)
        pathArray.removeLast(popCount)
        
        for _ in 0..<popCount {
            path.removeLast()
        }
    }
    
    /// Reset the navigation stack
    func reset() {
        pathArray.removeAll()
        path = NavigationPath()
    }
}
