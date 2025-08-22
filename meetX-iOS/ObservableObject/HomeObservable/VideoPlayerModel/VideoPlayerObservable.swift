//
//  ViewPlayerObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 31-03-2025.
//
import AVFoundation
import Combine
import SwiftUI

final class VideoPlayerObservable: ObservableObject {
    @Published var isPlaying = false
    @Published var isMuted = false
    @Published var isLoading = true
    @Published var isError = false
    @Published var showReplay = false
    @Published var videoSize: CGSize = .zero
    
    let player: AVPlayer
    private var subscriptions = Set<AnyCancellable>()
    private let playbackManager = VideoPlaybackManager.shared
    
    private var timeObserverToken: Any?
    
    init(videoURL: URL) {
        self.player = AVPlayer(url: videoURL)
        setupObservers()
        if AutoPlaySettings.shared.isAutoPlayEnabled {
            activateAndPlay()
        }
    }
    
    deinit {
        removeObservers()
    }
    
    @MainActor
    private func observeVideoSize() {
        Task {
            guard let currentItem = player.currentItem else { return }
            
            let asset = currentItem.asset
            do {
                let tracks = try await asset.loadTracks(withMediaType: .video)
                guard let track = tracks.first else { return }
                
                let naturalSize = try await track.load(.naturalSize)
                let transform = try await track.load(.preferredTransform)
                let size = naturalSize.applying(transform)
                
                self.videoSize = CGSize(width: abs(size.width), height: abs(size.height))
            } catch {
                print("Failed to load video size: \(error)")
            }
        }
    }

    
    func determineContentMode() -> ContentMode {
        let videoSize = videoSize
        guard videoSize.width > 0, videoSize.height > 0 else {
            return .fill // fallback until size is known
        }
        
        let aspectRatio = videoSize.width / videoSize.height
        let screenRatio: CGFloat = UIScreen.main.bounds.width / UIScreen.main.bounds.height
        
        if aspectRatio < screenRatio {
            return .fill // portrait video should fill the screen
        } else {
            return .fill // landscape video fits with black bars if needed
        }
    }
    
    func calculatedHeight() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let size = videoSize
        guard size.width > 0 else { return 400 } // fallback
        let aspectRatio = size.height / size.width
        return screenWidth * aspectRatio
    }

    private func setupObservers() {
        playbackManager.$isPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPlaying)
        
        // Additional observers for buffering or error states can be added here
        
        // Observe AVPlayer status
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                    case .playing:
                        self?.isLoading = false
                        self?.isError = false
                        self?.showReplay = false
                    case .paused:
                        self?.isLoading = false
                    case .waitingToPlayAtSpecifiedRate:
                        self?.isLoading = true
                    @unknown default:
                        break
                }
            }
            .store(in: &subscriptions)
        
        player.publisher(for: \.currentItem?.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                
                if status == .readyToPlay {
                    Task {
                        await MainActor.run {
                            self.observeVideoSize()
                        }
                    }
                } else if status == .failed {
                    self.isError = true
                }
            }
            .store(in: &subscriptions)
        
        player.publisher(for: \.currentItem)
            .compactMap { $0 }
            .sink { [weak self] _ in
                Task { await self?.observeVideoSize() }
            }
            .store(in: &subscriptions)


        // Observe playback end
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            .sink { [weak self] _ in
                self?.showReplay = true
            }
            .store(in: &subscriptions)
        
        // TODO: Handle errors if needed
    }
    
    private func removeObservers() {
        subscriptions.removeAll()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            activateAndPlay()
        }
    }
    
    func activateAndPlay() {
        playbackManager.setCurrent(player)
        playbackManager.play()
    }
    
    func pause() {
        playbackManager.pause()
    }
    
    func applyMuteState(_ muted: Bool) {
        isMuted = muted
        player.isMuted = muted
    }
    
    func replay() {
        showReplay = false
        player.seek(to: .zero)
        activateAndPlay()
    }
    
    func seekForward() {
        let currentTime = player.currentTime().seconds
        let newTime = currentTime + 10
        let duration = player.currentItem?.duration.seconds ?? 0
        if newTime < duration {
            player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
        }
    }
    
    func seekBackward() {
        let currentTime = player.currentTime().seconds
        let newTime = max(currentTime - 10, 0)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
    }
    
    func retryVideo() {
        isError = false
        isLoading = true
        player.seek(to: .zero)
        activateAndPlay()
    }
    
    func toggleMute() {
        applyMuteState(!isMuted)
    }
}
