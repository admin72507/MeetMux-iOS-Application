//
//  VideoCompressionLogic.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 26-05-2025.
//
import Foundation
import AVKit

enum VideoCompressor {
    static func compressVideoToData(inputURL: URL) async -> Data? {
        let asset = AVAsset(url: inputURL)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mp4")
        
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetMediumQuality
        ) else {
            debugPrint("⚠️ Failed to create export session")
            return nil
        }
        
        exportSession.outputURL = tempURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        return await withCheckedContinuation { continuation in
            exportSession.exportAsynchronously {
                defer {
                    // Clean up temp file
                    try? FileManager.default.removeItem(at: tempURL)
                }
                
                if exportSession.status == .completed {
                    do {
                        let data = try Data(contentsOf: tempURL)
                        debugPrint("✅ Video compressed successfully")
                        continuation.resume(returning: data)
                    } catch {
                        debugPrint("⚠️ Failed to read compressed data: \(error)")
                        continuation.resume(returning: nil)
                    }
                } else {
                    let errorMsg = exportSession.error?.localizedDescription ?? "Unknown error"
                    debugPrint("⚠️ Export failed: \(errorMsg)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}




