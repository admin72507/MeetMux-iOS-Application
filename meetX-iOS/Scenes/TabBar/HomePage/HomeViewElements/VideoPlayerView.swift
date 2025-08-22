////
////  VideoPlayerView.swift
////  meetX-iOS
////
////  Created by Karthick Thavasimuthu on 31-03-2025.
////
//import SwiftUI
//import AVKit
//import Combine
//
//struct VideoPlayerView: View {
//    @StateObject private var viewModel: VideoPlayerObservable
//    @State private var showPlayButton: Bool = true
//    
//    let videoURL: URL
//    let isActive: Bool
//    let videoFromGeneral: Bool
//    
//    init(videoURL: URL, isActive: Bool, videoFromGeneral: Bool) {
//        self.videoURL = videoURL
//        self.isActive = isActive
//        self.videoFromGeneral = videoFromGeneral
//        _viewModel = StateObject(wrappedValue: VideoPlayerObservable(videoURL: videoURL))
//    }
//    
//    var body: some View {
//        ZStack {
//            if viewModel.isError {
//                errorOverlay
//            } else {
//                GeometryReader { geometry in
//                    ZStack {
//                        VideoPlayer(player: viewModel.player)
//                            .aspectRatio(
//                                viewModel.videoSize == .zero
//                                ? 9.0 / 16.0
//                                : viewModel.videoSize.width / viewModel.videoSize.height,
//                                contentMode: .fill
//                            )
//                            .frame(maxWidth: .infinity, maxHeight: .infinity)
//                            .background(Color.black)
//                            .onDisappear {
//                                viewModel.pause()
//                            }
//                        
//                        // Play / Replay Buttons
//                        if showPlayButton {
//                            Button(action: {
//                                if viewModel.showReplay {
//                                    viewModel.replay()
//                                } else {
//                                    viewModel.activateAndPlay()
//                                }
//                            }) {
//                                if viewModel.showReplay {
//                                    VStack(spacing: 8) {
//                                        Image(systemName: "arrow.counterclockwise.circle.fill")
//                                            .resizable()
//                                            .frame(width: 50, height: 50)
//                                            .foregroundColor(ThemeManager.foregroundColor)
//                                            .shadow(radius: 4)
//                                            .background(
//                                                VisualEffectBlur(blurStyle: .systemThinMaterial)
//                                                    .clipShape(Circle())
//                                            )
//                                    }
//                                } else {
//                                    Image(systemName: "play.circle.fill")
//                                        .resizable()
//                                        .frame(width: 50, height: 50)
//                                        .foregroundColor(ThemeManager.foregroundColor)
//                                        .background(
//                                            VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
//                                                .clipShape(Circle())
//                                        )
//                                }
//                            }
//                            .transition(.opacity)
//                        }
//                    }
//                    .frame(width: geometry.size.width, height: geometry.size.height)
//                    .contentShape(Rectangle()) // <- makes entire area tappable
//                    .onTapGesture {
//                        if viewModel.isPlaying {
//                            viewModel.pause()
//                        } else {
//                            viewModel.activateAndPlay()
//                        }
//                    }
//                }
//            }
//        }
//        .onAppear {
//            viewModel.applyMuteState(VideoPlaybackManager.shared.getMuteState())
//        }
//        .onChange(of: isActive) { _, newValue in
//            if newValue {
//                viewModel.activateAndPlay()
//            } else {
//                viewModel.pause()
//            }
//        }
//        .onReceive(viewModel.$isPlaying) { playing in
//            withAnimation {
//                showPlayButton = !playing
//            }
//        }
//        .onReceive(viewModel.$showReplay) { replay in
//            withAnimation {
//                showPlayButton = replay
//            }
//        }
//    }
//    
//    private var errorOverlay: some View {
//        VStack(spacing: 16) {
//            Image(systemName: "exclamationmark.triangle.fill")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 60, height: 60)
//                .foregroundColor(.yellow)
//            
//            Text("Oops! Something went wrong.")
//                .font(.headline)
//                .foregroundColor(.white)
//            
//            Text("The video failed to play. Please try again.")
//                .font(.subheadline)
//                .multilineTextAlignment(.center)
//                .foregroundColor(.white.opacity(0.8))
//                .padding(.horizontal)
//            
//            Button(action: {
//                viewModel.retryVideo()
//            }) {
//                Text("Retry")
//                    .bold()
//                    .padding(.horizontal, 24)
//                    .padding(.vertical, 10)
//                    .background(Color.white.opacity(0.9))
//                    .foregroundColor(.black)
//                    .clipShape(Capsule())
//            }
//        }
//        .padding(24)
//        .background(
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color.black.opacity(0.8))
//        )
//        .frame(maxWidth: 300)
//        .transition(.scale)
//        .animation(.easeInOut, value: viewModel.isError)
//    }
//}
//
//// Reusable blur
//struct VisualEffectBlur: UIViewRepresentable {
//    var blurStyle: UIBlurEffect.Style
//    var animationDuration: Double = 0.3
//    
//    func makeUIView(context: Context) -> UIVisualEffectView {
//        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
//    }
//    
//    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
//        UIView.animate(withDuration: animationDuration) {
//            uiView.effect = UIBlurEffect(style: blurStyle)
//        }
//    }
//}

