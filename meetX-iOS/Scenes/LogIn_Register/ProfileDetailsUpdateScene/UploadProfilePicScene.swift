//
//  Section1_UploadProfilePic.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 10-02-2025.
//

import SwiftUI
import PhotosUI

//MARK: - 1. Section 1
///Upload Profile Pic View
struct UploadProfilePicView: View {
    
    @EnvironmentObject var viewModel                            : ProfileDetailViewModel
    @Binding var selectedImages                                 : [UIImage]
    @State private var isImagePickerPresented                   = false
    @State private var photoPickerItem: [PhotosPickerItem]      = []
    @State private var processedPickerItems: Set<String>        = []
    @State private var isCamera                                 = false
    @State private var showBottomSheet                          = false
    @State private var showAlertForPermissionDenied             = false
    private let helperFunctions                                 = PermissionHelper()
    @State private var debounceTask                             : Task<Void, Never>?
    @State private var isLoading                                = false

    private var maxSelectionCount: Int {
        max(1, 5 - selectedImages.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title & Subtitle
            VStack(alignment: .leading, spacing: 5) {
                RedAsteriskTextView(title: Constants.uploadPhotoTitle)
                    .padding(.bottom, 5)
                
                Text(Constants.mandatoryPhotoCount)
                    .fontStyle(size: 12, weight: .light)
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)
            }
            
            HStack(spacing: 10) {
                AddPhotoButton {
                    if selectedImages.count >= 5 {
                        viewModel.errorMessageValidation = Constants.minImagesRequired
                        return
                    }
                    showBottomSheet = true
                }
                .frame(width: 100, height: 120)
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
                    matching: .images,
                    photoLibrary: .shared()
                )
                .onChange(of: photoPickerItem) { oldValue, newValue in
                    debounceTask?.cancel()
                    debounceTask = Task {
                        try? await Task.sleep(nanoseconds: DeveloperConstants.LoginRegister.debounceImageTimer)
                        await handlePhotoPickerSelection(newValue)
                    }
                }
                .fullScreenCover(isPresented: $isCamera) {
                    CameraPicker { image in
                        selectedImages.append(image)
                    }
                    .edgesIgnoringSafeArea(.all)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            SelectedImageView(image: image) {
                                removeImage(at: index)
                            }
                            .defaultLoader(isLoading)
                        }
                    }
                    .frame(height: 120)
                }
            }
        }
        .frame(maxWidth: .infinity)
        // Clear processed items when picker is dismissed
        .onChange(of: isImagePickerPresented) { _, isPresented in
            if !isPresented {
                // Reset when picker is dismissed
                photoPickerItem.removeAll()
                processedPickerItems.removeAll()
            }
        }
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
        helperFunctions.requestPhotoPermission { isGranted in
            if isGranted {
                isImagePickerPresented = true
            } else {
                showAlertForPermissionDenied = true
                debugPrint(DeveloperConstants.LoginRegister.permissionDeniedMessage)
            }
        }
    }
    
    // Improved photo picker handling
    @MainActor
    private func handlePhotoPickerSelection(_ newItems: [PhotosPickerItem]) async {
        for item in newItems {
            let itemIdentifier = item.itemIdentifier ?? UUID().uuidString
            
            // Skip if already processed
            if processedPickerItems.contains(itemIdentifier) {
                continue
            }
            
            // Load the image
            let loadedImages = await HelperFunctions.loadImageFromPicker([item])
            if let image = loadedImages.first {
                selectedImages.append(image)
                processedPickerItems.insert(itemIdentifier)
            }
        }
    }
    
    private func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }
}

// MARK: - 1.1 Add Photo Button
struct AddPhotoButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(uiColor: .systemBackground))
                    .frame(width: 100, height: 120)
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
            .frame(width: 110, height: 130)
        }
    }
}

// MARK: - 1.2 Selected Image View
struct SelectedImageView: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Button(action: onRemove) {
                Image(systemName: DeveloperConstants.systemImage.closeXmark)
                    .resizable()
                    .scaledToFit()
                    .padding(6)
                    .background(Color(.systemBackground).opacity(0.8))
                    .clipShape(Circle())
                    .foregroundColor(.primary)
                    .shadow(radius: 1)
            }
            .frame(width: 30, height: 30)
            .offset(x: -5, y: 5)
        }
    }
}
