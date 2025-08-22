//
//  EditProfileScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 06-06-2025.
//
import SwiftUI

struct EditProfileScene: View {
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var keyboardResponder          = KeyboardHelper()
    @State private var isSupportScreenShown             = false
    var helperFunction                                  = HelperFunctions()
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel: EditProfileObservable
    @StateObject private var viewModelProfile = ProfileDetailViewModel()
    
    init(viewModel : EditProfileObservable) {
        self.viewModel = viewModel
    }
    
    @ViewBuilder
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 10) {
                    ZStack(alignment: .top) {
                        ThemeManager.backgroundColor.edgesIgnoringSafeArea(.top)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                UploadProfilePicEditProfileScene()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .environmentObject(viewModel)
                                
                                PersonalDetailsScene(
                                    selectedGender: $viewModel.selectedGender,
                                    username: $viewModel.username,
                                    bioText: $viewModel.bioText,
                                    emailAddress: $viewModel.emailAddress,
                                    formattedDate: $viewModel.formattedDate,
                                    fromEditProfile: true, helperFunctions: helperFunction)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .environmentObject(keyboardResponder)
                                
                                ActivityScene(
                                    returnSelectedSubCategories: viewModel.selectedSubCategories,
                                    onDataReceived: { viewModel.selectedSubCategories = $0 },
                                    profileUpdationViewModel: viewModelProfile
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            }
                            .padding()
                        }
                        .generalNavBarInControlRoom(
                            title: "Edit Profile",
                            subtitle: "Make Changes to Your Profile",
                            image: "person.text.rectangle",
                            onBacktapped: {
                                dismiss()
                            }
                        )
                        
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
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .toast(isPresenting: Binding<Bool>(
                    get: { !viewModel.errorMessageValidation.isEmpty },
                    set: { if !$0 { viewModel.errorMessageValidation = "" } }
                )) {
                    helperFunction.toastAtTopError(Constants.genericTitleError, viewModel.errorMessageValidation)
                }
                .sheet(isPresented: $isSupportScreenShown) {
                    NeedSupportScene(retrivedMobileNumber: "")
                        .presentationDragIndicator(.visible)
                }
                .toast(isPresenting: $viewModel.showErrorToastActivities) {
                    helperFunction.apiErrorToastCenter(Constants.activitiesFetchingFailed, Constants.apiGeneralError)
                }
                .toast(isPresenting: $viewModel.showToastErrorMessage) {
                    viewModel.helperFunctions.apiErrorToastCenter(
                        "Edit Profile !!", "Limit Reached, Please remove some and add again"
                    )
                }
                .toast(isPresenting: $viewModel.dismissTheView) {
                    helperFunction.apiErrorToastCenter("Edit Profile!!!", "Profile updated successfully")
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
