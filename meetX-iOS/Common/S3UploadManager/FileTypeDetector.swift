//
//  FileTypeDetector.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 26-04-2025.
//

import Foundation
import UniformTypeIdentifiers

enum FileType: String {
    case jpg = "jpg"
    case png = "png"
    case mp4 = "mp4"
    case mov = "mov"
    case pdf = "pdf"
    case unknown = "unknown"
}

func getFileTypeForVideoUrls(from url: URL) -> FileType {
    guard let type = UTType(filenameExtension: url.pathExtension) else {
        return .unknown
    }
    
    if type.conforms(to: .jpeg) { return .jpg }
    if type.conforms(to: .png) { return .png }
    if type.conforms(to: .pdf) { return .pdf }
    if type.conforms(to: .mpeg4Movie) { return .mp4 }
    if type.conforms(to: .quickTimeMovie) { return .mov }
    
    return .unknown
}

func getFileType(from data: Data) -> FileType {
    // JPEG
    if data.starts(with: [0xFF, 0xD8, 0xFF]) {
        return .jpg
    }
    
    // PNG
    if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
        return .png
    }
    
    // PDF
    if data.starts(with: [0x25, 0x50, 0x44, 0x46]) {
        return .pdf
    }
    
    // Scan first 512 bytes for "ftyp"
    let maxSearchRange = min(data.count - 8, 512)
    
    for offset in 0..<maxSearchRange {
        let signatureRange = offset..<offset + 4
        let brandRange = offset + 4..<offset + 8
        
        guard brandRange.endIndex <= data.count else { break }
        
        let signature = data.subdata(in: signatureRange)
        let brand = data.subdata(in: brandRange)
        
        if let sigStr = String(data: signature, encoding: .ascii), sigStr == "ftyp" {
            if let brandStr = String(data: brand, encoding: .ascii) {
                if brandStr.contains("mp4") || brandStr.contains("isom") || brandStr.contains("avc1") {
                    return .mp4
                } else if brandStr.contains("qt  ") {
                    return .mov
                } else {
                    // Even if brand is unknown, assume mp4 if "ftyp" found
                    return .mp4
                }
            }
        }
    }
    
    return .unknown
}


