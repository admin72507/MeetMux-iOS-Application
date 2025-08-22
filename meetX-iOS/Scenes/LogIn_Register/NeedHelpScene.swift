//
//  NeedHelpScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 17-02-2025.
//

import SwiftUI

struct NeedHelpView: View {
    var action: () -> Void
    
    var body: some View {
        HStack {
            Text(Constants.needHelp)
                .foregroundColor(.primary)
                .fontStyle(size: 12, weight: .light)
            
            Button(action: action) {
                HStack {
                    Text(Constants.connectText)
                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        .fontStyle(size: 12, weight: .semibold)
                    
                    Image(systemName: DeveloperConstants.systemImage.connectSpotlightImage)
                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        .font(.system(size: 12))
                }
            }
        }
        .padding(.top, 10)
    }
}
