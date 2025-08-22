//
//  LoginViewModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 07-02-2025.
//

import SwiftUI
import Combine

class LoginObservable: ObservableObject {
    @Published var apiErrors: [APIError] = []
    @Published var showErrorToast: Bool = false
    let routeManager = RouteManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    func validatePhoneNumber(_ phoneNumber: String, _ isChecked: Bool) -> (Bool, String?, String?) {
        if phoneNumber.count != 10 {
            return (false, Constants.phoneNumberError, Constants.genericTitleError)
        }
        if !isChecked {
            return (false, Constants.isTermsCondition, Constants.genericTitleError)
        }
        return (true, nil, nil)
    }
    
    // MARK: - Login SignUp Call
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

