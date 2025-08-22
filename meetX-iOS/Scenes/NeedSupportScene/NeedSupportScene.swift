//
//  NeedSupportScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 18-02-2025.
//

import SwiftUI
import AlertToast

struct NeedSupportScene: View {
    
    @ObservedObject private var viewModel = NeedSupportViewModel()
    @StateObject private var keyboardManager = KeyboardManager()
    @State private var isPickerPresented = false
    
    let retrivedMobileNumber: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            
            headerView
                .padding()
            
            Form {
                inputSection(title: Constants.mobileNumberTitle,
                             subtitle: Constants.mobileNumberSubTitle) {
                    
                    TextField(Constants.placeHolderText, text: $viewModel.mobileNumber)
                        .keyboardType(.phonePad)
                        .styledTextFieldSupport()
                        .fontStyle(size: 12, weight: .regular)
                        .onChange(of: viewModel.mobileNumber) { oldValue, newValue in
                            viewModel.mobileNumber = newValue.filter { $0.isNumber }
                            if viewModel.mobileNumber.count > 10 {
                                viewModel.mobileNumber = String(viewModel.mobileNumber.prefix(10))
                            }
                        }
                }
                
                inputSection(title: Constants.selectYourIssuetitle,
                             subtitle: Constants.selectYourIssueSubTitle) {
                    Menu {
                        ForEach(
                            retrivedMobileNumber == "" ? Constants.issues : Constants.reportIssues,
                            id: \.self
                        ) { issue in
                            Button(action: { viewModel.selectedIssue = issue }) {
                                HStack {
                                    Text(issue)
                                    if viewModel.selectedIssue == issue {
                                        Image(systemName: DeveloperConstants.systemImage.checkMark)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedIssue.isEmpty ? Constants.selectAnIssueTitle : viewModel.selectedIssue)
                                .foregroundColor(viewModel.selectedIssue.isEmpty ? .gray : .primary)
                            Spacer()
                            Image(systemName: DeveloperConstants.systemImage.downArrowImage)
                                .foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .frame(height: 45)
                        .fontStyle(size: 12, weight: .regular)
                    }
                }
                
                inputSection(title: Constants.additionalDetails,
                             subtitle: Constants.additionInformationText) {
                    TextField(Constants.describeRequest, text: $viewModel.requestDetails)
                        .styledTextFieldSupport()
                        .fontStyle(size: 12, weight: .regular)
                }
            }
            .onAppear {
                if let mobileNumber = retrivedMobileNumber {
                    viewModel.mobileNumber = mobileNumber
                }
            }
            .scrollContentBackground(.hidden)
            
            Spacer()
            
            if !keyboardManager.isKeyboardVisible {
                footerView
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: keyboardManager.isKeyboardVisible)
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .toast(isPresenting: $viewModel.showError) {
            viewModel.helperFunction.toastAtTopError(Constants.genericTitleError, Constants.errorMessageSupport)
        }
        .toast(isPresenting: $viewModel.showApiError) {
            viewModel.helperFunction.apiErrorToastCenter(Constants.submitSupportTitle, viewModel.errorMessage)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Text(Constants.contactSupportHeading)
                .fontStyle(size: 18, weight: .semibold)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text(Constants.needHelpToSubTitle)
                .fontStyle(size: 14, weight: .light)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    // MARK: - Footer View
    
    private var footerView: some View {
        VStack(spacing: 16) {
            Label {
                Button(action: viewModel.callSupport) {
                    Text(DeveloperConstants.General.supportMobileNumber)
                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        .fontStyle(size: 12, weight: .semibold)
                }
            } icon: {
                Image(systemName: DeveloperConstants.systemImage.phoneImage)
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
            }
            
            Label {
                Button(action: viewModel.sendEmail) {
                    Text(Constants.sendEmailToSupport)
                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        .fontStyle(size: 12, weight: .semibold)
                }
            } icon: {
                Image(systemName: DeveloperConstants.systemImage.paperPlaneImage)
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
            }
            
            Button(action: viewModel.submitRequest) {
                Text(Constants.submitRequest)
                    .applyCustomButtonStyle()
                    .pressEffect()
            }
        }
    }
    
    // MARK: - Input Section
    
    private func inputSection<Content: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Section(header: VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .fontStyle(size: 14, weight: .semibold)
                .foregroundStyle(ThemeManager.foregroundColor)
                .textCase(.none)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .fontStyle(size: 12, weight: .regular)
                    .foregroundColor(.gray)
                    .textCase(.none)
            }
        }) {
            content()
        }
    }
}
