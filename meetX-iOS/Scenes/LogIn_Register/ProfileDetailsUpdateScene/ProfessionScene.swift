//
//  ProfessionScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 11-02-2025.
//
import SwiftUI

struct ProfessionScene: View {
    
    @Environment(\.colorScheme) var deviceTheme
    @State private var moveProfessionalDetailScreen: Bool   = false
    let viewModel                                           : ProfileDetailViewModel
    
    var body: some View {
        Button(action: {
            viewModel.handleNavigationToProfessionScene()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                
                Text(Constants.profesionalDetailsTitle)
                    .fontStyle(size: 14, weight: .semibold)
                    .foregroundColor(ThemeManager.foregroundColor)
                
                HStack(alignment: .top, spacing: 10) {
                    
                    Text(Constants.professionalDesc)
                        .fontStyle(size: 12, weight: .light)
                        .foregroundColor(.gray)
                        .padding(.bottom, 5)
                    
                    Image(systemName: DeveloperConstants.systemImage.chevronRight)
                        .foregroundColor(ThemeManager.staticPurpleColour)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.dynamicBackground(for: deviceTheme))
            .cornerRadius(12)
            .shadow(color: ThemeManager.staticPurpleColour.opacity(0.2), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
