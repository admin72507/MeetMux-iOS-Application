//
//  CreatePostObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 19-05-2025.
//

import Foundation
import SwiftUI
import Combine
import PhotosUI
import AVFoundation
import Photos
import UniformTypeIdentifiers
import AVFoundation

class CreatePostObservable: ObservableObject {
    @Published var selectedSegment: DeveloperConstants.PostSegmentControlList  = .GeneralPost
    
    // Navigate to Page
    @Published var navigateToSelectActivitiesPage: Bool = false
    @Published var navigateToTagPeoplePage: Bool = false
    @Published var navigateToSelectLocationPage: Bool = false
    @Published var navigateToSelectPhotoOrVideoPage: Bool = false // Navigate to photo video to choose
    
    // Make back button available
    @Published var makeBackButtonAvailabel: Bool = true
    
    // Activities Selection Tab
    var activitiesModelList: ActivitiesModel = ActivitiesModel(categories: [])
    var onDataReceived: (Set<Int>) -> Void = { _ in }
    @Published var filteredActivities : ActivitiesModel = ActivitiesModel(categories: [])
    
    // Media sections handling
    @Published var openCameraOnTap: Bool = false
    @Published var showAlertForPermissionDenied: Bool = false
    @Published var imageVideoPickerFromGallery: Bool = false
    @Published var isVideoRecorderPresented = false
    @Published var videoErrorMessageToast: String = ""
    @Published var videolargeToast: Bool = false
    
    // Date and Time Selector
    @Published var isDateTempData: Date = Date()
    @Published var isDateTimePickerPresented: Bool = false
    
    //Media loading
    @Published var isMediaLoading: Bool = false
    @Published var pickerImagesAndVideo: [PhotosPickerItem] = []
    @Published var isProcessingMedia: Bool = false
    @Published var debounceTask : Task<Void, Never>?
    
    // Enable Post Button
    @Published var enablePostButton: Bool = false
    
    // Gender PreferenceView
    @Published var showGenderPreferenceView: Bool = false
    
    // Live Duration
    @Published var showLiveDurationView: Bool = false
    
    // MARK: - Final Data Handlers
    @Published var isPublicPost: Bool = true // Post public or private true - Public | false - private
    @Published var postDescriptionText: String = "" // Has the post description text
    @Published var selectedMediaItems: [SelectedMedia] = [] // Has media files
    @Published var selectedSubActivites: Set<Int> = [] // Has the activities Data
    @Published var selectedUserTags: Set<ConnectedUser> = [] // Selected User Tags // Array of User ID
    @Published var selectedDateAndTime : String = "" // Selected Date
    @Published var backendDateTimeUTC: String = ""  // Backend UTC to be passed
    @Published var selectedGender: String = "Any" // Selected Gender
    @Published var selectedLiveDuration: String = ""  // Selected Live Duration
    @Published var selectedLatitude: Double = 0.0 // Selected Lat --> used in general and planned
    @Published var selectedLongitude: Double = 0.0 // Selected Long --> used in general and planned
    @Published var selectedLocationName: String = "" // Selected LocationName
    @Published var triggerDataAndTimeChange: Bool = false
    
    @Published var userLatitude: Double = 0.0 // Selected User live location --> used in live post
    @Published var userLongitude: Double = 0.0 // Selected User Live Long -->used in live post
    
    // HELPERS
    @Published var showLocationBottomSheet: Bool = false
    @Published var showAlertForLivePostCreaion: Bool = false
    @Published var errorToast: Bool = false
    var selectedPopUpToContinue: Bool = false // Used to check if the user selected the pop up to continue
    let permissionHelper = PermissionHelper()
    let helperFunctions = HelperFunctions()
    let locationViewModel = LocationObservable()
    let userDataManager = UserDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var validationCancellables = Set<AnyCancellable>()
    @Published var errorMessgeApi: String?
    @Published var showSuccessPostToast: Bool = false
    @Published var isKeyboardVisible = false
    
    init() {
        onDataReceived = { [weak self] selectedSet in
            DispatchQueue.main.async {
                guard selectedSet.count > 0,
                      let self = self,
                      self.activitiesModelList.categories.count > 0 else { return }

                self.selectedSubActivites = selectedSet
                self.filteredActivities = self.getFilteredActivities
            }
        }

        $filteredActivities
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedActivities in
                let selectedIDs = updatedActivities.categories
                    .flatMap { $0.subcategories }
                    .map { $0.id }

                self?.selectedSubActivites = Set(selectedIDs)
            }
            .store(in: &cancellables)

