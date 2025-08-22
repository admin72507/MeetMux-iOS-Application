//
//  LogOutBottomSheet.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 06-04-2025.
//

import SwiftUI

struct LogoutConfirmationSheet: View {
    
    @Binding var isPresented: Bool
    var onConfirm: () -> Void
    let randomPrompt = logoutPrompts.randomElement()
    
    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
            
            Text(randomPrompt?.title ?? "")
                .fontStyle(size: 16, weight: .semibold)
                .multilineTextAlignment(.center)
                .padding(.top)
            
            Text(randomPrompt?.subtitle ?? "")
                .fontStyle(size: 14, weight: .light)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                Button(action: {
                    isPresented = false
                }) {
                    Text(Constants.cancelText)
                        .fontStyle(size: 14, weight: .medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(10)
                        .foregroundStyle(ThemeManager.foregroundColor)
                }
                
                Button(action: {
                    isPresented = false
                    onConfirm()
                }) {
                    Text(DeveloperConstants.logoutLabelOptions.randomElement() ?? "")
                        .foregroundColor(.white)
                        .fontStyle(size: 14, weight: .medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .presentationDetents([.height(200)])
    }
}