import SwiftUI
import AVKit
import Combine

struct VideoPlayerView: View {
    @StateObject private var viewModel: VideoPlayerObservable
    @State private var showPlayButton: Bool = true
    
    let videoURL: URL
    let isActive: Bool
    let videoFromGeneral: Bool
    
    init(videoURL: URL, isActive: Bool, videoFromGeneral: Bool) {
        self.videoURL = videoURL
        self.isActive = isActive
        self.videoFromGeneral = videoFromGeneral
        _viewModel = StateObject(wrappedValue: VideoPlayerObservable(videoURL: videoURL))
    }
    
    var body: some View {
        ZStack {
            if viewModel.isError {
                errorOverlay
            } else {
                GeometryReader { geometry in
                    ZStack {
                        // Use custom player without controls
                        CustomVideoPlayerRepresentable(player: viewModel.player)
                            .aspectRatio(
                                viewModel.videoSize == .zero
                                ? 9.0 / 16.0
                                : viewModel.videoSize.width / viewModel.videoSize.height,
                                contentMode: .fill
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                            .onDisappear {
                                viewModel.pause()
                            }
                        
                        // Your Custom Play / Replay Buttons
                        if showPlayButton {
                            Button(action: {
                                if viewModel.showReplay {
                                    viewModel.replay()
                                } else {
                                    viewModel.activateAndPlay()
                                }
                            }) {
                                if viewModel.showReplay {
                                    VStack(spacing: 8) {
                                        Image(systemName: "arrow.counterclockwise.circle.fill")
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(ThemeManager.foregroundColor)
                                            .shadow(radius: 4)
                                            .background(
                                                VisualEffectBlur(blurStyle: .systemThinMaterial)
                                                    .clipShape(Circle())
                                            )
                                    }
                                } else {
                                    Image(systemName: "play.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(ThemeManager.foregroundColor)
                                        .background(
                                            VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                                                .clipShape(Circle())
                                        )
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if viewModel.isPlaying {
                            viewModel.pause()
                        } else {
                            viewModel.activateAndPlay()
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.applyMuteState(VideoPlaybackManager.shared.getMuteState())
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                viewModel.activateAndPlay()
            } else {
                viewModel.pause()
            }
        }
        .onReceive(viewModel.$isPlaying) { playing in
            withAnimation {
                showPlayButton = !playing
            }
        }
        .onReceive(viewModel.$showReplay) { replay in
            withAnimation {
                showPlayButton = replay
            }
        }
    }
    
    private var errorOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.yellow)
            
            Text("Oops! Something went wrong.")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("The video failed to play. Please try again.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal)
            
            Button(action: {
                viewModel.retryVideo()
            }) {
                Text("Retry")
                    .bold()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.9))
                    .foregroundColor(.black)
                    .clipShape(Capsule())
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
        )
        .frame(maxWidth: 300)
        .transition(.scale)
        .animation(.easeInOut, value: viewModel.isError)
    }
}

// MARK: - Custom Video Player Representable (No Default Controls)
struct CustomVideoPlayerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        // Disable all default controls
        playerViewController.showsPlaybackControls = false
        playerViewController.allowsPictureInPicturePlayback = false
        playerViewController.videoGravity = .resizeAspectFill
        
        // Remove any gesture recognizers that might interfere
        playerViewController.view.gestureRecognizers?.removeAll()
        
        return playerViewController
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

// Keep your existing VisualEffectBlur
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    var animationDuration: Double = 0.3
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        UIView.animate(withDuration: animationDuration) {
            uiView.effect = UIBlurEffect(style: blurStyle)
        }
    }
}
