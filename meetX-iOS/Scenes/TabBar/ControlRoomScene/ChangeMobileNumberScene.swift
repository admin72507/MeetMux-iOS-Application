//
//  ChangeMobileNumber.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 16-05-2025.
//

import SwiftUI
import Combine

struct ChangeMobileNumberScene: View {
    
    @ObservedObject var viewModel: ControlRoomObservable
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Image(DeveloperConstants.LoginRegister.logoImage)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .opacity(0.8)
                .padding()
            
            Text(Constants.changeMobileNumberDescription)
                .foregroundColor(.gray)
                .fontStyle(size: 14, weight: .light)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 5)
            
            Text("\(DeveloperConstants.LoginRegister.indiaCountryCode) \(viewModel.cleanMobileNumberWithCountryCode(viewModel.userDataManager.getSecureUserData().mobileNumber ?? ""))")
                .fontStyle(size: 16, weight: .semibold)
                .foregroundColor(.primary)
                .padding()
            
            PhoneNumberTextField(phoneNumber: $viewModel.collectedNewMobileNumber)
            
            Spacer()
            
            Button(action: {
                viewModel.doubleOTPMobileNumberValidator = true
                hideKeyboard()
            }) {
                Text(Constants.continueText)
                    .applyCustomButtonStyle()
            }
            .pressEffect()
            .padding(.top, 20)
            
            NeedHelpView(action: {
                viewModel.isNeedSupportOverlayShown.toggle()
            })
        }
        .generalNavBarInControlRoom(
            title: Constants.changeMobileNumber,
            subtitle: "Change and verify your mobile number",
            image: "phone.fill",
            onBacktapped: {
                dismiss()
            })
        .sheet(isPresented: $viewModel.isNeedSupportOverlayShown) {
            NeedSupportScene(
                retrivedMobileNumber: (viewModel.cleanMobileNumberWithCountryCode(viewModel.userDataManager.getSecureUserData().mobileNumber ?? "")))
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.doubleOTPMobileNumberValidator) {
            
        }
    }
}
