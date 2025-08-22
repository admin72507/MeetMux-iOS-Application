//
//  AppRoutes.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 06-03-2025.
//
import SwiftUI

protocol AppRoute: Hashable {
    
    associatedtype Destination: View
    @ViewBuilder func view() -> Destination
}

struct AppRouteWrapper: Hashable, Identifiable {
    
    let id                  = UUID()
    private let viewBuilder : () -> AnyView
    
    init<T: AppRoute>(_ route: T) {
        self.viewBuilder = { AnyView(route.view()) }
    }
    
    func view() -> AnyView {
        viewBuilder()
    }
    
    static func == (lhs: AppRouteWrapper, rhs: AppRouteWrapper) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
