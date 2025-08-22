//
//  SubmitFeedbackObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 25-05-2025.
//

import Foundation
import Combine

final class SubmitFeedbackObservable: ObservableObject {
    
    @Published var comments: String = ""
    @Published var emojiText: String = ""
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    func handleSubmitFeedback() {
        
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else { return }

        let requestBody = SubmitFeedbackRequest(
            comments: comments,
            emojiText: emojiText
        )
        
        let publisher: AnyPublisher<FeedbackResponse, APIError> = apiService.genericPostPublisher(
            toURLString: URLBuilderConstants.URLBuilder(type: .submitFeedback),
            requestBody: requestBody,
            isAuthNeeded: true
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        self.showToast = true
                        self.toastMessage = error.localizedDescription
                        print("Error: \(error.localizedDescription)")
                }
                Loader.shared.stopLoading()
            }, receiveValue: { [weak self] response in
                self?.showToast = true
                self?.toastMessage = response.message
            })
            .store(in: &cancellables)
    }
}
