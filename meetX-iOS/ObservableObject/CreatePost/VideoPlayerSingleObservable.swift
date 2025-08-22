//
//  VideoPlayerSingleObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 28-05-2025.
//

import SwiftUI
import AVKit
import Combine

class VideoPlayerViewModelCreatePost: ObservableObject {
    @Published var isPlaying = false
    @Published var isMuted = false
    @Published var showReplay = false
    @Published var isPortraitVideo = false
    @Published var player: AVPlayer
    
    private var cancellables = Set<AnyCancellable>()
    private let videoURL: URL
    
    init(videoURL: URL) {
        self.videoURL = videoURL
        self.player = AVPlayer(url: videoURL)
        addNotificationObservers()
        Task {
            await determineVideoOrientation()
        }
    }
    
    deinit {
        removeNotificationObservers()
    }
    
    func onAppear() {
        player.play()
        isPlaying = true
    }
    
    func onDisappear() {
        player.pause()
    }
    
    func togglePlayPause() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
        if showReplay { showReplay = false }
    }
    
    func toggleMute() {
        isMuted.toggle()
        player.isMuted = isMuted
    }
    
    func replayVideo() {
        player.seek(to: .zero)
        player.play()
        isPlaying = true
        showReplay = false
    }
    
    private func addNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
            self?.showReplay = true
        }
    }
    
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func determineVideoOrientation() async {
        let asset = AVURLAsset(url: videoURL)
        do {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            if let track = tracks.first {
                let size = try await track.load(.naturalSize)
                let transform = try await track.load(.preferredTransform)
                let transformedSize = size.applying(transform)
                await MainActor.run {
                    self.isPortraitVideo = abs(transformedSize.height) > abs(transformedSize.width)
                }
            }
        } catch {
            print("Failed to load video info: \(error)")
        }
    }
}
