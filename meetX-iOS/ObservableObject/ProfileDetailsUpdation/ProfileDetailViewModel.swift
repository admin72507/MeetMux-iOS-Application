//
//  ProfileDetailViewModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 10-02-2025.
//

import SwiftUI
import PhotosUI
import Combine
import AWSS3
import AWSCore

class ProfileDetailViewModel: ObservableObject {
    
    @Published var selectedImages: [UIImage]            = []
    @Published var selectedGender: Int                  = 20
    @Published var formattedDate: String                = ""
    @Published var username: String                     = ""
    @Published var emailAddress: String                 = ""
    @Published var bioText: String                      = ""
    @Published var errorMessageValidation: String       = ""
    @Published var selectedSubCategories: Set<Int>      = []
    @Published var capturedImageForVerification: UIImage? = nil
    @Published var showErrorToastActivities             : Bool = false
    @Published var showUploadRelatedErrorMessage        : Bool = false
    var compressedImage: [Data]                         = []
    let routeManager                                    = RouteManager.shared
    var imageUploadErrorMessage                         : String?
    private var cancellables = Set<AnyCancellable>()
    let helperFunctions                                 = HelperFunctions()
    var verificationBase64: String = ""
    let permissionHelper = PermissionHelper()
    private let userDataManager: UserDataManager
    
    init(userDataManager: UserDataManager = UserDataManager.shared) {
        self.userDataManager = userDataManager
    }
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = DeveloperConstants.General.dateFormat
        return formatter
    }()
    
    var isImageCaptured: Bool {
        return capturedImageForVerification != nil
    }
    
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
            (selectedImages.count <= 0, Constants.minImagesRequired),
            (!isImageCaptured, Constants.verificationPhoto),
            (username.isEmpty, Constants.emptyUsername), //username
            (bioText.isEmpty, Constants.bioEmptyMessage), // bio
            (emailAddress.isEmpty, Constants.emptyEmail), // email
            (!isValidEmail(emailAddress), Constants.invalidEmail), //valid email check
            (selectedGender == 20, Constants.emptyGender), //selected gender
            (formattedDate.isEmpty, Constants.emptyDate), //selected date
            (calculateAge(from: formattedDate) ?? 0 <= 18, Constants.userAgeLimit),
            (selectedSubCategories.isEmpty, Constants.activityNotSelected) //selected categories
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
    
    func handleNavigationToProfessionScene() {
        routeManager.navigate(to: ProfessionalSceneRoute())
    }
    
    func saveTheProfileDetails() {
        compressUIImageToData(
            images: selectedImages,
            onSuccess: { [weak self] compressedDataArray in
                self?.uploadFilesWithAutoDetection(files: compressedDataArray)
            },
            onFailure: { [weak self] error in
                self?.showErrorToastActivities = true
            }
        )
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? self
    }
}


// MARK: - Activities List
extension ProfileDetailViewModel {
    
    /// Api Call to handle the subactivities list
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
                        failure(error)
                }
                Loader.shared.stopLoading()
            }, receiveValue: { activitiesModel in
                completion(activitiesModel)
            })
            .store(in: &cancellables)
    }
    
    /// Profile Update API
    func handleInternalAPI(_ profilePicurls: [String]) {
        
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else { return }
        
        if let selectedImage = capturedImageForVerification {
            if let base64String = compressAndConvertToBase64(image: selectedImage) {
                verificationBase64 = base64String
            }else { return }
        }
        
        let requestBody = ProfileUpdateRequest(
            profilePicUrls: profilePicurls,
            fullName: username,
            about: bioText,
            email: emailAddress,
            gender: helperFunctions.genderIDToString(selectedGender),
            dob: formattedDate,
            verificationPhotoString: verificationBase64,
            subActivitiesIds: selectedSubCategories.array
        )
        
        let publisher: AnyPublisher<ProfileUpdateResponse, APIError> = apiService.genericPostPublisher(
            toURLString: URLBuilderConstants.URLBuilder(type: .profileUpdate),
            requestBody: requestBody,
            isAuthNeeded: true
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                Loader.shared.stopLoading()
                switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        self.errorMessageValidation = error.localizedDescription
                }
            }, receiveValue: { [weak self] response in
                switch response.success {
                    case true:
                        self?.handleAPIResponse(response)
                    case false:
                        Loader.shared.stopLoading()
                        self?.errorMessageValidation = response.message
                }
            })
            .store(in: &cancellables)
    }
    
    func handleAPIResponse(_ response: ProfileUpdateResponse) {
        _ = userDataManager.updateProfileCompletionData(
            userName: response.user?.username ?? "",
            userDisplayName: response.user?.name ?? "",
            userProfilePicture: response.user?.profilePicUrls.first ?? "",
            requiresProfileCompletion: false,
            userGender: response.user?.gender ?? ""
        )

        userDataManager.storeUserPreferences(
            username: response.user?.username
        )
        
        if self.permissionHelper.checkPermissionsHandlerSyncLogin().count > 0 {
            self.routeManager.navigate(to: PermissionStepScene())
        } else {
            self.routeManager.navigate(to: HomePageRoute())
        }
    }
    
    func compressAndConvertToBase64(image: UIImage, compressionQuality: CGFloat = 0.3) -> String? {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            self.errorMessageValidation = "Failed to compress image"
            return nil
        }
        let base64String = imageData.base64EncodedString(options: .lineLength64Characters)
        return base64String
    }
    
}

// MARK: - S3 Uploader
extension ProfileDetailViewModel {
    
    func uploadFilesWithAutoDetection(files: [Data]) {
        var uploadFiles: [UploadFile] = []
        
        for fileData in files {
            let fileType = getFileType(from: fileData)
            let uploadFile = UploadFile(data: fileData, fileExtension: fileType.rawValue)
            uploadFiles.append(uploadFile)
        }
        
        S3UploadManager.shared.uploadDataArray(
            uploadFiles, .profile
        )
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                    case .finished:
                        debugPrint("Upload finished successfully")
                    case .failure(let error):
                        Loader.shared.stopLoading()
                        self?.errorMessageValidation = error.localizedDescription
                }
            }, receiveValue: { [weak self] urls in
                self?.handleInternalAPI(urls)
            })
            .store(in: &cancellables)
    }
}
