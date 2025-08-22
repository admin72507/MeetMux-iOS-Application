//
//  GeneralPostModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 19-05-2025.
//

import Foundation

struct PostSection: Identifiable {
    let id = UUID()
    var sectionTitle: String?
    var sectionSubtitle: String?
    var subCategories: [PostSectionList]?
}

struct PostSectionList: Identifiable {
    let id = UUID()
    var icon: String?
    var title: String?
    var subtitle: String?
}
