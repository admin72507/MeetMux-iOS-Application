//
//  NoResultScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 16-02-2025.
//

import SwiftUI

struct EmptyStateView: View {
    let imageName: String
    let message: String
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                .padding(.bottom, 10)
            
            Text(message)
                .fontStyle(size: 12, weight: .light)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

