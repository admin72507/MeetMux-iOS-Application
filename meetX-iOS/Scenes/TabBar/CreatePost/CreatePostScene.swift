//
//  KeyboardManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 27-06-2025.
//
import SwiftUI
import AlertToast
import PhotosUI
import UniformTypeIdentifiers

struct CreatePostScene: View {
    @Binding var isTabBarPresented: Bool
    @StateObject private var viewModel: CreatePostObservable
    @StateObject private var tagPeopleViewModel: TagPeopleViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var theme
    @StateObject private var keyboard = KeyboardHelper()
    
    init(isTabBarPresented: Binding<Bool>) {
        _isTabBarPresented = isTabBarPresented
        
        let createPostVM = CreatePostObservable()
        _viewModel = StateObject(wrappedValue: createPostVM)
        _tagPeopleViewModel = StateObject(wrappedValue: TagPeopleViewModel(selectedConnections: createPostVM.selectedUserTags))
    }
    
    @ViewBuilder
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ThemeManager.backgroundColor.edgesIgnoringSafeArea(.top)
                
                VStack {
                    CustomSegmentedControl(
                        selectedSegment: $viewModel.selectedSegment,
                        titleProvider: { $0.title },
                        showLiveIndicator: true,
                        onSegmentChanged: { index in
                            switch index {
                                case 0:
                                    viewModel.selectedSegment = .GeneralPost
                                case 1:
                                    viewModel.selectedSegment = .plannedActivity
                                    viewModel.modifySelectedActivitiesBasedonLivePlanned()
                                case 2:
                                    viewModel.selectedSegment = .liveActivity
                                    viewModel.modifySelectedActivitiesBasedonLivePlanned()
                                    viewModel.locationFetcherForLiveActivity()
                                default:
                                    viewModel.selectedSegment = .GeneralPost
                            }
                        }
                    )
                    .frame(height: 45)
                    .padding(.horizontal)
                    .id("segmentControl")
                    
                    switch viewModel.selectedSegment {
                        case .GeneralPost, .plannedActivity, .liveActivity:
                            GeneralCreatePostView(
                                viewModel: viewModel,
                                selectedLocation: $viewModel.selectedLocationName,
                                selectedTagConnections: $viewModel.selectedUserTags,
                                onDeleteTappedOnTag: { user in
                                    viewModel.selectedUserTags.remove(user)
                                    tagPeopleViewModel.selectedConnections = viewModel.selectedUserTags
                                },
                                selectedActivityList: $viewModel.filteredActivities,
                                onItemSelected: { selectedItem in
                                    itemSelectionHandler(selectedItem)
                                })
                    }
                }
                .padding(.top, 20)
                .generalNavBarInControlRoom(
                    title: Constants.createPostTitle,
                    subtitle: Constants.createPostDescription,
                    image: DeveloperConstants.systemImage.postCreationTitleImage,
                    onBacktapped: {
                        dismiss()
                        isTabBarPresented = true
                    })
                
                // Top shadow bar
                VStack {
                    ThemeManager.backgroundColor
                        .frame(height: HelperFunctions.hasNotch(in: geometry.safeAreaInsets) ? 110 : 70)
                        .shadow(color: ThemeManager.staticPurpleColour.opacity(0.1), radius: 2, x: 0, y: 2)
                        .edgesIgnoringSafeArea(.top)
                    Spacer()
                }
                
