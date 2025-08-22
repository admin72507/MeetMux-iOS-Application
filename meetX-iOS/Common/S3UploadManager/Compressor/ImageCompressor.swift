//
//  ImageCompressor.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 26-04-2025.
//

import UIKit

// MARK: - Compression Error
enum ImageCompressionError: Error, LocalizedError {
    case failedToCompressImage
    case failedToResizeImage
    
    var errorDescription: String? {
        switch self {
            case .failedToCompressImage:
                return "Failed to compress image."
            case .failedToResizeImage:
                return "Failed to resize image."
        }
    }
}

// MARK: - Compress and Convert UIImage to Data with Callbacks
func compressUIImageToData(
    images: [UIImage],
    maxSizeKB: Int = 1000,
    targetWidth: CGFloat = 1920,
    onSuccess: @escaping ([Data]) -> Void,
    onFailure: @escaping (Error) -> Void
) {
    var compressedDataArray: [Data] = []
    
    for image in images {
        guard let compressedData = resizeAndCompressImage(image: image, maxSizeKB: maxSizeKB, targetWidth: targetWidth) else {
            onFailure(ImageCompressionError.failedToCompressImage)
            return
        }
        compressedDataArray.append(compressedData)
    }
    
    onSuccess(compressedDataArray)
}

// MARK: - Resize and Compress Single UIImage
private func resizeAndCompressImage(image: UIImage, maxSizeKB: Int, targetWidth: CGFloat) -> Data? {
    var resizedImage = image
    
    // Step 1: Resize if necessary
    let scale = targetWidth / image.size.width
    if scale < 1.0 {
        let newHeight = image.size.height * scale
        let newSize = CGSize(width: targetWidth, height: newHeight)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
    }
    
    // Step 2: Compress
    var compression: CGFloat = 1.0
    let maxBytes = maxSizeKB * 1024
    var imageData = resizedImage.jpegData(compressionQuality: compression)
    
    while let data = imageData, data.count > maxBytes, compression > 0.1 {
        compression -= 0.1
        imageData = resizedImage.jpegData(compressionQuality: compression)
    }
    
    return imageData
}
