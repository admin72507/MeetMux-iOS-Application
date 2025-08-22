//
//  EditProfileUploadImage.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 09-06-2025.
//

import SwiftUI
import PhotosUI
import Kingfisher
import AlertToast

//MARK: - Enhanced Upload Profile Pic View
struct UploadProfilePicEditProfileScene: View {
    
    @EnvironmentObject var viewModel: EditProfileObservable
    @State private var isImagePickerPresented = false
    @State private var photoPickerItem: [PhotosPickerItem] = []
    @State private var isCamera = false
    @State private var showBottomSheet = false
    @State private var showAlertForPermissionDenied = false
    private let helperFunctions = PermissionHelper()
    @State private var debounceTask: Task<Void, Never>?
    @State private var isLoading = false
    
    // Computed property for maximum selection count
    private var maxSelectionCount: Int {
        max(1, 5 - viewModel.profileImages.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title & Subtitle
            VStack(alignment: .leading, spacing: 5) {
                Text(Constants.uploadPhotoTitle)
                    .fontStyle(size: 14, weight: .semibold)
                    .padding(.bottom, 5)
                
                Text(Constants.mandatoryPhotoCount)
                    .fontStyle(size: 12, weight: .light)
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)
            }
            
            HStack(spacing: 10) {
                // Add Photo Button
                AddPhotoButtonEditProfile {
                    if viewModel.profileImages.count >= 5 {
                        viewModel.showToastErrorMessage.toggle()
                    } else {
                        showBottomSheet = true
                    }
                }
                .frame(width: 120, height: 170)
                .sheet(isPresented: $showBottomSheet) {
                    AddPhotoBottomSheet(
                        isPresented: $showBottomSheet,
                        title: Constants.uploadProfilePictureText,
                        options: DeveloperConstants.MediaOptions.options(
                            onPhotoLibraryTap: handlePhotoLibraryTap,
                            onCameraTap: handleCameraTap
                        ))
                    .presentationDetents([.height(220)])
                    .ignoresSafeArea(edges: .bottom)
                }
                .alert(Constants.photoAccessDenied, isPresented: $showAlertForPermissionDenied) {
                    Button(Constants.settingsTitle) { helperFunctions.openAppSettings() }
                    Button(Constants.cancelText, role: .cancel) { }
                } message: {
                    Text(Constants.photoDeniedMessage)
                }
                .photosPicker(
                    isPresented: $isImagePickerPresented,
                    selection: $photoPickerItem,
                    maxSelectionCount: maxSelectionCount,
                    matching: .images
                )
                .onChange(of: photoPickerItem) { oldValue, newValue in
                    debounceTask?.cancel()
                    debounceTask = Task {
                        try? await Task.sleep(nanoseconds: DeveloperConstants.LoginRegister.debounceImageTimer)
                        await handlePhotoPickerSelection(oldValue: oldValue, newValue: newValue)
                        
                        // Clear the selection after processing to prevent showing as selected next time
                        await MainActor.run {
                            photoPickerItem = []
                        }
                    }
                }
                .fullScreenCover(isPresented: $isCamera) {
                    CameraPicker { image in
                        // Add image from camera with proper identification
                        viewModel.addImageFromCamera(image)
                    }
                    .edgesIgnoringSafeArea(.all)
                }
                
                // Display Images
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.profileImages) { imageItem in
                            ProfileImageItemView(
                                imageItem: imageItem,
                                isLoading: $isLoading
                            ) {
                                // Remove image by ID
                                viewModel.removeImage(withId: imageItem.id)
                            }
                        }
                    }
                    .frame(height: 190)
                }
            }
            
            // Processing indicator
            if viewModel.isProcessingImages {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing images...")
                        .fontStyle(size: 12, weight: .medium)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 5)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Handlers
    private func handleCameraTap() {
        showBottomSheet = false
        helperFunctions.requestCameraPermission { isGranted in
            if isGranted {
                isCamera = true
            } else {
                showAlertForPermissionDenied = true
                debugPrint(DeveloperConstants.LoginRegister.permissionCameraDeied)
            }
        }
    }
    
    private func handlePhotoLibraryTap() {
        showBottomSheet = false
        
        // Check if we can add more images
        if viewModel.profileImages.count >= 5 {
            viewModel.showToastErrorMessage.toggle()
            return
        }
        
        helperFunctions.requestPhotoPermission { isGranted in
            if isGranted {
                isImagePickerPresented = true
            } else {
                showAlertForPermissionDenied = true
                debugPrint(DeveloperConstants.LoginRegister.permissionDeniedMessage)
            }
        }
    }
    
    @MainActor
    private func handlePhotoPickerSelection(oldValue: [PhotosPickerItem], newValue: [PhotosPickerItem]) async {
        // Only process the new items that weren't in the old selection
        let newItems = newValue.filter { !oldValue.contains($0) }
        
        // Check if adding these new items would exceed the limit
        let totalAfterAddition = viewModel.profileImages.count + newItems.count
        if totalAfterAddition > 5 {
            // Show error message if limit would be exceeded
            viewModel.showToastErrorMessage = true
            return
        }
        
        let loadedImages = await HelperFunctions.loadImageFromPicker(newItems)
        
        // Add each image from gallery with proper identification
        for image in loadedImages {
            viewModel.addImageFromGallery(image)
        }
    }
}

// MARK: - Profile Image Item View
struct ProfileImageItemView: View {
    let imageItem: ProfileImageItem
    @Binding var isLoading: Bool
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                switch imageItem.sourceType {
                    case .existing(let signedUrl, _):
                        // Use KFImage for existing images from URL
                        KFImage(URL(string: signedUrl))
                            .placeholder {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 130, height: 180)
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    )
                            }
                            .retry(maxCount: 3)
                            .fade(duration: 0.25)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                    case .newGallery(let image), .newCamera(let image):
                        // Use regular Image for local UIImages
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: DeveloperConstants.systemImage.closeXmark)
                    .foregroundColor(.white)
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 25, height: 25)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .frame(width: 30, height: 30)
            .offset(x: -5, y: 5)
            
            // Type indicator (for debugging/development)
            if imageItem.isExisting {
                VStack {
                    Spacer()
                    HStack {
                        Text("Existing")
                            .fontStyle(size: 12, weight: .semibold)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(ThemeManager.gradientNewPinkBackground)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        Spacer()
                    }
                }
                .offset(x: 0, y: 0)
            }
        }
    }
}

struct AddPhotoButtonEditProfile: View {
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(uiColor: .systemBackground))
                    .frame(width: 120, height: 170)
                    .shadow(color: colorScheme == .dark ? Color.white.opacity(0.2) : ThemeManager.staticPurpleColour.opacity(0.2), radius: 3, x: 0, y: 0)
                
                
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: DeveloperConstants.systemImage.plusImage)
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(ThemeManager.staticPurpleColour)
                    )
            }
            .frame(width: 110, height: 160)
        }
    }
}
