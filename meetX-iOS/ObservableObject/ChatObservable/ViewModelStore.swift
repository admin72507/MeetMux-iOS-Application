//
//  ViewModelStore.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 12-07-2025.
//

import Combine
import Foundation
import Kingfisher

class ViewModelStore: ObservableObject {
    static let shared = ViewModelStore()

    private var chatLandingObservable: ChatLandingObservable?

    private init() {
        configureImageCache()
    }

    private func configureImageCache() {
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
        cache.memoryStorage.config.countLimit = 100
        cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024
        cache.diskStorage.config.expiration = .days(7)
    }

    func getChatLandingObservable() -> ChatLandingObservable {
        if chatLandingObservable == nil {
            chatLandingObservable = ChatLandingObservable()
        }
        return chatLandingObservable!
    }
}
