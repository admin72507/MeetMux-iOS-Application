//
//  EditProfileObservable.swift
//  meetX-iOS
//
//  Enhanced version with proper image state management
//

import SwiftUI
import PhotosUI
import Combine
import AWSS3
import AWSCore

// MARK: - Enhanced Image Management Models
enum ProfileImageSourceType {
    case existing(signedUrl: String, s3Url: String) // Existing images from server
    case newGallery(image: UIImage) // New images from gallery
    case newCamera(image: UIImage) // New images from camera
}

struct ProfileImageItem: Identifiable, Equatable {
    let id = UUID()
    let sourceType: ProfileImageSourceType
    
    // Helper computed properties
    var displayImage: UIImage? {
        switch sourceType {
            case .existing(let signedUrl, _):
                // You'll need to load this from cache or fetch it
                return loadImageFromURL(signedUrl)
            case .newGallery(let image), .newCamera(let image):
                return image
        }
    }
    
    var isExisting: Bool {
        switch sourceType {
            case .existing: return true
            default: return false
        }
    }
    
    var isNew: Bool {
        return !isExisting
    }
    
    var s3Url: String? {
        switch sourceType {
            case .existing(_, let s3Url): return s3Url
            default: return nil
        }
    }
    
    static func == (lhs: ProfileImageItem, rhs: ProfileImageItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    private func loadImageFromURL(_ urlString: String) -> UIImage? {
        // Implement your image loading logic here
        // This could be from cache or async loading
        return nil // Placeholder
    }
}

class EditProfileObservable: ObservableObject {
    
    // MARK: - Published Properties
    @Published var profileImages: [ProfileImageItem] = [] // Single source of truth
    @Published var selectedGender: Int = 20
    @Published var formattedDate: String = ""
    @Published var username: String = ""
    @Published var emailAddress: String = ""
    @Published var bioText: String = ""
    @Published var errorMessageValidation: String = ""
    @Published var selectedSubCategories: Set<Int> = []
    @Published var showErrorToastActivities: Bool = false
    @Published var showUploadRelatedErrorMessage: Bool = false
    @Published var isProcessingImages: Bool = false
    @Published var showToastErrorMessage: Bool = false
    @Published var dismissTheView: Bool = false
    
    // MARK: - Private Properties
    let helperFunctions = HelperFunctions()
    private let permissionHelper = PermissionHelper()
    private var cancellables = Set<AnyCancellable>()
    let routeManager = RouteManager.shared
    var imageUploadErrorMessage: String?
    let userDataManager = UserDataManager.shared
    
    // MARK: - Computed Properties for backward compatibility
    var selectedImages: [UIImage] {
        get {
            return profileImages.compactMap { $0.displayImage }
        }
        set {
            // Handle the case where selectedImages is set directly
            // This maintains backward compatibility with your existing UI
            updateProfileImagesFromUIImages(newValue)
        }
    }
    
    // MARK: - Initialization
    init(
        fullName: String,
        bio: String,
        email: String,
        selectedActivities: Set<Int>,
        s3ImageUrls: [String],
        signedProfileImageUrl: [String]
    ) {
        self.username = fullName
        self.emailAddress = email
        self.bioText = bio
        self.selectedSubCategories = selectedActivities
        
        // Initialize existing images
        self.profileImages = createInitialProfileImages(
            s3Urls: s3ImageUrls,
            signedUrls: signedProfileImageUrl
        )
    }
    
    // MARK: - Helper Methods
    private func createInitialProfileImages(s3Urls: [String], signedUrls: [String]) -> [ProfileImageItem] {
        var items: [ProfileImageItem] = []
        
        // Ensure both arrays have the same count
        let minCount = min(s3Urls.count, signedUrls.count)
        
        for i in 0..<minCount {
            let item = ProfileImageItem(
                sourceType: .existing(signedUrl: signedUrls[i], s3Url: s3Urls[i])
            )
            items.append(item)
        }
        
        return items
    }
    
    private func updateProfileImagesFromUIImages(_ images: [UIImage]) {
        // This is called when selectedImages is set directly
        // We need to figure out which images are new
        let currentNewImages = profileImages.filter { $0.isNew }
        let existingImages = profileImages.filter { $0.isExisting }
        
        // Clear existing new images and add the new ones
        var updatedImages = existingImages
        
        // Add new images (we can't distinguish between gallery and camera here)
        for image in images {
            // Check if this image is already in our existing images
            let isAlreadyPresent = currentNewImages.contains { item in
                switch item.sourceType {
                    case .newGallery(let existingImage), .newCamera(let existingImage):
                        return existingImage == image
                    default:
                        return false
                }
            }
            
            if !isAlreadyPresent {
                let newItem = ProfileImageItem(sourceType: .newGallery(image: image))
                updatedImages.append(newItem)
            }
        }
        
        self.profileImages = updatedImages
    }
    
    // MARK: - Public Methods for Image Management
    
    /// Add new image from gallery
    func addImageFromGallery(_ image: UIImage) {
        let newItem = ProfileImageItem(sourceType: .newGallery(image: image))
        profileImages.append(newItem)
    }
    
    /// Add new image from camera
    func addImageFromCamera(_ image: UIImage) {
        let newItem = ProfileImageItem(sourceType: .newCamera(image: image))
        profileImages.append(newItem)
    }
    
    /// Remove image by ID
    func removeImage(withId id: UUID) {
        profileImages.removeAll { $0.id == id }
    }
    
    /// Remove image by UIImage reference (for backward compatibility)
    func removeImage(_ image: UIImage) {
        profileImages.removeAll { item in
            switch item.sourceType {
                case .newGallery(let img), .newCamera(let img):
                    return img == image
                default:
                    return false
            }
        }
    }
    
