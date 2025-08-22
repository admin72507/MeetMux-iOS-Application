//
//  VideoTransferable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 28-05-2025.
//
import Foundation
import CoreTransferable

// Custom Transferable for Video Picker
struct VideoPickerTransferable: Transferable {
    // Video URL
    let videoURL: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { exportingFile in
            return .init(exportingFile.videoURL)
        } importing: { ReceivedTransferredFile in
            let originalFile = ReceivedTransferredFile.file
            let copiedFile = URL.documentsDirectory.appending(path: "video_\(UUID().uuidString).mov")
            
            /// Checking if already file Exists at the Path
            if FileManager.default.fileExists(atPath: copiedFile.path()) {
                /// Deleting Old File
                try FileManager.default.removeItem(at: copiedFile)
            }
            /// Copying File
            try FileManager.default.copyItem(at: originalFile, to: copiedFile)
            /// Passing the Copied File Path
            return .init(videoURL: copiedFile)
        }
    }
}
