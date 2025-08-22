//
//  OTPVerifyScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 07-02-2025.
//

import SwiftUI
import AlertToast

struct OTPVerificationView: View {
    
    @StateObject private var viewModel: OTPObservable
    @FocusState private var focusedIndex: Int?
    
    var helperFunction = HelperFunctions()
    
    init(
        mobileNumber: String
    ) {
        _viewModel = StateObject(wrappedValue: OTPObservable(mobileNumber: mobileNumber))
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    RouteManager.shared.goBack()
                }) {
                    Image(systemName: DeveloperConstants.systemImage.backButtonImage)
                        .font(.title2)
                        .foregroundColor(ThemeManager.foregroundColor)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            Image(DeveloperConstants.LoginRegister.logoImageFull)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .opacity(0.8)
                .padding()
            
            Text(Constants.otpTitle)
                .fontStyle(size: 18, weight: .bold)
            Text(Constants.otpSubtitle)
                .foregroundColor(.gray)
                .fontStyle(size: 14, weight: .light)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 5)
            
            Text("\(DeveloperConstants.LoginRegister.indiaCountryCode) \(viewModel.mobileNumber)")
                .fontStyle(size: 16, weight: .semibold)
                .foregroundColor(.primary)
                .padding()
            
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    TextField("", text: Binding<String>(
                        get: { viewModel.otp[index] },
                        set: { newValue in viewModel.otp[index] = newValue }
                    ))
                    .frame(width: 50, height: 50)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($focusedIndex, equals: index)
                    .onChange(of: viewModel.otp[index]) { oldValue, newValue in
                        viewModel.handleOTPChange(at: index, newValue: newValue)
                        
                        if !newValue.isEmpty {
                            focusedIndex = index < 5 ? index + 1 : nil
                        }
                        
                        if newValue.isEmpty && index > 0 {
                            focusedIndex = index - 1
                        }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(style: StrokeStyle(lineWidth: 0.1)))
                }
            }
            .padding(.top, 20)
            
            resendView
            
            Spacer()
            
            Button(action: {
                hideKeyboard()
                viewModel.verifyOTP()
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
        .toast(isPresenting: $viewModel.showErrorToast) {
            helperFunction.apiErrorToastCenter(Constants.toastErrorTitle, viewModel.apiErrors.last?.localizedDescription ?? "")
        }
        .background(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            focusedIndex = nil
            hideKeyboard()
        }
        .sheet(isPresented: Binding<Bool>(
            get: { viewModel.isNeedSupportOverlayShown },
            set: { newValue in viewModel.isNeedSupportOverlayShown = newValue }
        )) {
            NeedSupportScene(retrivedMobileNumber: "")
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedIndex = 0
            }
        }
    }
    
    @ViewBuilder
    var resendView: some View {
        HStack {
            if viewModel.canResendOTP == true {
                Text(Constants.otpResendSubtitle)
                    .fontStyle(size: 12, weight: .light)
                    .foregroundStyle(ThemeManager.foregroundColor)
                Button(action: {
                    viewModel.resendOTP()
                }) {
                    Text(Constants.otpResendTitle)
                        .fontStyle(size: 14, weight: .semibold)
                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                }
            } else {
                Text("\(Constants.resendOTP) \(viewModel.resendSecondsLeft)s")
                    .fontStyle(size: 14, weight: .semibold)
                    .foregroundColor(.gray)
            }
        }
        .padding(.top, 10)
    }
}
