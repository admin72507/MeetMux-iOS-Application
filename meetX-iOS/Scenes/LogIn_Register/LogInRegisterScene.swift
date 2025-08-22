//
//  LogInScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-12-2024.
//

import SwiftUI
import AlertToast
import Combine

struct LogInRegisterScene: View {
    
    @State private var phoneNumber: String              = ""
    @State private var isChecked                        = false
    @State private var isNeedHelpTapped                 = false
    @State private var showErrorToast                   = false
    @StateObject private var keyboardResponder          = KeyboardHelper()
    @StateObject private var loginViewModel             = LoginObservable()
    var helperFunction                                  = HelperFunctions()
    
    @ViewBuilder
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading) {
                    
                    LogoImagesView(edgeInsets: geometry.safeAreaInsets)
                    
                    TitleSubTitle()
                    
                    PhoneNumberTextField(phoneNumber: $phoneNumber)
                    
                    VStack(alignment: .center) {
                        TermsAndConditionsView(isChecked: $isChecked)
                            .padding(.top)
                        
                        ContinueButton(
                            phoneNumber: $phoneNumber,
                            isChecked: $isChecked,
                            showErrorToast: $showErrorToast,
                            loginViewModel: loginViewModel
                        )
                        
                        NeedHelpView {
                            isNeedHelpTapped.toggle()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: geometry.size.height)
            }
        }
        .scrollIndicators(.hidden)
        .toast(isPresenting: $showErrorToast) {
            helperFunction.apiErrorToastCenter(
                loginViewModel.validatePhoneNumber(phoneNumber, isChecked).2 ?? "",
                loginViewModel.validatePhoneNumber(phoneNumber, isChecked).1 ?? ""
            )
        }
        .onTapGesture {
            hideKeyboard()
        }
        .safeAreaInset(edge: .bottom) {
            Spacer().frame(
                height: keyboardResponder.keyboardHeight + (keyboardResponder.keyboardHeight > 0 ? 50 : 0))
        }
        .sheet(isPresented: $isNeedHelpTapped) {
            NeedSupportScene(retrivedMobileNumber: "")
                .presentationDragIndicator(.visible)
        }
        .toast(isPresenting: $loginViewModel.showErrorToast) {
            helperFunction.apiErrorToastCenter(
                Constants.apiLoginFailed,
                loginViewModel.apiErrors.first?.localizedDescription ?? "")
        }
    }
}

// MARK: - Logo Images View
struct LogoImagesView: View {

    var edgeInsets: EdgeInsets
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var keyboardObserver = KeyboardObserver()
    let loginAnimations = DeveloperConstants.loginAnimations.randomElement()

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Logo - Fixed size, won't shrink
            Image(DeveloperConstants.LoginRegister.logoImageFull)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding(.top, 20)

            // Animation - Flexible but with minimum constraints
            LottieLoginRegisterLocalFileView(
                animationName: loginAnimations ?? "MenWomen",
                hasNotch: HelperFunctions.hasNotch(in: edgeInsets)
            )
            .frame(
                maxWidth: .infinity,
                minHeight: keyboardObserver.isKeyboardVisible ? 150 : 200,
                maxHeight: .infinity
            )
            .padding(.horizontal, 20)
            .animation(.easeInOut(duration: 0.3), value: keyboardObserver.isKeyboardVisible)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var selectedThemeImage: String {
        colorScheme == .dark
        ? DeveloperConstants.LoginRegister.conservativeBlackImage
        : DeveloperConstants.LoginRegister.conservativeImage
    }
}

// MARK: - Title & Subtitle View
struct TitleSubTitle: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Constants.loginTitle)
                .fontStyle(size: 18, weight: .semibold)
            
            Text(Constants.loginSubtitle)
                .fontStyle(size: 12, weight: .light)
                .foregroundColor(.primary)
        }
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 16)
    }
}

// MARK: - Phone Number Text Field
struct PhoneNumberTextField: View {
    
    @Binding var phoneNumber: String
    @State private var isCountryPickerVisible = false
    @State private var selectedCountry = PickerOption(value: "+91", displayText: "+91")
    
