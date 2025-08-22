////
////  ReportChatView.swift
////  meetX-iOS
////
////  Created by Karthick Thavasimuthu on 08-07-2025.
////
//
import SwiftUI
import Combine

struct ReportChatView: View {
    @ObservedObject var viewModel: ChatLandingObservable
    @State private var selectedReason: String = ""
    @State private var descriptionText: String = ""
    @State private var isSubmitting = false
    @FocusState private var isTextEditorFocused: Bool

    let conversation: RecentChat?

    private let reportReasons = [
        "Harassment or bullying",
        "Hate speech or discrimination",
        "Threats or violent behavior",
        "Sexual harassment",
        "Unwanted or inappropriate messages",
        "Nudity or sexual content",
        "Violent or graphic content",
        "Offensive or abusive language",
        "False information or impersonation",
        "Promotion of illegal activities",
        "Spam or repeated messages",
        "Scams or fraudulent behavior",
        "Misleading links or phishing attempts",
        "Advertising or self-promotion",
        "Underage user",
        "Self-harm or suicide concern",
        "Sharing private or personal information without consent",
        "Other (please describe)"
    ]

    // MARK: - Computed Properties

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Report Issue")
                .fontStyle(size: 16, weight: .semibold)
                .foregroundStyle(ThemeManager.foregroundColor)

            Text("Help us keep the community safe")
                .fontStyle(size: 14, weight: .light)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private var reasonSelectionHeader: some View {
        Text("Select a reason")
            .fontStyle(size: 16, weight: .semibold)
            .foregroundStyle(ThemeManager.foregroundColor)
            .padding(.horizontal)
    }

    private var reasonGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            reasonButtons
        }
        .padding(.horizontal)
    }

    private var reasonSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            reasonSelectionHeader
            reasonGrid
        }
    }

    private var reasonButtons: some View {
        ForEach(reportReasons, id: \.self) { reason in
            ReasonButton(
                reason: reason,
                isSelected: selectedReason == reason,
                action: {
                    selectedReason = reason
                }
            )
        }
    }

    private var descriptionHeader: some View {
        Text("Additional details (optional)")
            .fontStyle(size: 16, weight: .semibold)
            .foregroundStyle(ThemeManager.foregroundColor)
            .padding(.horizontal)
    }

    private var textEditorPlaceholder: some View {
        Group {
            if descriptionText.isEmpty && !isTextEditorFocused {
                Text("Provide more context about the issue...")
                    .fontStyle(size: 14, weight: .light)
                    .foregroundStyle(.gray)
                    .padding(.top, 8)
                    .padding(.leading, 4)
            }
        }
    }

    private var textEditor: some View {
        TextEditor(text: $descriptionText)
            .focused($isTextEditorFocused)
            .padding()
            .frame(height: 100)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .overlay(
                textEditorPlaceholder,
                alignment: .topLeading
            )
            .padding(.horizontal)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            descriptionHeader
            textEditor
        }
    }

    private var submitButtonContent: some View {
        HStack {
            if isSubmitting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("Submit Report")
                    .fontWeight(.semibold)
            }
        }
    }

    private var submitButtonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                selectedReason.isEmpty || isSubmitting
                ? LinearGradient(
                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                : ThemeManager.gradientNewPinkBackground
            )
    }

    private var submitButton: some View {
        Button(action: submitReport) {
            submitButtonContent
                .frame(maxWidth: .infinity)
                .padding()
                .background(submitButtonBackground)
                .foregroundColor(.white)
        }
        .disabled(selectedReason.isEmpty || isSubmitting)
        .padding(.horizontal)
    }

    private var mainContent: some View {
        VStack(spacing: 24) {
            headerSection
            reasonSelectionSection
            descriptionSection
            submitButton
        }
        .padding(.top)
    }

    private var scrollableContent: some View {
        ScrollView {
            mainContent
        }
    }

    private var backgroundView: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
            .onTapGesture {
                isTextEditorFocused = false
            }
    }

    private var navigationToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                viewModel.showReportChatModal.toggle()
            }
        }
    }

    var body: some View {
        ZStack {
            backgroundView
            scrollableContent
        }
    }

    // MARK: - Private Methods

    private func submitReport() {
        guard let conversation = conversation else { return }
        isSubmitting = true
        isTextEditorFocused = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isSubmitting = false
            viewModel.reportChatConversation(
                conversation,
                reportReason: selectedReason,
                reportDescription: descriptionText
            ) {
                viewModel.showReportChatModal.toggle()
            }
        }
    }
}

// MARK: - ReasonButton

struct ReasonButton: View {
    let reason: String
    let isSelected: Bool
    let action: () -> Void

    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                isSelected
                ? ThemeManager.gradientNewPinkBackground
                : LinearGradient(
                    colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var buttonOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(isSelected ?
                    Color.clear :
                        Color(.systemGray4), lineWidth: 1)
    }

    private var buttonContent: some View {
        Text(reason)
            .font(.system(size: 14))
            .multilineTextAlignment(.center)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
    }

    var body: some View {
        Button(action: action) {
            buttonContent
                .background(buttonBackground)
                .overlay(buttonOverlay)
        }
    }
}