        // FIXED: Simplified validation publisher that triggers on any relevant change
        Publishers.CombineLatest(
            Publishers.CombineLatest4(
                $postDescriptionText.removeDuplicates(),
                $selectedSubActivites.removeDuplicates(),
                $selectedMediaItems.removeDuplicates { $0.count == $1.count },
                $selectedSegment.removeDuplicates()
            ),
            Publishers.CombineLatest4(
                $selectedLatitude.removeDuplicates(),
                $selectedLongitude.removeDuplicates(),
                $selectedLocationName.removeDuplicates(),
                $backendDateTimeUTC.removeDuplicates()
            )
        )
        .combineLatest(
            Publishers.CombineLatest3(
                $selectedLiveDuration.removeDuplicates(),
                $userLatitude.removeDuplicates(),
                $userLongitude.removeDuplicates()
            )
        )
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .map { [weak self] _, _ in
            return self?.validatePostFields() ?? false
        }
        .removeDuplicates()
        .assign(to: \.enablePostButton, on: self)
        .store(in: &validationCancellables)

        // Error handling
        $errorMessgeApi
            .compactMap { $0 }
            .sink { error in
                self.errorToast.toggle()
            }
            .store(in: &cancellables)
    }

    let postSections: [PostSection] = [
        PostSection( //General
            sectionTitle: Constants.makePostMoreInteresting,
            sectionSubtitle: "Add context to help others engage with your post",
            subCategories: [
                PostSectionList(
                    icon: DeveloperConstants.systemImage.photoOnRectangleAngled,
                    title: "Photo/Video",
                    subtitle: "Attach media to your post"
                ),
                PostSectionList(
                    icon: DeveloperConstants.systemImage.figureWalkMotion,
                    title: "Activities",
                    subtitle: "Share what you’re up to"
                ),
                PostSectionList(
                    icon: DeveloperConstants.systemImage.tagPeopleImage,
                    title: Constants.tagConnectionsTitle,
                    subtitle: Constants.mentionFriendsText
                ),
                PostSectionList(
                    icon: DeveloperConstants.systemImage.locationNorth,
                    title: "Location",
                    subtitle: "Add your current place / Place of Interest"
                )
            ]
                   ),
        PostSection( //Planned Activity
            sectionTitle: Constants.makePlannedPostInteresting,
            sectionSubtitle: Constants.makePlannedPostSubtitle,
            subCategories: [
                PostSectionList(
                    icon: DeveloperConstants.systemImage.photoOnRectangleAngled,
                    title: "Photo/Video",
                    subtitle: "Attach media to your post"
                ),
                PostSectionList(
                    icon: DeveloperConstants.systemImage.figureWalkMotion,
                    title: "Activities*",
                    subtitle: "Share what you’re up to (One Activity Allowed)"
                ),
                PostSectionList(
                    icon: DeveloperConstants.systemImage.tagPeopleImage,
                    title: Constants.tagConnectionsTitle,
                    subtitle: Constants.mentionFriendsText
                ),
                PostSectionList(
                    icon: DeveloperConstants.systemImage.locationNorth,
                    title: "Location*",
                    subtitle: "Add your current place"
                ),
                PostSectionList(
                    icon: DeveloperConstants.systemImage.selectDataAnTime,
                    title: "Date & Time*",
                    subtitle: "Add date&time for your activity"
                ),
                PostSectionList(
                    icon: DeveloperConstants.systemImage.genderIcon,
                    title: "Preferred Gender",
                    subtitle: "Add who can show interest on your activity"
                )
            ]
                   ),
        PostSection( //Live Activity
            sectionTitle: Constants.makeLiveActivityInteresting,
            sectionSubtitle: Constants.makeLiveSubtitle,
            subCategories: [
                PostSectionList(
                    icon: DeveloperConstants.systemImage.photoOnRectangleAngled,
                    title: "Photo/Video*",
                    subtitle: "Attach media to your post"
                ),
                PostSectionList(
                    icon: DeveloperConstants.systemImage.figureWalkMotion,
                    title: "Activities*",
                    subtitle: "Share what you’re up to (One Activity Allowed)"
                ),
                PostSectionList(
                    icon: DeveloperConstants.systemImage.tagPeopleImage,
                    title: Constants.tagConnectionsTitle,
                    subtitle: Constants.mentionFriendsText
                ),
                PostSectionList(
                    icon: DeveloperConstants.systemImage.simpleLocationIcon,
                    title: "Current Location*",
                    subtitle: "Add your current location"
                ),
                PostSectionList(
                    icon: DeveloperConstants.systemImage.liveDuration,
                    title: "Live Duration*",
                    subtitle: "Add duration you are planned for the live"
                ),
                PostSectionList(
                    icon: DeveloperConstants.systemImage.genderIcon,
                    title: "Preferred Gender",
                    subtitle: "Add who can show interest on your activity"
                )
            ]
                   )
    ]
    
    // MARK: - Check location permission and open
    func checkLocationAndOpenLocationSelector() {
        guard permissionHelper.getLocationAuthStatus() else {
            showLocationBottomSheet = true
            return
        }
        // open the sheet
        navigateToSelectLocationPage = true
    }
    
    @MainActor func openAppSettings() {
        permissionHelper.openAppSettings()
    }
    
    // MARK: - Planned Activity Live activity activites modifier
    func modifySelectedActivitiesBasedonLivePlanned() {
        guard selectedSubActivites.count > 1 else {
            return
        }
        
        selectedSubActivites.removeAll()
        filteredActivities.categories.removeAll()
        errorMessgeApi = "Removed selected activities since planned does multiple activities"
    }
    
    // MARK: - FIXED: Location fetcher with validation trigger
    func locationFetcherForLiveActivity() {
        if selectedSegment == .liveActivity {
            if permissionHelper.getLocationAuthStatus() {
                if let latitude = locationViewModel.latitude, let longitude = locationViewModel.longitude {
                    userLatitude = latitude
                    userLongitude = longitude
                    // Trigger validation after setting location
                    triggerValidation()
                }
                showAlertForLivePostCreaion = true
            } else {
                showLocationBottomSheet = true
            }
        }
    }

    func userCurrentLocationChecker() -> Bool {
        if permissionHelper.getLocationAuthStatus() {
            if let _ = locationViewModel.latitude, let _ = locationViewModel.longitude {
                return true
            }
        }
        return false
    }
    
}

