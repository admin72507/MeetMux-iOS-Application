//
//  BottomAlert.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 23-02-2025.
//

import SwiftUI

struct BottomSheetAlertView: View {
    @State private var showSheet = false
    
    var body: some View {
        VStack {
            Button("Show Bottom Sheet") {
                showSheet.toggle()
            }
            .padding()
        }
        .sheet(isPresented: $showSheet) {
            BottomSheetContent(
                title: Constants.locationAccessDisabled,
                subtitle: Constants.enableLocationText,
                message: Constants.locationAccessInstructions,
                primaryButtonTitle: Constants.openSettingsText,
                secondaryButtonTitle: "Close",
                primaryAction: openAppSettings,
                secondaryAction: {
                    print("Proceeding to next step...")
                    showSheet = false
                }, hideSecondaryButton: true, showSheet: $showSheet
            )
            .presentationDetents([.fraction(0.35)])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            showSheet.toggle()
        }
    }
}

// MARK: - Reusable Bottom Sheet Component
struct BottomSheetContent: View {
    let title: String
    let subtitle: String?
    let message: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String
    let primaryAction: () -> Void
    let secondaryAction: (() -> Void)?
    let hideSecondaryButton: Bool

    @Binding var showSheet: Bool

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // Title
            Text(title)
                .fontStyle(size: 18, weight: .bold)
                .multilineTextAlignment(.center)

            // Subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .fontStyle(size: 14, weight: .semibold)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            // Message
            Text(message)
                .fontStyle(size: 12, weight: .light)
                .multilineTextAlignment(.center)

            Spacer()

            // Horizontal Buttons
            HStack(spacing: 12) {
                if !hideSecondaryButton {
                    Button(secondaryButtonTitle) {
                        secondaryAction?()
                        showSheet = false
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                    .applyCustomButtonStyle()
                }

                Button(primaryButtonTitle) {
                    primaryAction()
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
                .applyCustomButtonStyle()
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding(.horizontal)
        .onDisappear {
            secondaryAction?()
        }
    }
}


// MARK: - Helper Function to Open Settings
func openAppSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
    }
}

// MARK: - Preview
struct BottomSheetAlertView_Previews: PreviewProvider {
    static var previews: some View {
        BottomSheetAlertView()
    }
}