    var body: some View {
        HStack {
            GenericPickerMenu(
                isVisible: $isCountryPickerVisible,
                selectedOption: $selectedCountry,
                listDetails: DeveloperConstants.MenuOptions.countryOptions
            )
            
            Rectangle()
                .frame(width: 1, height: 25)
                .foregroundColor(.gray.opacity(0.5))
            
            TextField(Constants.placeHolderText, text: $phoneNumber)
                .keyboardType(.numberPad)
                .padding()
                .fontStyle(size: 14, weight: .light)
                .foregroundColor(ThemeManager.foregroundColor)
                .onChange(of: phoneNumber) { oldValue, newValue in
                    phoneNumber = newValue.filter { $0.isNumber }
                    if phoneNumber.count > 10 {
                        phoneNumber = String(phoneNumber.prefix(10))
                    }
                }
        }
        .background(Color.white.opacity(0.2))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
        .padding(.horizontal, 16)
    }
}

// MARK: - Terms and Conditions View
struct TermsAndConditionsView: View {
    
    @Binding var isChecked: Bool
    @State private var showEffect = false
    @State private var showWebView = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: {
                isChecked.toggle()
                showEffect = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showEffect = false
                }
            }) {
                Image(
                    systemName: isChecked ? DeveloperConstants.systemImage.checkMarkImageFill : DeveloperConstants.systemImage.checkMarkImage)
                .resizable()
                .frame(width: 25, height: 25)
                .foregroundColor(isChecked ? ThemeManager.staticPurpleColour : .gray)
                .symbolEffect(showEffect ? .rotate.clockwise.byLayer : .rotate.counterClockwise.byLayer, options: .nonRepeating)
            }
            Text(Constants.acceptText)
                .foregroundColor(.primary)
                .fontStyle(size: 12, weight: .light)
            
            Button(action : {
                showWebView = true
            }) {
                Text(Constants.termsConditiontext)
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                    .fontStyle(size: 12, weight: .semibold)
            }
            .sheet(isPresented: $showWebView) {
                SafariView(url:
                            URL(
                                string: DeveloperConstants.BaseURL.termsAndConditionsURL
                            )!
                )
            }
        }
    }
}

// MARK: - Continue Button View
struct ContinueButton: View {
    @Binding var phoneNumber: String
    @Binding var isChecked: Bool
    @Binding var showErrorToast: Bool
    @ObservedObject var loginViewModel: LoginObservable
    
    var body: some View {
        Button(action: {
            let (isValid, _, _) = loginViewModel.validatePhoneNumber(phoneNumber, isChecked)
            showErrorToast = !isValid ? true : false
            if showErrorToast == false {
                hideKeyboard()
                Loader.shared.startLoading()
                loginViewModel.makeLoginSignupcall(
                    phoneNumber) {
                        loginViewModel.routeManager.navigate(to: OTPVerificationScene(mobileNumber: phoneNumber))
                    } failure: {_ in
                        loginViewModel.showErrorToast = true
                    }
            }
        }) {
            Text(Constants.continueText)
                .applyCustomButtonStyle()
        }
        .shadow(radius: 5)
        .pressEffect()
    }
}

struct LogoImagesView_Previews: PreviewProvider {
    static var previews: some View {
        LogoImagesView(edgeInsets: EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
            .previewLayout(.sizeThatFits)
            .background(Color.black)
    }
}

struct LottieLoaderView_Previews: PreviewProvider {
    static var previews: some View {
        LottieLoaderView(webURL: "https://lottie.host/336f9b38-560f-4d6b-8927-b5347944ff64/FGIyuxOfwt.lottie")
            .frame(width: 300, height: 300)
            .background(Color.black)
    }
}

// MARK: - Keyboard Observer
class KeyboardObserver: ObservableObject {
    @Published var isKeyboardVisible = false
    @Published var keyboardHeight: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Keyboard will show
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
            }
            .sink { [weak self] height in
                DispatchQueue.main.async {
                    self?.keyboardHeight = height
                    self?.isKeyboardVisible = true
                }
            }
            .store(in: &cancellables)

        // Keyboard will hide
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.keyboardHeight = 0
                    self?.isKeyboardVisible = false
                }
            }
            .store(in: &cancellables)
    }
}
