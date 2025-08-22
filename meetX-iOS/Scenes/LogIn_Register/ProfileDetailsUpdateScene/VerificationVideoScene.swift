import SwiftUI
import AVFoundation
import UIKit

struct VideoVerificationView: View {
    
    @EnvironmentObject var viewModel : ProfileDetailViewModel
    @State private var isVerificationPhotoTaken = false
    @State private var showBottomSheet = false
    @State private var showAlertForPermissionDenied = false
    private let helperFunctions = PermissionHelper()
    @State private var isCamera = false
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            VStack(alignment: .leading, spacing: 5) {
                RedAsteriskTextView(title: Constants.photoVerification)
                    .padding(.bottom, 5)
                
                Text(Constants.photoVerificationDesc)
                    .fontStyle(size: 12, weight: .light)
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)
            }
            
            // Display captured image
            if let image = viewModel.capturedImageForVerification {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .cornerRadius(10)
                        .clipped()
                    
                    // Close button
                    Button(action: {
                        viewModel.capturedImageForVerification = nil
                        isVerificationPhotoTaken = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .position(x: UIScreen.main.bounds.width - 60, y: 20)
                }
                .frame(height: 250)
            }
            
            // Action Button
            Button(action: {
                handleCameraTap()
            }) {
                Text(viewModel.capturedImageForVerification == nil ? Constants.openCamera : Constants.retakePhoto)
                    .frame(maxWidth: .infinity)
                    .frame(height: 15)
                    .fontStyle(size: 14, weight: .semibold)
                    .padding()
                    .background(ThemeManager.backgroundColor)
                    .foregroundColor(ThemeManager.foregroundColor)
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(ThemeManager.staticPurpleColour, lineWidth: 1)
                    )
                    .shadow(color: ThemeManager.staticPurpleColour.opacity(0.25), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal)
            
        }
        .fullScreenCover(isPresented: $isCamera) {
            CameraPicker { image in
                viewModel.capturedImageForVerification = image
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    // MARK: - Handlers
    private func handleCameraTap() {
        helperFunctions.requestCameraPermission { isGranted in
            if isGranted {
                isCamera = true
            } else {
                showAlertForPermissionDenied = true
                debugPrint(DeveloperConstants.LoginRegister.permissionCameraDeied)
            }
        }
    }
}
