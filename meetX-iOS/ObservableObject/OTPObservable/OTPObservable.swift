//
//  OTPObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 22-03-2025.
//

import SwiftUI
import Combine

// MARK: - OTP Observable Class
class OTPObservable: ObservableObject {
    
    // MARK: - Published Properties
    @Published var otp: [String] = Array(repeating: "", count: 6)
    @Published var showErrorToast: Bool = false
    @Published var isNeedSupportOverlayShown: Bool = false
    @Published var canResendOTP: Bool = false
    @Published var resendSecondsLeft: Int = 30
    @Published var apiErrors: [APIError] = []
    
    // MARK: - Dependencies
    private let routeManager = RouteManager.shared
    private let permissionHelper = PermissionHelper()
    private let apiService: ApiServiceMapper?
    private let userDataManager: UserDataManager
    private let navigationHandler: NavigationHandler
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    // MARK: - Properties
    let mobileNumber: String
    private let resendTimerDuration: Int = 30
    private let otpLength: Int = 6
    
    // MARK: - Initialization
    init(
        mobileNumber: String,
         apiService: ApiServiceMapper? = SwiftInjectDI.shared.resolve(ApiServiceMapper.self),
         userDataManager: UserDataManager = UserDataManager.shared,
         navigationHandler: NavigationHandler = NavigationHandler()
    ) {
        self.mobileNumber = mobileNumber
        self.apiService = apiService
        self.userDataManager = userDataManager
        self.navigationHandler = navigationHandler
        startResendTimer()
    }
    
    deinit {
        invalidateTimer()
    }
}

// MARK: - OTP Input Handling
extension OTPObservable {
    
    func handleOTPChange(at index: Int, newValue: String) {
        guard index >= 0 && index < otp.count else { return }
        
        // Only allow single digit input
        if newValue.count > 1 {
            otp[index] = String(newValue.prefix(1))
        } else {
            otp[index] = newValue
        }
        
        if showErrorToast {
            showErrorToast = false
        }
    }
    
    private var isOTPValid: Bool {
        let joinedOTP = otp.joined()
        return !joinedOTP.isEmpty && joinedOTP.count == otpLength
    }
}

// MARK: - OTP Verification
extension OTPObservable {
    
    func verifyOTP() {
        guard isOTPValid else {
            apiErrors.append(.apiFailed(underlyingError: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Please, enter valid OTP"])))
            showErrorToast = true
            return
        }
        
        Loader.shared.startLoading()
        
        makeOTPVerificationRequest()
    }
    
    private func makeOTPVerificationRequest() {
        guard let apiService = apiService else {
            apiErrors.append(.apiFailed(underlyingError: nil))
            showErrorToast = true
            Loader.shared.stopLoading()
            return
        }
        
        let requestBody = OTPVerificationRequest(
            mobileNumber: mobileNumber,
            otp: otp.joined()
        )
        
        apiService.genericPostPublisher(
            toURLString: URLBuilderConstants.URLBuilder(type: .loginSignup),
            requestBody: requestBody,
            isAuthNeeded: false
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            guard let self = self else { return }
            
            Loader.shared.stopLoading()
            
            if case let .failure(error) = completion {
                self.apiErrors.append(error)
                self.showErrorToast = true
            }
        } receiveValue: { [weak self] response in
            self?.handleOTPVerificationResult(response)
        }
        .store(in: &cancellables)
    }

    
    private func handleOTPVerificationResult(_ response : OTPVerificationResponse) {
        Loader.shared.stopLoading()
        
        switch response.success {
            case true:
                handleSuccessfulVerification(response)
                
            case false,.none,.some(_):
                handleVerificationError(.apiFailed(underlyingError: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: response.message ?? "Something went wrong, please try again later."])))
        }
    }
    
    private func handleSuccessfulVerification(_ response: OTPVerificationResponse) {
        userDataManager.clearAllUserData { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.storeUserData(response)
                    self?.navigateAfterLogin(response)
                } else {
                    self?.apiErrors.append(.apiFailed(underlyingError: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: response.message ?? "Something went wrong, please try again later."])))
                    self?.showErrorToast = true
                }
            }
        }
    }
    
    private func handleVerificationError(_ error: APIError) {
        apiErrors.append(error)
        showErrorToast = true
    }
}

