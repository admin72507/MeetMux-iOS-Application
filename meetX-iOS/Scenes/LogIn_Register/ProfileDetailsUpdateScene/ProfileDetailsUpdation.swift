//
//  ProfileDetailsUpdation.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 08-02-2025.
//

import SwiftUI
import PhotosUI
import AlertToast

struct ProfileDetailsUpdation: View {
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel                  = ProfileDetailViewModel()
    @StateObject private var keyboardResponder          = KeyboardHelper()
    @State private var isSupportScreenShown             = false
    var helperFunction                                  = HelperFunctions()
    var navigationFromAppCordinator                     : Bool? = false
    
    @ViewBuilder
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        ThemeManager.backgroundColor.edgesIgnoringSafeArea(.top)
                        
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 20) {
                                UploadProfilePicView(selectedImages: $viewModel.selectedImages)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .environmentObject(viewModel)
                                
                                VideoVerificationView()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .environmentObject(viewModel)
                                
                                PersonalDetailsScene(
                                    selectedGender: $viewModel.selectedGender,
                                    username: $viewModel.username,
                                    bioText: $viewModel.bioText,
                                    emailAddress: $viewModel.emailAddress,
                                    formattedDate: $viewModel.formattedDate,
                                    fromEditProfile: false,
                                    helperFunctions: helperFunction
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .environmentObject(keyboardResponder)
                                
                                ActivityScene(
                                    returnSelectedSubCategories: viewModel.selectedSubCategories,
                                    onDataReceived: { viewModel.selectedSubCategories = $0 },
                                    profileUpdationViewModel: viewModel
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ProfessionScene(viewModel: viewModel)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .hidden()
                            }
                            .padding()
                        }
                        .customNavigationBar(
                            title: Constants.updateProfileTitle,
                            backButtonHidden: navigationFromAppCordinator ?? false
                        ) {
                            navigationFromAppCordinator ?? false ? viewModel.routeManager.navigate(to: LoginRegister()) : presentationMode.wrappedValue.dismiss()
                        }
                        
                        VStack {
                            ThemeManager.backgroundColor
                                .frame(height: HelperFunctions.hasNotch(in: geometry.safeAreaInsets) ? 98 : 64)
                                .shadow(color: ThemeManager.staticPurpleColour.opacity(0.1), radius: 2, x: 0, y: 2)
                                .edgesIgnoringSafeArea(.top)
                            Spacer()
                        }
                    }
                    
                    VStack {
                        Button(action: {
                            hideKeyboard()
                            viewModel.validateAndProceed { isValid in
                                if isValid {
                                    Loader.shared.startLoading()
                                    viewModel.saveTheProfileDetails()
                                }
                            }
                        }) {
                            Text(Constants.saveButtonText)
                                .applyCustomButtonStyle()
                        }
                        .padding(.bottom, 0)
                        
                        NeedHelpView {
                            isSupportScreenShown.toggle()
                        }
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .toast(isPresenting: Binding<Bool>(
                    get: { !viewModel.errorMessageValidation.isEmpty },
                    set: { if !$0 { viewModel.errorMessageValidation = "" } }
                )) {
                    helperFunction.apiErrorToastCenter(Constants.genericTitleError, viewModel.errorMessageValidation)
                }
                .sheet(isPresented: $isSupportScreenShown) {
                    NeedSupportScene(retrivedMobileNumber: "")
                        .presentationDragIndicator(.visible)
                }
                .toast(isPresenting: $viewModel.showErrorToastActivities) {
                    helperFunction.apiErrorToastCenter(Constants.activitiesFetchingFailed, Constants.apiGeneralError)
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ProfileDetailsUpdation()
}