// MARK: - Call the Activities API and return the list to load the view
extension CreatePostObservable {
    
    /// Function to handle the activities section
    func getSubActivitiesList(
        completion: @escaping (ActivitiesModel) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            failure(APIError.apiFailed(underlyingError: nil))
            return
        }
        
        let publisher:
        AnyPublisher<ActivitiesModel, APIError> = apiService.genericPublisher(
            fromURLString: URLBuilderConstants.URLBuilder(type: .getActivitiesList)
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        failure(APIError.apiFailed(underlyingError: error))
                }
                Loader.shared.stopLoading()
            }, receiveValue: { activitiesModel in
                completion(activitiesModel)
            })
            .store(in: &cancellables)
    }
    
    /// Computed variable to handle the array filtering
    /// // Filtered activities list with only selected subactivities
    var getFilteredActivities: ActivitiesModel {
        let filteredCategories = activitiesModelList.categories.map { category in
            // Filter subcategories that are in selectedSubActivities
            let filteredSubcategories = category.subcategories.filter { subcategory in
                selectedSubActivites.contains(subcategory.id)
            }
            // Return new Activities with filtered subcategories
            return Activities(id: category.id, name: category.name, subcategories: filteredSubcategories)
        }
        return ActivitiesModel(categories: filteredCategories)
    }
}

// MARK: - Extension CreatePost Media acccessing
extension CreatePostObservable {
    
    // MARK: - Camera and Video Tap
    func handleCameraTap() {
        navigateToSelectPhotoOrVideoPage = false
        permissionHelper.requestCameraPermission { [weak self] isGranted in
            if isGranted {
                self?.openCameraOnTap = true
            } else {
                self?.showAlertForPermissionDenied = true
                debugPrint(DeveloperConstants.LoginRegister.permissionCameraDeied)
            }
        }
    }
    
    // MARK: - Image Library Tap
    func handlePhotoLibraryTap() {
        navigateToSelectPhotoOrVideoPage = false
        permissionHelper.requestPhotoPermission { isGranted in
            if isGranted {
                self.imageVideoPickerFromGallery = true
            } else {
                self.showAlertForPermissionDenied = true
                debugPrint(DeveloperConstants.LoginRegister.permissionDeniedMessage)
            }
        }
    }
    
    func handleVideoLibraryTap() {
        navigateToSelectPhotoOrVideoPage = false
        permissionHelper.requestPhotoPermission { isGranted in
            if isGranted {
                self.isVideoRecorderPresented = true
            } else {
                self.showAlertForPermissionDenied = true
                debugPrint(DeveloperConstants.LoginRegister.permissionDeniedMessage)
            }
        }
    }
    
