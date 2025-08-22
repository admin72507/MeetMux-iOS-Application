//
//  S2DownloadManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 14-05-2025.
//

import Foundation
import AWSS3
import Kingfisher
import UIKit

// MARK: - S3 URL Parser
struct S3URLParser {
    static func extract(from urlString: String) -> (bucket: String, key: String)? {
        guard let url = URL(string: urlString),
              let host = url.host,
              host.contains(".s3."),
              let bucket = host.components(separatedBy: ".s3.").first else {
            return nil
        }
        
        let key = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return (bucket, key)
    }
}

// MARK: - S3 Image Downloader
final class S3ImageDownloader: ObservableObject {
    static let shared = S3ImageDownloader()
    private init() {}
    
    @Published var downloadProgress: Double = 0.0
    
    private let bucketName = DeveloperConstants.BaseURL.bucketName
    private let transferUtilityKey = DeveloperConstants.utilityKey
    private let region: AWSRegionType = .APSouth1
    
    /// Function to load image using a full S3 URL
    func loadImage(from urlString: String) async throws -> UIImage? {
        guard let (bucket, key) = S3URLParser.extract(from: urlString) else {
            print("❌ Invalid S3 URL: \(urlString)")
            return nil
        }
        return try await loadImage(bucket: bucket, key: key)
    }
    
    /// Core image loader using bucket and key
    func loadImage(bucket: String, key: String) async throws -> UIImage? {
        let cacheKey = "s3-\(key)"
        
        // 1. Check Kingfisher memory cache
        if let cachedImage = ImageCache.default.retrieveImageInMemoryCache(forKey: cacheKey) {
            self.downloadProgress = 1.0
            return cachedImage
        }
        
        // 2. Download from S3
        do {
            let data = try await downloadData(fromBucket: bucket, key: key)
            
            guard !data.isEmpty else { return nil }
            
            if let image = UIImage(data: data) {
                try await ImageCache.default.store(image, forKey: cacheKey)
                self.downloadProgress = 1.0
                return image
            } else {
                self.downloadProgress = 0.0
                print("S3 download failed: Data or image is nil")
                return nil
            }
        } catch {
            self.downloadProgress = 0.0
            print("S3 download error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Download S3 data with progress
    private func downloadData(fromBucket bucket: String, key: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let expression = AWSS3TransferUtilityDownloadExpression()
            expression.progressBlock = { [weak self] _, progress in
                let progressValue = progress.fractionCompleted
                DispatchQueue.main.async { [weak self] in
                    self?.downloadProgress = progressValue
                }
            }
            AWSS3TransferUtility.default().downloadData(
                fromBucket: bucket,
                key: key,
                expression: expression
            ) { task, url, data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "S3DownloadError",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to download image data"]
                        )
                    )
                }
            }
        }
    }
}
