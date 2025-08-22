//
//  SubmitFeedback.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 06-04-2025.
//

import SwiftUI

struct SubmitFeedbackView: View {
    
    @State private var selectedFeedback: String?    = nil
    @State private var additionalComments: String   = ""
    @StateObject private var viewModel: SubmitFeedbackObservable = .init()
    @Environment(\.dismiss) var dismiss
    
    let feedbackOptions: [String] = [
        "👍 I liked it",
        "👎 Not a fan",
        "🤔 Confusing",
        "😂 Funny",
        "😡 Offensive",
        "❤️ Loved it"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            
            // Header
            VStack(spacing: 8) {
                
                Text(DeveloperConstants.playfulFeedbackPrompts.randomElement() ?? "We’d love your feedback!")
                    .fontStyle(size: 14, weight: .regular)
                    .foregroundColor(.gray)
            }
            .multilineTextAlignment(.center)
            
            // Feedback options
            VStack(spacing: 12) {
                ForEach(feedbackOptions, id: \.self) { option in
                    Button(action: {
                        selectedFeedback = option
                    }) {
                        HStack {
                            Text(option)
                                .font(.body)
                                .foregroundStyle(ThemeManager.foregroundColor)
                            Spacer()
                            if selectedFeedback == option {
                                Image(systemName: DeveloperConstants.systemImage.circleImage)
                                    .foregroundColor(ThemeManager.staticPinkColour)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
            }
            
            // Additional Comments
            VStack(alignment: .leading, spacing: 8) {
                Text(Constants.additionalComments)
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                TextEditor(text: $additionalComments)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
            
            Spacer()
            
            Button(action: {
                Loader.shared.startLoading()
                viewModel.emojiText = selectedFeedback ?? ""
                viewModel.comments = additionalComments
                viewModel.handleSubmitFeedback()
                selectedFeedback = ""
                additionalComments = ""
            }) {
                Text(Constants.submitFeedback)
                    .applyCustomButtonStyle()
            }
            .disabled(selectedFeedback == nil)
            
        }
        .onTapGesture {
            hideKeyboard()
        }
        .padding()
        .background(Color(.systemBackground))
        .generalNavBarInControlRoom(
            title: Constants.submitFeedback,
            subtitle: Constants.helpUsImproveText,
            image: DeveloperConstants.systemImage.pencilFill,
            onBacktapped: {
                dismiss()
            })
        .toast(isPresenting: $viewModel.showToast) {
            HelperFunctions().apiErrorToastCenter(
                Constants.submitFeedback,
                viewModel.toastMessage
            )
        }
    }
}

#Preview {
    SubmitFeedbackView()
}
