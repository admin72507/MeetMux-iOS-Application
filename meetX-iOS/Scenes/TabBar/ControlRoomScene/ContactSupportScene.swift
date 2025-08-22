//
//  ContactSupportScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 15-05-2025.
//

import SwiftUI

struct ContactSupportSheet: View {
    
    @Binding var showSupportOptions: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 20)
            
            Text(Constants.connectText)
                .fontStyle(size: 16, weight: .semibold)
                .multilineTextAlignment(.center)
                .padding(.top)
            
            Text(Constants.hereToHelpYou)
                .fontStyle(size: 14, weight: .light)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                Button(action: {
                    showSupportOptions = false
                    if let phoneURL = URL(string: "tel://\(DeveloperConstants.General.numberWithoutCode)") {
                        if UIApplication.shared.canOpenURL(phoneURL) {
                            UIApplication.shared.open(phoneURL)
                        }
                    }
                }) {
                    Text(DeveloperConstants.General.supportMobileNumber)
                        .fontStyle(size: 14, weight: .semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.gray.opacity(0.1))
                        .cornerRadius(10)
                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                }
                
                // Email Support Button
                Button(action: {
                    showSupportOptions = false
                    if let emailURL = URL(string: "mailto:\(DeveloperConstants.General.supportEmail)") {
                        UIApplication.shared.open(emailURL)
                    }
                }) {
                    Text(DeveloperConstants.General.supportEmail)
                        .fontStyle(size: 14, weight: .semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.gray.opacity(0.1))
                        .cornerRadius(10)
                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .presentationDetents([.height(275)])
    }
}

#Preview {
    ContactSupportSheet(showSupportOptions: .constant(true))
}
