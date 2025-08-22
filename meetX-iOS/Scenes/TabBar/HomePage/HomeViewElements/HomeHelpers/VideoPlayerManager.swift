//
//  VideoPlayerManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 03-05-2025.
//
import AVFoundation
import Combine

final class VideoPlaybackManager: ObservableObject {
    static let shared = VideoPlaybackManager()
    
    private var currentPlayer: AVPlayer?
    private var subscriptions = Set<AnyCancellable>()
    
    // Publishers to communicate playback state
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isBuffering: Bool = false
    @Published private(set) var isMuted: Bool = false
    
    private init() {}
    
    func setCurrent(_ player: AVPlayer) {
        // Pause & reset old player if different
        if currentPlayer != player {
            currentPlayer?.pause()
            currentPlayer?.seek(to: .zero)
            removeObservers()
        }
        
        currentPlayer = player
        currentPlayer?.isMuted = isMuted
        
        addObservers(to: player)
        
        // Auto play if enabled in settings, else stay paused (default false)
        if AutoPlaySettings.shared.isAutoPlayEnabled {
            play()
        }
    }

    func play() {
        currentPlayer?.play()
    }
    
    func pause() {
        currentPlayer?.pause()
    }
    
    func togglePlayPause() {
        guard currentPlayer != nil else { return }
        
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        currentPlayer?.isMuted = muted
    }
    
    func getMuteState() -> Bool {
        return isMuted
    }
    
    func pauseCurrent() {
        guard let player = currentPlayer else { return }
        
        if player.timeControlStatus == .playing {
            player.pause()
        }
    }

    private func addObservers(to player: AVPlayer) {
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                    case .playing:
                        self?.isPlaying = true
                        self?.isBuffering = false
                    case .paused:
                        self?.isPlaying = false
                        self?.isBuffering = false
                    case .waitingToPlayAtSpecifiedRate:
                        self?.isBuffering = true
                    @unknown default:
                        break
                }
            }
            .store(in: &subscriptions)
    }
    
    private func removeObservers() {
        subscriptions.removeAll()
    }

    func toggleMute() {
        setMuted(!isMuted)
    }
}
