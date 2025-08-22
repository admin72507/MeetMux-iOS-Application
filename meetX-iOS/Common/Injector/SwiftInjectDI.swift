//
//  SwiftInjectDI.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 22-04-2025.
//

import Swinject

final class SwiftInjectDI {
    static let shared = SwiftInjectDI()
    private let container: Container
    
    private init() {
        self.container = Container()
    }
    
    func register<Dependency>(_ dependencyType: Dependency.Type, factory: @escaping (Resolver) -> Dependency) {
        container.register(dependencyType, factory: factory)
    }
    
    func resolve<Dependency>(_ dependencyType: Dependency.Type) -> Dependency? {
        return container.resolve(dependencyType)
    }
}