    // MARK: - Limit Checker
    func limitCheckerMediaFilesCount() -> Bool {
        guard selectedMediaItems.count < 5 else {
            videoErrorMessageToast = "Maximum 5 media files can be added per post \nPlease remove existing selection and try again."
            return false
        }
        return true
    }
    
    // MARK: - Video is lesser than 2min check
    @available(iOS 16.0, *)
    func validateVideoDuration(url: URL) async throws -> Bool {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let durationInSeconds = CMTimeGetSeconds(duration)
        return durationInSeconds <= DeveloperConstants.General.maximumVideoDuration
    }
    
    // MARK: - maximum selected media
    var remainingMediaSlots: Int {
        max(0, 5 - selectedMediaItems.count)
    }
    
    // MARK: - Remove a media
    func removeMedia(at index: Int) {
        guard selectedMediaItems.indices.contains(index) else { return }
        selectedMediaItems.remove(at: index)
    }
    
    // MARK: - Date Formatter
    func dateFormatterInPlannedAndLive(_ selectedDate : Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        formatter.locale = Locale.current
        
        let formattedString = formatter.string(from: selectedDate)
        return formattedString
    }
    
    // MARK: - UTC Convertor
    func utcConvertor(_ selectedDate : Date) {
        // 1. For backend (UTC)
        let backendFormatter = DateFormatter()
        backendFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        backendFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let utcString = backendFormatter.string(from: selectedDate)
        backendDateTimeUTC = utcString
    }
    
    // MARK: - Handling of selected Images
    func handlePickerItemsChange(
        oldItems: [PhotosPickerItem],
        newItems: [PhotosPickerItem]
    ) {
        debounceTask?.cancel()
        debounceTask = Task {
            do {
                try await Task.sleep(nanoseconds: 200_000_000)
                guard !newItems.isEmpty else { return }
                
                await MainActor.run {
                    isProcessingMedia = true
                }
                
                for item in newItems {
                    let detachedTask = Task.detached(priority: .userInitiated) {
                        do {
                            if item.supportedContentTypes.contains(where: { $0.conforms(to: .image) }) {
                                if let imageData = try? await item.loadTransferable(type: Data.self),
                                   let image = UIImage(data: imageData) {
                                    let resized = image.resized(toMaxDimension: 1024)
                                    let media = SelectedMedia(
                                        type: .image(resized),
                                        source: .gallery,
                                        originalPickerItem: item
                                    )
                                    await MainActor.run {
                                        self.selectedMediaItems.append(media)
                                        self.triggerDataAndTimeChange.toggle()
                                        debugPrint("✅ Image added. Total: \(self.selectedMediaItems.count)")
                                    }
                                    return
                                }
                            } else if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
                                if let videoTransferable = try await item.loadTransferable(type: VideoPickerTransferable.self) {
                                    let isValid = try await self.validateVideoDuration(url: videoTransferable.videoURL)
                                    await MainActor.run {
                                        if isValid {
                                            let media = SelectedMedia(
                                                type: .video(localURL: videoTransferable.videoURL),
                                                source: .gallery,
                                                originalPickerItem: item
                                            )
                                            self.selectedMediaItems.append(media)
                                            self.triggerDataAndTimeChange.toggle()
                                            debugPrint("🎥 Video added via fileRepresentation. Total: \(self.selectedMediaItems.count)")
                                        } else {
                                            self.videoErrorMessageToast = "Video must be under 2 minutes."
                                            self.videolargeToast = true
                                        }
                                    }
                                    return
                                }
                            }
                            
                            // Unrecognized or failed case
                            await MainActor.run {
                                self.videoErrorMessageToast = "Unsupported format or failed to load."
                                self.videolargeToast = true
                            }
                        } catch {
                            await MainActor.run {
                                self.videoErrorMessageToast = "Failed to process media item: \(error.localizedDescription)"
                                self.videolargeToast = true
                                debugPrint("❌ Error:", error)
                            }
                        }
                    }
                    
                    _ = await detachedTask.value
                }
                
                await MainActor.run {
                    isProcessingMedia = false
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            } catch {
                await MainActor.run {
                    isProcessingMedia = false
                    videoErrorMessageToast = "Processing interrupted."
                    videolargeToast = true
                    debugPrint("❌ Outer task error:", error)
                }
            }
        }
    }
}

// MARK: - Validation and API Handlers
extension CreatePostObservable {
    
