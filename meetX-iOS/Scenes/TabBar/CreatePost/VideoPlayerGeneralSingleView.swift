//
//  VideoPlayerGeneralSingleView.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 28-05-2025.
//
import SwiftUI
import AVKit

struct VideoPlayerViewCreatePost: View {
    @StateObject private var viewModel: VideoPlayerViewModelCreatePost
    
    init(videoURL: URL) {
        _viewModel = StateObject(wrappedValue: VideoPlayerViewModelCreatePost(videoURL: videoURL))
    }
    
    var body: some View {
        ZStack {
            VideoPlayer(player: viewModel.player)
                .aspectRatio(contentMode: viewModel.isPortraitVideo ? .fill : .fit)
                .ignoresSafeArea()
                .onAppear {
                    viewModel.onAppear()
                }
                .onDisappear {
                    viewModel.onDisappear()
                }
            
            videoControlOverlay
        }
    }
    
    private var videoControlOverlay: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 40) {
                controlButton(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill", action: viewModel.togglePlayPause)
                controlButton(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill", action: viewModel.toggleMute)
                
                if viewModel.showReplay {
                    controlButton(systemName: "gobackward", action: viewModel.replayVideo)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 10)
            .padding(.bottom, safeAreaBottomInset + 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
    
    private func controlButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(radius: 5)
        }
    }
}