    /// Get all images that need to be uploaded to S3
    func getNewImagesForUpload() -> [UIImage] {
        return profileImages.compactMap { item in
            switch item.sourceType {
                case .newGallery(let image), .newCamera(let image):
                    return image
                default:
                    return nil
            }
        }
    }
    
    /// Get all existing S3 URLs that should be kept
    func getExistingS3Urls() -> [String] {
        return profileImages.compactMap { item in
            switch item.sourceType {
                case .existing(_, let s3Url):
                    return s3Url
                default:
                    return nil
            }
        }
    }
    
    /// Get final combined URLs for API call
    func getFinalImageUrls(newUploadedUrls: [String]) -> [String] {
        var finalUrls: [String] = []
        var newUrlIndex = 0
        
        for item in profileImages {
            switch item.sourceType {
                case .existing(_, let s3Url):
                    finalUrls.append(s3Url)
                case .newGallery(_), .newCamera(_):
                    if newUrlIndex < newUploadedUrls.count {
                        finalUrls.append(newUploadedUrls[newUrlIndex])
                        newUrlIndex += 1
                    }
            }
        }
        
        return finalUrls
    }
    
    // MARK: - Validation
    func validateAndProceed(completion: (Bool) -> Void) {
        if let errorMessage = validateInputs() {
            errorMessageValidation = errorMessage
            completion(false)
        } else {
            errorMessageValidation = ""
            completion(true)
        }
    }
    
    private func validateInputs() -> String? {
        let errors: [(Bool, String)] = [
            (profileImages.count <= 0, Constants.minImagesRequired),
            (username.isEmpty, Constants.emptyUsername),
            (bioText.isEmpty, Constants.bioEmptyMessage),
            (emailAddress.isEmpty, Constants.emptyEmail),
            (!isValidEmail(emailAddress), Constants.invalidEmail),
            (selectedSubCategories.isEmpty, Constants.activityNotSelected)
        ]
        
        for (condition, message) in errors {
            if condition {
                return message
            }
        }
        
        return nil
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = DeveloperConstants.General.emailRegex
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func calculateAge(from birthDate: String) -> Int? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DeveloperConstants.General.dateFormat
        guard let birthDate = dateFormatter.date(from: birthDate) else {
            return nil
        }
        
        let today = Date()
        let ageComponents = Calendar.current.dateComponents([.year], from: birthDate, to: today)
        return ageComponents.year
    }
    
    // MARK: - Save Profile
    func saveTheProfileDetails() {
        isProcessingImages = true
        
        let newImages = getNewImagesForUpload()
        
        if newImages.isEmpty {
            // No new images to upload, directly call API with existing URLs
            let existingUrls = getExistingS3Urls()
            handleProfileUpdateAPI(imageUrls: existingUrls)
        } else {
            // Compress and upload new images
            compressUIImageToData(
                images: newImages,
                onSuccess: { [weak self] compressedDataArray in
                    print("Compression successful with \(compressedDataArray.count) images")
                    self?.uploadNewImagesToS3(compressedDataArray)
                },
                onFailure: { [weak self] error in
                    print("Compression failed: \(error.localizedDescription)")
                    self?.isProcessingImages = false
                    self?.showErrorToastActivities = true
                }
            )
        }
    }
    
    private func uploadNewImagesToS3(_ compressedData: [Data]) {
        var uploadFiles: [UploadFile] = []
        
        for fileData in compressedData {
            let fileType = getFileType(from: fileData)
            let uploadFile = UploadFile(data: fileData, fileExtension: fileType.rawValue)
            uploadFiles.append(uploadFile)
        }
        
        S3UploadManager.shared.uploadDataArray(uploadFiles, .profile)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                    case .finished:
                        debugPrint("Upload finished successfully")
                    case .failure(let error):
                        self?.isProcessingImages = false
                        Loader.shared.stopLoading()
                        self?.imageUploadErrorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] newUploadedUrls in
                // Combine existing URLs with newly uploaded URLs
                let finalUrls = self?.getFinalImageUrls(newUploadedUrls: newUploadedUrls) ?? []
                self?.handleProfileUpdateAPI(imageUrls: finalUrls)
            })
            .store(in: &cancellables)
    }
    
    private func handleProfileUpdateAPI(imageUrls: [String]) {
        
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else { return }
        
        let requestBody = EditProfileUpdateRequest(
            fullName: username,
            email: emailAddress,
            profilePicUrls: imageUrls,
            about: bioText,
            subActivitiesIds: selectedSubCategories.array
        )
        
        let publisher: AnyPublisher<ProfileUpdateResponse, APIError> = apiService.genericPostPublisher(
            toURLString: URLBuilderConstants.URLBuilder(type: .editProfile),
            requestBody: requestBody,
            isAuthNeeded: true,
            httpMethod: .put
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                Loader.shared.stopLoading()
                switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        print("Error: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                switch response.success {
                    case true:
                        //Returs Bool to tell whether the details are stored or not
                        _ = self?.userDataManager.updateProfileCompletionData(
                            userName: response.user?.username ?? "",
                            userDisplayName: response.user?.name ?? "",
                            userProfilePicture: response.user?.profilePicUrls.first ?? "", userGender: response.user?.gender ?? ""
                        )
                        
                        self?.userDataManager.storeUserPreferences(
                            username: response.user?.username
                        )
                        
                        self?.dismissTheView.toggle()
                        self?.routeManager.goBackMultiple(2)
                    case false:
                        Loader.shared.stopLoading()
                        self?.showErrorToastActivities.toggle()
                }
            })
            .store(in: &cancellables)
    }
}