// MARK: - User Data Management
extension OTPObservable {
    
    @discardableResult
    private func storeUserData(_ response: OTPVerificationResponse) -> Bool {
        // Validate required fields
        guard
            let token = response.token,
            let mobileNumber = response.user?.mobileNumber,
            let userId = response.user?.userId
        else {
            return false
        }
        
        // Store secure user data
        let isStored = userDataManager.storeSecureUserData(
            token: token,
            mobileNumber: mobileNumber,
            userId: userId,
            userName: response.user?.username ?? "",
            userDisplayName: response.user?.name ?? "",
            userProfilePicture: response.user?.profilePicUrls?.first ?? "",
            requiresProfileCompletion: response.requiresProfileCompletion ?? false, userGender: response.user?.gender ?? ""
        )
        
        // Store non-sensitive UI preferences
        if let username = response.user?.username {
            userDataManager.storeUserPreferences(username: username)
        }

        // Use current location at each login
        LocationStorage.isUsingCurrentLocation = true

        return isStored
    }

    private func navigateAfterLogin(_ response: OTPVerificationResponse) {
        navigationHandler.navigateAfterLogin(
            requiresProfileCompletion: response.requiresProfileCompletion ?? false,
            permissionHelper: permissionHelper,
            routeManager: routeManager
        )
    }
}

// MARK: - Resend OTP
extension OTPObservable {
    
    func resendOTP() {
        guard canResendOTP else { return }
        
        otp = Array(repeating: "", count: otpLength)
        
        resetResendTimer()
        
        makeLoginSignupcall(mobileNumber) { [weak self] in
            DispatchQueue.main.async {
                self?.apiErrors.append(.apiFailed(underlyingError: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "OTP Sent Successfully"])))
                self?.showErrorToast = true
            }
        } failure: { [weak self] _ in
            DispatchQueue.main.async {
                self?.apiErrors.append(.apiFailed(underlyingError: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Something went wrong, please try again later."])))
                self?.showErrorToast = true
            }
        }
    }
    
    private func resetResendTimer() {
        canResendOTP = false
        resendSecondsLeft = resendTimerDuration
        startResendTimer()
    }
    
    func startResendTimer() {
        invalidateTimer()
        canResendOTP = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func updateTimer() {
        if resendSecondsLeft > 0 {
            resendSecondsLeft -= 1
        } else {
            canResendOTP = true
            invalidateTimer()
        }
    }
    
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func makeLoginSignupcall(_ mobileNumber : String,
                             completion: @escaping () -> Void,
                             failure: @escaping (Error) -> Void) {
        Loader.shared.startLoading()
        
        print("REACHED 1")
        let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self)
        
        let requestBody = LoginSignupRequest(
            mobileNumber: mobileNumber,
            countryCode: DeveloperConstants.LoginRegister.indiaCountryCode,
            enableSmsOTP: true
        )
        print("REACHED 2 \(requestBody)")
        
        apiService?.genericPostPublisher(
            toURLString: URLBuilderConstants.URLBuilder(type: .loginSignup),
            requestBody: requestBody,
            isAuthNeeded: false)
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            guard let self = self else { return }
            switch completion {
                case let .failure(error):
                    print("REACHED 3 \(error)")
                    self.apiErrors.append(error)
                    failure(error)
                case .finished:
                    break
            }
            Loader.shared.stopLoading()
        }, receiveValue: { [weak self] (response: LoginSignUpResponse) in
            guard let _ = self else { return }
            print("REACHED 4 \(response)")
            completion()
        })
        .store(in: &cancellables)
    }
}

// MARK: - Navigation Handler
class NavigationHandler {
    
    func navigateAfterLogin(requiresProfileCompletion: Bool,
                            permissionHelper: PermissionHelper,
                            routeManager: RouteManager) {
        if requiresProfileCompletion {
            routeManager.navigate(to: ProfileUpdationScene())
        } else if permissionHelper.checkPermissionsHandlerSyncLogin().isEmpty {
            routeManager.navigate(to: HomePageRoute())
        } else {
            routeManager.navigate(to: PermissionStepScene())
        }
    }
}
