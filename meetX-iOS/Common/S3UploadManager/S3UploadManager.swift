//
//  S3UploadManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 26-04-2025.
//

import Foundation
import AWSS3
import Combine
import CommonCrypto
import CryptoKit

// MARK: - Upload Manager

class S3UploadManager {
    static let shared = S3UploadManager()
    
    private let bucketName = DeveloperConstants.BaseURL.bucketName
    private let transferUtilityKey = DeveloperConstants.utilityKey
    private let region: AWSRegionType = .APSouth1
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    /// Upload multiple Data items (images, videos, PDFs, etc.), get back array of S3 URL Strings
    func uploadDataArray(
        _ dataItems: [UploadFile],
        _ typeOfUpload: DeveloperConstants.typeOfUpload
    ) -> AnyPublisher<[String], Error> {
        Future<[String], Error> { [weak self] promise in
            guard let self = self else { return }
            
            let dispatchGroup = DispatchGroup()
            var uploadedUrls: [String] = []
            var uploadErrors: [Error] = []
            
            for file in dataItems {
                dispatchGroup.enter()
                
                let fileName = self.generateUniqueFileName(for: file.data, fileExtension: file.fileExtension)
                
                guard let userIDFolderName = KeychainMechanism.fetchFromKeychain(key: DeveloperConstants.Keychain.userID) else { return }
                
                if self.isVideo(fileExtension: file.fileExtension) {
                    let key = "\(userIDFolderName)/\(getTheBuckName(typeOfUpload, .video))\(fileName)"
                    // Multipart upload for videos
//                    self.multipartUpload(file: file, key: key) { result in
//                        switch result {
//                            case .success(let url):
//                                uploadedUrls.append(url)
//                            case .failure(let error):
//                                uploadErrors.append(error)
//                        }
//                        dispatchGroup.leave()
//                    }
                    self.simpleUpload(file: file, key: key) { result in
                        switch result {
                            case .success(let url):
                                uploadedUrls.append(url)
                            case .failure(let error):
                                uploadErrors.append(error)
                        }
                        dispatchGroup.leave()
                    }
                } else {
                    let key = "\(userIDFolderName)/\(getTheBuckName(typeOfUpload, .image))\(fileName)"
                    // Simple upload for images, pdfs etc.
                    self.simpleUpload(file: file, key: key) { result in
                        switch result {
                            case .success(let url):
                                uploadedUrls.append(url)
                            case .failure(let error):
                                uploadErrors.append(error)
                        }
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .global(qos: .userInitiated)) {
                if !uploadErrors.isEmpty {
                    promise(.failure(uploadErrors.first!)) // return first error
                } else {
                    promise(.success(uploadedUrls))
                }
            }
        }
        .subscribe(on: DispatchQueue.global(qos: .userInitiated)) // Background thread
        .receive(on: DispatchQueue.main) // Result delivered on main thread
        .eraseToAnyPublisher()
    }
    
    // MARK: - Simple Upload (images, pdf)
    private func simpleUpload(file: UploadFile, key: String, completion: @escaping (Result<String, Error>) -> Void) {
        let transferUtility = AWSS3TransferUtility.default()
        
        let contentType = getContentType(for: file.fileExtension)
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = { task, progress in
            print("Upload Progress for \(key): \(progress.fractionCompleted * 100)%")
        }
        
        transferUtility.uploadData(
            file.data,
            bucket: bucketName,
            key: key,
            contentType: contentType,
            expression: expression
        ) { task, error in
            if let error = error {
                debugPrint("Simple upload failed: \(error.localizedDescription)")
                debugPrint("🔍 File size: \(file.data.count) bytes, Key: \(key)")
                completion(.failure(error))
            } else {
                let url = "https://\(self.bucketName).s3.\(self.getAWSRegionString()).amazonaws.com/\(key)"
                debugPrint("Simple upload succeeded: \(url)")
                completion(.success(url))
            }
        }
    }
    
    // MARK: - Multipart Upload (videos)
    private func multipartUpload(file: UploadFile, key: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let transferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: transferUtilityKey) else {
            completion(.failure(NSError(domain: "S3UploadManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transfer Utility not found"])))
            return
        }
        
        let contentType = getContentType(for: file.fileExtension)
        let expression = AWSS3TransferUtilityMultiPartUploadExpression()
        expression.progressBlock = { task, progress in
            debugPrint("Multipart Upload Progress for \(key): \(progress.fractionCompleted * 100)%")
        }
        
        transferUtility.uploadUsingMultiPart(
            data: file.data,
            bucket: bucketName,
            key: key,
            contentType: contentType,
            expression: expression
        ) { task, error in
            if let error = error {
                debugPrint("Multipart upload failed: \(error.localizedDescription)")
                debugPrint("🔍 File size: \(file.data.count) bytes, Key: \(key)")
                completion(.failure(error))
            } else {
                let url = "https://\(self.bucketName).s3.\(self.getAWSRegionString()).amazonaws.com/\(key)"
                debugPrint("Multipart upload succeeded: \(url)")
                completion(.success(url))
            }
        }
    }
    
