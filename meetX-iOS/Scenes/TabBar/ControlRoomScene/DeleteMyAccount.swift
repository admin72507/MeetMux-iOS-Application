//
//  DeleteMyAccount.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 06-04-2025.
//

import SwiftUI

struct DeleteAccountView: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var showConfirmation = false
    @StateObject private var viewModel: DeleteMyAccountObservable = .init()
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "trash")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.red)
                .frame(width: 100, height: 100)
            
            Text("Permanently Delete / Deactivate Account")
                .fontStyle(size: 18, weight: .semibold)
            
            Text(makeAttributedText())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Spacer()
            
            Button(role: .destructive) {
                showConfirmation = true
                viewModel.actionType = .delete
            } label: {
                Text("Delete My Account")
                    .fontStyle(size: 16, weight: .semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Button(role: .none) {
                showConfirmation = true
                viewModel.actionType = .deactivate
            } label: {
                Text("Deactivate My Account")
                    .fontStyle(size: 16, weight: .semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.5))
                    .foregroundColor(ThemeManager.foregroundColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
        .confirmationDialog(
            "Are you absolutely sure?",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button(viewModel.actionType == .deactivate
                   ? "Yes, Deactivate my account"
                   : "Yes, Delete my account",
                   role: .destructive
            ) {
                // Handle API call
                Loader.shared.startLoading()
                viewModel.handleDeleteAccount()
            }
            Button(Constants.cancelText, role: .cancel) { }
        }
    }
    
    func makeAttributedText() -> AttributedString {
        var attributed = AttributedString("We're sorry to see you go.\n")
        attributed.font = .system(size: 16, weight: .regular)
        attributed.foregroundColor = .gray
        
        var point1 = AttributedString("\n1. Deleting your account is permanent and cannot be undone. Your data will be removed from our servers.\n")
        point1.font = .system(size: 16, weight: .light)
        point1.foregroundColor = .primary
        
        var point2 = AttributedString("2. Deactivating your account will keep your data on our servers for a limited period of time, allowing you to continue using meetmux in the future.")
        point2.font = .system(size: 16, weight: .light)
        point2.foregroundColor = .primary
        
        return attributed + point1 + point2
    }
}
