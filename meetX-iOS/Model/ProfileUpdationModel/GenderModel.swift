//
//  GenderModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 16-02-2025.
//

struct GenderModel: Identifiable {
    let id: Int
    let name: String
    let icon: String
}

// MARK: - Gender Data
let genderOptions: [GenderModel] = [
    GenderModel(id: 1, name: Constants.menuMale, icon: DeveloperConstants.systemImage.genderMenuMale),
    GenderModel(id: 0, name: Constants.menuFemale, icon: DeveloperConstants.systemImage.genderMenuFemale),
    GenderModel(id: 10, name: Constants.menuOthers, icon: DeveloperConstants.systemImage.genderMenuFemale)
]