    // MARK: - Retry Simple
    private func uploadWithRetrySimple(file: UploadFile, key: String, retryCount: Int = 0, completion: @escaping (Result<String, Error>) -> Void) {
        simpleUpload(file: file, key: key) { result in
            switch result {
                case .success(let url):
                    completion(.success(url))
                case .failure(let error):
                    if retryCount < 3 {
                        debugPrint("Retrying simple upload for \(key), attempt \(retryCount + 1)")
                        self.uploadWithRetrySimple(file: file, key: key, retryCount: retryCount + 1, completion: completion)
                    } else {
                        completion(.failure(error))
                    }
            }
        }
    }
    
    // MARK: - Retry multipart
    private func uploadWithRetryMultipart(file: UploadFile, key: String, retryCount: Int = 0, completion: @escaping (Result<String, Error>) -> Void) {
        multipartUpload(file: file, key: key) { result in
            switch result {
                case .success(let url):
                    completion(.success(url))
                case .failure(let error):
                    if retryCount < 3 {
                        debugPrint("Retrying multipart upload for \(key), attempt \(retryCount + 1)")
                        self.uploadWithRetryMultipart(file: file, key: key, retryCount: retryCount + 1, completion: completion)
                    } else {
                        completion(.failure(error))
                    }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func getContentType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
            case "jpg", "jpeg", "png":
                return "image/\(fileExtension.lowercased())"
            case "mp4":
                return "video/mp4"
            case "mov":
                return "video/quicktime"
            case "pdf":
                return "application/pdf"
            default:
                return "application/octet-stream"
        }
    }
    
    private func isVideo(fileExtension: String) -> Bool {
        let videoExtensions = ["mp4", "mov"]
        return videoExtensions.contains(fileExtension.lowercased())
    }
    
    private func generateUniqueFileName(for data: Data, fileExtension ext: String) -> String {
        let hash = data.sha256String()
        return "\(hash).\(ext)"
    }
    
    private func getAWSRegionString() -> String {
        switch region {
            case .APSouth1:
                return "ap-south-1"
            default:
                return "us-east-1" // Default region
        }
    }
    
    private func getTheBuckName(
        _ typeofBucket: DeveloperConstants.typeOfUpload,
        _ typeOfFile: DeveloperConstants.fileTypeForS3Upload
    ) -> String {
        switch typeofBucket {
            case .profile:
                return "profile-pictures/"
            case .generalPost:
                return "posts/generalactivity/\(typeOfFile.rawValue)"
            case .livePost:
                return "posts/liveactivity/\(typeOfFile.rawValue)"
            case .plannedPost:
                return "posts/plannedactivity/\(typeOfFile)"
        }
    }
}

// MARK: - Upload File Model

struct UploadFile {
    let data: Data
    let fileExtension: String
}

// MARK: - SHA256 Helper
extension Data {
    func sha256String() -> String {
        let hash = SHA256.hash(data: self)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
