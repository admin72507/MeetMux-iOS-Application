//
//  NeedSupportObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 23-03-2025.
//

import SwiftUI
import Combine

class NeedSupportViewModel: ObservableObject {
    @Published var mobileNumber: String             = ""
    @Published var selectedIssue: String            = ""
    @Published var requestDetails: String           = ""
    @Published var showError: Bool                  = false
    @Published var showApiError: Bool               = false
    @Published var errorMessage: String             = ""
    var helperFunction                              = HelperFunctions()
    var apiErrors: [APIError] = []
    private var cancellables = Set<AnyCancellable>()
    
    func submitRequest() {
        guard !mobileNumber.isEmpty,
              mobileNumber.count == 10,
              !selectedIssue.isEmpty else {
            showError = true
            errorMessage = Constants.errorMessageSupport
            return
        }
        
        Loader.shared.startLoading()
        makeSupportAPICall(completion: { [weak self] responseModel in
            self?.showApiError = true
            self?.errorMessage = responseModel.message
            self?.mobileNumber = ""
            self?.selectedIssue = ""
            self?.requestDetails = ""
        }, failure: { [weak self] error in
            self?.showApiError = true
            self?.errorMessage = error.localizedDescription
        })
    }
    
    func sendEmail() {
        let email = DeveloperConstants.General.supportEmail
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
    
    func callSupport() {
        let phoneNumber = DeveloperConstants.General.supportMobileNumber.replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "tel://\(phoneNumber)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Hitting support API
    func makeSupportAPICall(completion: @escaping (NeedSupportResponse) -> Void,
                            failure: @escaping (Error) -> Void) {
            let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self)
            
            let requestBody = SupportRequest(
                mobileNumber: mobileNumber,
                issue: selectedIssue,
                details: requestDetails
            )
            
            apiService?.genericPostPublisher(
                toURLString: URLBuilderConstants.URLBuilder(type: .needSupport),
                requestBody: requestBody,
                isAuthNeeded: false)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                    case let .failure(error):
                        self.apiErrors.append(error)
                        failure(error)
                    case .finished:
                        break
                }
                Loader.shared.stopLoading()
            }, receiveValue: { [weak self] (response: NeedSupportResponse) in
                guard let _ = self else { return }
                completion(response)
            })
            .store(in: &cancellables)
    }
}