                if viewModel.isProcessingMedia {
                    handleProgressForMedia()
                } else if keyboard.keyboardHeight == 0 {
                    handleThePostButton(geometry)
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .onAppear() {
                isTabBarPresented = false
            }
            .animation(.easeInOut, value: viewModel.isProcessingMedia)
        }
        .fullScreenCover(isPresented: $viewModel.showSuccessPostToast) {
            SuccessPageView( okAction: {
                dismiss()
            })
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.locationFetcherForLiveActivity()
        }
        .sheet(isPresented: $viewModel.showGenderPreferenceView ) {
            GenderWheelPickerView(
                isPresented: $viewModel.showGenderPreferenceView,
                selectedGender: $viewModel.selectedGender,
                options: Constants.genderArray
            ) { newGender in
                viewModel.selectedGender = newGender
            }
            .presentationDragIndicator(.visible)
            .presentationDetents([.height(200)])
        }
        .sheet(isPresented: $viewModel.showLiveDurationView) {
            GenderWheelPickerView(
                isPresented: $viewModel.showLiveDurationView,
                selectedGender: $viewModel.selectedLiveDuration,
                options: Constants.liveDurations
            ) { liveDuration in
                viewModel.selectedLiveDuration = liveDuration
            }
            .presentationDragIndicator(.visible)
            .presentationDetents([.height(250)])
        }
        .sheet(isPresented: $viewModel.showLocationBottomSheet) {
            BottomSheetContent(
                title: Constants.locationAccessDisabled,
                subtitle: Constants.enableLocationText,
                message: Constants.locationAccessInstructions,
                primaryButtonTitle: Constants.openSettingsText,
                secondaryButtonTitle: "Close",
                primaryAction: { viewModel.openAppSettings() },
                secondaryAction: { viewModel.selectedSegment = .plannedActivity },
                hideSecondaryButton: false,
                showSheet: $viewModel.showLocationBottomSheet
            )
            .presentationDragIndicator(.visible)
            .presentationDetents([.fraction(0.35)])
        }
        .sheet(isPresented: $viewModel.showAlertForLivePostCreaion) {
            BottomSheetContent(
                title: Constants.titleNewPopUpForLocation,
                subtitle: Constants.subTitlePopUpForLocation,
                message: Constants.descriptionPopUpForLocation,
                primaryButtonTitle: Constants.continueText,
                secondaryButtonTitle: "Close",
                primaryAction: {
                    viewModel.selectedPopUpToContinue = true
                    viewModel.selectedSegment = .liveActivity
                    viewModel.showAlertForLivePostCreaion = false
                },
                secondaryAction: {
                    if viewModel.selectedPopUpToContinue {
                        viewModel.selectedPopUpToContinue = false
                        viewModel.selectedSegment = .liveActivity
                    }else {
                        viewModel.selectedSegment = .plannedActivity
                    }
                    viewModel.showAlertForLivePostCreaion = false
                },
                hideSecondaryButton: false,
                showSheet: $viewModel.showLocationBottomSheet
            )
            .onAppear {
                viewModel.selectedPopUpToContinue = false
            }
            .presentationDragIndicator(.visible)
            .presentationDetents([.fraction(0.35)])
        }
        .sheet(isPresented: $viewModel.navigateToTagPeoplePage, onDismiss: {
            viewModel.selectedUserTags = tagPeopleViewModel.selectedConnections
        }) {
            TagPeopleScene(viewModel: tagPeopleViewModel, isNavigationFromMenu: false)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.navigateToSelectLocationPage) {
            LocationSearchView { mainName,entireName,lat,lon in
                viewModel.selectedLocationName = entireName
                viewModel.selectedLatitude = lat ?? 0.0
                viewModel.selectedLongitude = lon ?? 0.0
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.navigateToSelectActivitiesPage) {
            ActivitiesSelectionScene(
                selectedSubActivites: $viewModel.selectedSubActivites,
                activityModel: viewModel.activitiesModelList,
                onSendData: viewModel.onDataReceived,
                moveToActivityScreen: $viewModel.navigateToSelectActivitiesPage,
                showNotificationBar: .constant(false),
                showDoneButton:
                        .constant(true),
                fromPostCreationPlannedorLive: [
                    .plannedActivity,
                    .liveActivity
                ]
                    .contains(viewModel.selectedSegment)
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .toast(isPresenting: $viewModel.errorToast) {
            HelperFunctions().apiErrorToastCenter("Create Post!!!", viewModel.errorMessgeApi ?? Constants.unknownError)
        }
        .sheet(
            isPresented: $viewModel.navigateToSelectPhotoOrVideoPage,
            onDismiss: { },
            content: {
                AddPhotoBottomSheet(
                    isPresented: $viewModel.navigateToSelectPhotoOrVideoPage,
                    title: Constants.uploadMediaTomakePostInterestText,
                    options: DeveloperConstants.MediaOptionsCreatePost.options(
                        onPhotoLibraryTap: {
                            viewModel.handlePhotoLibraryTap()
                        },
                        onCameraTap: {
                            viewModel.handleCameraTap()
                        },
                        onVideoRecordTap: {
                            viewModel.handleVideoLibraryTap()
                        }
                    ))
                .presentationDetents([.height(295)])
                .ignoresSafeArea(edges: .bottom)
            })
        .fullScreenCover(isPresented: $viewModel.openCameraOnTap) {
            CameraPicker { image in
                let capturedImageFromCamera = SelectedMedia(
                    type: .image(image),
                    source: .cameraImage
                )
                viewModel.selectedMediaItems.append(capturedImageFromCamera)
                viewModel.triggerDataAndTimeChange.toggle()
            }
            .ignoresSafeArea(.all)
        }
        .photosPicker(
            isPresented: $viewModel.imageVideoPickerFromGallery,
            selection: $viewModel.pickerImagesAndVideo,
            maxSelectionCount: 5,
            matching: .any(of: [.images, .videos])
        )
        .alert(
            Constants.photoAccessDenied,
            isPresented: $viewModel.showAlertForPermissionDenied
        ) {
            Button(Constants.settingsTitle) { viewModel.permissionHelper.openAppSettings() }
            Button(Constants.cancelText, role: .cancel) { }
        } message: {
            Text(Constants.photoDeniedPostSection)
        }
        .fullScreenCover(isPresented: $viewModel.isVideoRecorderPresented) {
            VideoRecorderView { videoURL in
                let recordedVideo = SelectedMedia(
                    type: .video(localURL: videoURL),
                    source: .cameraVideo
                )
                viewModel.selectedMediaItems.append(recordedVideo)
                viewModel.triggerDataAndTimeChange.toggle()
            }
        }
        .toast(isPresenting: $viewModel.videolargeToast) {
            HelperFunctions().apiErrorToastCenter(
                "Photo/Video Selection Failed 😕",
                viewModel.videoErrorMessageToast
            )
        }
        .onChange(of: viewModel.pickerImagesAndVideo) { oldValue, newValue in
            guard !newValue.isEmpty else { return }
            
            let newlyAdded = newValue.filter { !oldValue.contains($0) }
            guard !newlyAdded.isEmpty else { return }
            
            viewModel.handlePickerItemsChange(oldItems: oldValue, newItems: newlyAdded)
        }
        .sheet(isPresented: $viewModel.isDateTimePickerPresented) {
            DateAndTimePickerScene(
                isPresented: $viewModel.isDateTimePickerPresented,
                selectedDate: $viewModel.isDateTempData
            ) { confirmedDate in
                viewModel.isDateTempData = confirmedDate
                viewModel.selectedDateAndTime = viewModel.dateFormatterInPlannedAndLive(confirmedDate)
                viewModel.utcConvertor(confirmedDate)
                viewModel.triggerDataAndTimeChange.toggle()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

extension CreatePostScene {
    func handleProgressForMedia() -> some View {
        ZStack {
            VisualEffectBlur(blurStyle: theme == .dark ? .dark : .light)
                .ignoresSafeArea()
            
            ProgressView("Processing media...")
                .progressViewStyle(CircularProgressViewStyle(tint: ThemeManager.foregroundColor))
                .foregroundColor(ThemeManager.foregroundColor)
                .padding()
        }
        .onAppear() {
            viewModel.makeBackButtonAvailabel = false
        }
        .onDisappear() {
            viewModel.makeBackButtonAvailabel = true
        }
        .contentShape(Rectangle())
        .onTapGesture { }
        .transition(.opacity)
        .animation(.easeInOut, value: true)
    }
    
    // MARK: - Handle the post button
    func handleThePostButton(_ geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()
            
            Button(action: {
                Loader.shared.startLoading()
                Task {
                    await viewModel.prepareAndUploadMedia(completion: {_ in  })
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: DeveloperConstants.systemImage.postButton)
                    Text(
                        viewModel.selectedSegment == .GeneralPost
                        ? "Create a Post"
                        : viewModel.selectedSegment == .plannedActivity
                        ? "Create a Planned Activity"
                        : "Create a Live Activity"
                    )
                }
                .fontStyle(size: 14, weight: .semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
            }
            .disabled(!viewModel.enablePostButton)
            .frame(height: 45)
            .background(postButtonBackgroundTwo)
            .cornerRadius(25)
            .padding(.horizontal, 16)
            .shadow(
                color: viewModel.enablePostButton
                ? ThemeManager.staticPurpleColour.opacity(0.5)
                : .clear,
                radius: 6, x: 0, y: 4
            )
            .padding(.bottom, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.25), value: keyboard.keyboardHeight)
        }
        .frame(maxWidth: .infinity)
        .edgesIgnoringSafeArea(.bottom)
    }
    
    @ViewBuilder
    private var postButtonBackgroundTwo: some View {
        if viewModel.enablePostButton {
            ThemeManager.gradientBackground
        } else {
            Color.gray.opacity(0.6)
        }
    }
}

// MARK: - extension for Action Handling
extension CreatePostScene {
    
    func itemSelectionHandler(_ selecteditem: PostSectionList) {
        switch selecteditem.icon {
                
            case DeveloperConstants.systemImage.figureWalkMotion:
                if viewModel.activitiesModelList.categories.count > 0 {
                    viewModel.navigateToSelectActivitiesPage = true
                } else {
                    Loader.shared.startLoading()
                    viewModel.getSubActivitiesList { activitiesModel in
                        viewModel.activitiesModelList = activitiesModel
                        viewModel.navigateToSelectActivitiesPage = true
                    } failure: { error in
                        viewModel.errorMessgeApi = error.localizedDescription
                    }
                }
                
            case DeveloperConstants.systemImage.locationNorth:
                viewModel.checkLocationAndOpenLocationSelector()
                
            case DeveloperConstants.systemImage.tagPeopleImage:
                viewModel.navigateToTagPeoplePage = true
                
            case DeveloperConstants.systemImage.photoOnRectangleAngled:
                if viewModel.limitCheckerMediaFilesCount() {
                    viewModel.navigateToSelectPhotoOrVideoPage = true
                } else {
                    viewModel.videolargeToast = true
                }
                
            case DeveloperConstants.systemImage.selectDataAnTime:
                viewModel.isDateTimePickerPresented.toggle()
                
            case DeveloperConstants.systemImage.genderIcon:
                viewModel.showGenderPreferenceView.toggle()
                
            case DeveloperConstants.systemImage.liveDuration:
                viewModel.showLiveDurationView.toggle()
                
            case .none:
                break
            case .some(_):
                break
        }
    }
}