    /// Validation Functions
    /// 1. General Post -> Need only Description mandatory
    ///  2. Planned Activity -> Need Description, Activities, selected lat and selected long, Date and Time
    ///  3. Live Activty --> Need Description, Photo/video(minimum 1), Activities, userlatitude and userlongitude, Live Duration(30, 60, maximum 24hrs --> after that activity become expired)
    
    // MARK: - FIXED: Improved validation logic
    func validatePostFields() -> Bool {
        let trimmedDesc = postDescriptionText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch selectedSegment {
            case .GeneralPost:
                let isValid = PostValidationType.general(
                    description: trimmedDesc
                ).isValid
                print("🔍 General post validation: \(isValid) - Desc count: \(trimmedDesc.count)")
                return isValid

            case .plannedActivity:
                let isValid = PostValidationType.planned(
                    description: trimmedDesc,
                    activities: selectedSubActivites,
                    locationName: selectedLocationName,
                    dateAndTime: backendDateTimeUTC
                ).isValid
                return isValid

            case .liveActivity:
                let isValid = PostValidationType.live(
                    description: trimmedDesc,
                    media: selectedMediaItems,
                    activities: selectedSubActivites,
                    lat: userLatitude,
                    lng: userLongitude,
                    duration: selectedLiveDuration
                ).isValid
                return isValid
        }
    }

    // MARK: - FIXED: Improved validation enum
    enum PostValidationType {
        case general(description: String)
        case planned(description: String, activities: Set<Int>, locationName: String, dateAndTime: String)
        case live(description: String, media: [SelectedMedia], activities: Set<Int>, lat: Double, lng: Double, duration: String)

        var isValid: Bool {
            switch self {
                case .general(let desc):
                    return desc.count >= DeveloperConstants.General.numberOfCharactersNeeded

                case .planned(let desc, let acts, let locationName, let dateTime):
                    let descValid = desc.count >= DeveloperConstants.General.numberOfCharactersNeeded
                    let activitiesValid = !acts.isEmpty
                    let locationValid = !locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    let dateTimeValid = !dateTime.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

                    return descValid && activitiesValid && locationValid && dateTimeValid

                case .live(let desc, let media, let acts, let lat, let lng, let dur):
                    let descValid = desc.count >= DeveloperConstants.General.numberOfCharactersNeeded
                    let mediaValid = !media.isEmpty
                    let activitiesValid = !acts.isEmpty
                    let locationValid = lat != 0.0 && lng != 0.0
                    let durationValid = !dur.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

                    return descValid && mediaValid && activitiesValid && locationValid && durationValid
            }
        }
    }

    // MARK: - Helper method to manually trigger validation
    func triggerValidation() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let isValid = self.validatePostFields()
            print("🔄 Manual validation triggered: \(isValid)")
            self.enablePostButton = isValid
        }
    }

    var cleanedDescription: String {
        postDescriptionText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
    
}


// MARK: - Extension Post Creation
extension CreatePostObservable {
    
    // MARK: - get the user tags from user array
    func getUserTags() -> [String] {
        return selectedUserTags.compactMap(\.userId)
    }
    
