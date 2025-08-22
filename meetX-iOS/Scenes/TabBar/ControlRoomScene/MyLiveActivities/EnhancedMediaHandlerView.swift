//
//  EnhancedMediaHandlerView.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 25-06-2025.
//
import SwiftUI
import Kingfisher
import AVKit
import AVFoundation

// MARK: - Enhanced Media View
struct EnhancedMediaHandleView: View {
    let media: MediaFile
    let index: Int
    let typeFrom: DeveloperConstants.postDetailType
    @State private var videoThumbnail: UIImage?
    
    // Computed properties for consistent sizing
    private var frameWidth: CGFloat {
        typeFrom == .MyActivities ? 150 : 200
    }
    
    private var frameHeight: CGFloat {
        typeFrom == .MyActivities ? 150 : 250
    }
    
    var body: some View {
        Group {
            if media.type?.lowercased() == "video" {
                // Video thumbnail
                if let thumbnail = videoThumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: frameWidth, height: frameHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [.black.opacity(0.25), .clear, .black.opacity(0.5)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .overlay(
                                    VStack {
                                        Spacer()
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 3)
                                        Spacer()
                                        
                                        HStack(spacing: 6) {
                                            Image(systemName: "video.fill")
                                                .font(.caption)
                                            Text("Video")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(.black.opacity(0.7))
                                        )
                                        .padding(.bottom, 8)
                                    }
                                )
                        )
                } else {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.18), Color.gray.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: frameWidth, height: frameHeight)
                        .overlay(
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.4)
                                    .tint(ThemeManager.gradientNewPinkBackground)
                                Text("Loading video...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                            }
                        )
                        .onAppear {
                            generateVideoThumbnail()
                        }
                }
            } else {
                // Image
                KFImage(URL(string: media.url ?? ""))
                    .placeholder {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.18), Color.gray.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: frameWidth, height: frameHeight)
                            .overlay(
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.4)
                                        .tint(.blue)
                                    Text("Loading image...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fontWeight(.medium)
                                }
                            )
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: frameWidth, height: frameHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.15)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        HStack(spacing: 6) {
                                            Image(systemName: "photo.fill")
                                                .font(.caption)
                                            Text("Photo")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(.black.opacity(0.7))
                                        )
                                        .padding(.trailing, 16)
                                        .padding(.bottom, 8)
                                    }
                                }
                            )
                    )
            }
        }
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
    
    private func generateVideoThumbnail() {
        guard let urlString = media.url, let url = URL(string: urlString) else { return }
        
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 300, height: 300)
        
        let time = CMTime(seconds: 1, preferredTimescale: 1)
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, _ in
            if let cgImage = cgImage {
                DispatchQueue.main.async {
                    self.videoThumbnail = UIImage(cgImage: cgImage)
                }
            }
        }
    }
}
