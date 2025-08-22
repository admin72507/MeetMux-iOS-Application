//
//  PostGalleryModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 27-05-2025.
//
import SwiftUI
import PhotosUI

enum MediaSource: String, Codable {
    case gallery
    case cameraImage
    case cameraVideo
}

enum MediaType: Equatable {
    case image(UIImage)
    case video(localURL: URL, originalData: Data? = nil)
}

struct SelectedMedia: Identifiable, Equatable {
    let id: UUID
    let type: MediaType
    let source: MediaSource
    let originalPickerItem: PhotosPickerItem? // Only non-nil for gallery
    let pickerItemIdentifier: String?
    
    init(type: MediaType, source: MediaSource, originalPickerItem: PhotosPickerItem? = nil) {
        self.id = UUID()
        self.type = type
        self.source = source
        self.originalPickerItem = originalPickerItem
        self.pickerItemIdentifier = originalPickerItem?.itemIdentifier
    }
    
    static func == (lhs: SelectedMedia, rhs: SelectedMedia) -> Bool {
        // If both are gallery items with valid identifiers, compare those
        if let lhsID = lhs.pickerItemIdentifier,
           let rhsID = rhs.pickerItemIdentifier {
            return lhsID == rhsID
        }
        
        // Otherwise, fallback to comparing based on source + media content
        // For images: compare image data or reference
        // For videos: compare local URLs
        
        switch (lhs.type, rhs.type) {
            case let (.image(lhsImage), .image(rhsImage)):
                return lhsImage.pngData() == rhsImage.pngData() // or other image equality
            case let (.video(lhsURL, _), .video(rhsURL, _)):
                return lhsURL == rhsURL
            default:
                return false
        }
    }
}