    func handleCreatePostActivity(_ mediaUploaded: [String], completion: @escaping (Bool) -> Void) {
        
        let urlString : URLBuilderConstants.ClientPathAppender
        let requestBody: Encodable
        
        switch selectedSegment {
            case .GeneralPost:
                urlString = .generalPostCreation
                requestBody = GeneralPostRequest(
                    action: "create",
                    visibility: isPublicPost ? "public" : "private",
                    latitude: selectedLatitude,
                    longitude: selectedLongitude,
                    caption: postDescriptionText,
                    peopleTags: getUserTags(),
                    activityTags: Array(selectedSubActivites),
                    mediaUrls: mediaUploaded)
                
            case .plannedActivity:
                urlString = .plannedPostCreation
                requestBody = PlannedActivityPostRequest(
                    action: "create",
                    visibility: isPublicPost ? "public" : "private",
                    latitude: selectedLatitude,
                    longitude: selectedLongitude,
                    caption: postDescriptionText,
                    peopleTags: getUserTags(),
                    activityTags: Array(selectedSubActivites),
                    maxParticipants: 10,
                    genderRestriction: selectedGender,
                    mediaUrls: mediaUploaded,
                    startTime: backendDateTimeUTC
                )

            case .liveActivity:
                urlString = .livePostCreation
                requestBody = LiveActivityPostRequest(
                    action: "create",
                    visibility: isPublicPost ? "public" : "private",
                    location: "",
                    latitude: userLatitude,
                    longitude: userLongitude,
                    caption: postDescriptionText,
                    peopleTags: getUserTags(),
                    activityTags: Array(selectedSubActivites),
                    maxParticipants: 10,
                    mediaUrls: mediaUploaded,
                    genderRestriction: selectedGender,
                    getLocationImage: true,
                    duration: selectedLiveDuration
                )
        }
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else {
            return
        }
        
        apiService.genericPostPublisher(
            toURLString: URLBuilderConstants.URLBuilder(type: urlString),
            requestBody: requestBody,
            isAuthNeeded: true)
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            guard let self = self else { return }
            switch completion {
                case let .failure(error):
                    self.errorMessgeApi = error.localizedDescription
                case .finished:
                    break
            }
            Loader.shared.stopLoading()
        }, receiveValue: { [weak self] (response: GeneralPostCreationResponse) in
            guard let self = self else { return }
            if response.success == true {
                // dismiss the view and open the success view
                // remove all the instances
                removeAllInstances()
                showSuccessPostToast.toggle()
                completion(response.success ?? false)
            }else {
                self.errorMessgeApi = "Post creation failed, \(response.message ?? "Please try again later")"
            }
        })
        .store(in: &cancellables)
    }
    
    func removeAllInstances() {
        isPublicPost = true
        postDescriptionText = ""
        selectedMediaItems.removeAll()
        selectedSubActivites.removeAll()
        selectedUserTags.removeAll()
        selectedDateAndTime = ""
        backendDateTimeUTC = ""
        selectedGender = ""
        selectedLiveDuration = ""
        selectedLatitude = 0.0
        selectedLongitude = 0.0
        selectedLocationName = ""
    }

}

// MARK: - Extension S3 uploader
extension CreatePostObservable {

    func prepareAndUploadMedia(completion: @escaping (Bool) -> Void) async {
        guard !selectedMediaItems.isEmpty else {
            debugPrint("ℹ️ selectedMediaItems is empty. Proceeding without uploads.")
            handleCreatePostActivity([], completion: { statusBool in
                completion(statusBool)
            })
            return
        }
        
        var mediaDataArray: [Data] = []
        
        for item in selectedMediaItems {
            switch item.type {
                case .image(let image):
                    if let imageData = image.jpegData(compressionQuality: 0.8) {
                        mediaDataArray.append(imageData)
                    } else {
                        errorMessgeApi = "Image conversion failed, Please try again"
                        debugPrint("⚠️ Failed to convert image to Data")
                    }
                    
                case .video(let localURL, _):
                    // Use compression instead of direct data loading
                    if let compressedData = await VideoCompressor.compressVideoToData(inputURL: localURL) {
                        mediaDataArray.append(compressedData)
                    } else {
                        // Fallback to original if compression fails
                        do {
                            let videoData = try Data(contentsOf: localURL)
                            mediaDataArray.append(videoData)
                            debugPrint("⚠️ Video compression failed, using original file")
                        } catch {
                            errorMessgeApi = "Failed to load video data, Please try again"
                            debugPrint("⚠️ Failed to load video data: \(error)")
                        }
                    }
            }
        }
        
        // ✅ If some media were valid, upload
        if !mediaDataArray.isEmpty {
            uploadFilesWithAutoDetection(files: mediaDataArray, completion: { statusBool in
                completion(statusBool)
            })
        } else {
            debugPrint("⚠️ No valid media to upload after conversion. Proceeding without uploads.")
            handleCreatePostActivity([], completion: { statusBool in
                completion(statusBool)
            })
        }
    }

    private func uploadFilesWithAutoDetection(files: [Data], completion: @escaping (Bool) -> Void) {
        var uploadFiles: [UploadFile] = []
        
        for fileData in files {
            let fileType = getFileType(from: fileData)
            let uploadFile = UploadFile(data: fileData, fileExtension: fileType.rawValue)
            uploadFiles.append(uploadFile)
        }
        
        S3UploadManager.shared.uploadDataArray(
            uploadFiles, .generalPost
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            switch completion {
                case .finished:
                    debugPrint("Upload finished successfully")
                case .failure(let error):
                    Loader.shared.stopLoading()
                    self?.errorMessgeApi = error.localizedDescription
            }
        }, receiveValue: { [weak self] urls in
            self?.handleCreatePostActivity(urls, completion: { statusBool in
                completion(statusBool)
            })
        })
        .store(in: &cancellables)
    }
}
