//
//  MediaListingScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 27-05-2025.
//
import SwiftUI
import AVKit
import PhotosUI

// MARK: - Image and video display view
struct MediaThumbnailScrollView: View {
    @Binding var selectedMedia: [SelectedMedia]
    @Binding var photoPickerItem: [PhotosPickerItem]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(selectedMedia) { media in
                    MediaThumbnailView(media: media, allMedia: selectedMedia) {
                        removeMedia(media)
                    }
                }
            }
            .padding()
        }
    }
    
    private func removeMedia(_ media: SelectedMedia) {
        if let mediaIndex = selectedMedia.firstIndex(of: media) {
            selectedMedia.remove(at: mediaIndex)
        }
        
        if let originalItem = media.originalPickerItem {
            photoPickerItem.removeAll { $0 == originalItem }
        }
    }
}

struct MediaThumbnailView: View {
    let media: SelectedMedia
    let allMedia: [SelectedMedia]
    let onDelete: () -> Void
    
    @State private var isViewerPresented = false
    @State private var videoThumbnail: UIImage? = nil
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button {
                isViewerPresented = true
            } label: {
                mediaContent
                    .frame(width: 150, height: 200)
                    .clipped()
                    .cornerRadius(10)
            }
            
            Button(action: onDelete) {
                Image(systemName: DeveloperConstants.systemImage.closeXmark)
                    .font(.title2)
                    .foregroundColor(.white)
                    .background(ThemeManager.gradientBackground)
                    .clipShape(Circle())
            }
            .offset(x: 6, y: -6)
        }
        .sheet(isPresented: $isViewerPresented) {
            MediaViewerScene(mediaItems: allMedia, initialMedia: media)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
    
    @ViewBuilder
    private var mediaContent: some View {
        ZStack {
            switch media.type {
                case .image(let uiImage):
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                    
                case .video(let localURL, _):
                    if let thumbnail = videoThumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .overlay(playButtonOverlay)
                    } else {
                        Color.gray.opacity(0.2)
                            .overlay(ProgressView())
                            .task {
                                await loadThumbnailIfNeeded(from: localURL)
                            }
                    }
            }
        }
    }
    
    private var playButtonOverlay: some View {
        Image(systemName: DeveloperConstants.systemImage.playCircleFill)
            .resizable()
            .frame(width: 40, height: 40)
            .foregroundColor(.white)
            .shadow(radius: 5)
    }
    
    private func loadThumbnailIfNeeded(from url: URL) async {
        guard videoThumbnail == nil else { return }
        do {
            videoThumbnail = try await UIImage.thumbnailImage(for: url)
        } catch {
            print("Thumbnail generation failed: \(error.localizedDescription)")
        }
    }
}

struct MediaViewerScene: View {
    let mediaItems: [SelectedMedia]
    let initialMedia: SelectedMedia
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    
    init(mediaItems: [SelectedMedia], initialMedia: SelectedMedia) {
        self.mediaItems = mediaItems
        self.initialMedia = initialMedia
        _currentIndex = State(initialValue: mediaItems.firstIndex(of: initialMedia) ?? 0)
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $currentIndex) {
                ForEach(Array(mediaItems.enumerated()), id: \.offset) { index, media in
                    ZStack {
                        switch media.type {
                            case .image(let uiImage):
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                                    .tag(index)
                                
                            case .video(let url, _):
                                VideoPlayerViewCreatePost(videoURL: url)
                                    .tag(index)
                        }
                    }
                    .background(Color.black)
                    .ignoresSafeArea()
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .background(Color.black)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    pageControlDots
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
            }
        }
    }
    
    private var pageControlDots: some View {
        HStack(spacing: 8) {
            ForEach(mediaItems.indices, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? ThemeManager.staticPinkColour : Color.gray.opacity(0.5))
                    .frame(width: index == currentIndex ? 10 : 8, height: index == currentIndex ? 10 : 8)
                    .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
            }
        }
    }
}

extension View {
    var safeAreaBottomInset: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .windows.first(where: \.isKeyWindow)?
            .safeAreaInsets.bottom ?? 0
    }
}
