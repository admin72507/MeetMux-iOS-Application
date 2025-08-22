//
//  RouteManager 2.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 06-03-2025.
//


class RouteManager: ObservableObject {
    static let shared = RouteManager()
    @Published var path = NavigationPath()

    private init() {}

    /// Navigate to a new screen
    func navigate<T: AppRoute>(to destination: T) {
        let wrappedRoute = AppRouteWrapper(destination)

        // Prevent duplicate navigation (if last screen is the same)
        if path.count > 0, let lastRoute = path.last as? AppRouteWrapper, lastRoute == wrappedRoute {
            return
        }

        path.append(wrappedRoute)
    }

    /// Go back to the previous screen
    func goBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    /// Reset the navigation stack
    func reset() {
        path = NavigationPath()
    }
}
