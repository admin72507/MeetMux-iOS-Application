//
//  GridViewForPost.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 30-05-2025.
//
import SwiftUI
import AVFoundation
import Foundation
import Combine

struct InstagramProfileGridView: View {
    @Binding var postDetails: [PostItem]
    @ObservedObject var viewModel: ProfileMeAndOthersObservable
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedPost: PostItem? = nil
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        if postDetails.isEmpty {
            SimpleEmptyStateView()
        } else {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(postDetails.enumerated()), id: \.offset) { index, post in
                    gridItemView(for: post, at: index)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
    }
    
    private func gridItemView(for post: PostItem, at index: Int) -> some View {
        SimpleGridItemView(
            post: post,
            index: index,
            onTap: {
                print("Tapped post at index \(index) with ID: \(post.id)")
                selectedPost = post
                viewModel.navigateToPostDetail(postId: post.postID ?? "")
            }
        )
        .onAppear {
            if index == postDetails.count - 3, !viewModel.isLoading {
                viewModel.isLoading = true
                viewModel.getTheProfileDetails()
            }
        }
    }
}

// MARK: - Simple Empty State
struct SimpleEmptyStateView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.stack")
                .font(.system(size: 40))
                .foregroundColor(.gray)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            
            VStack(spacing: 8) {
                Text("No posts yet")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("Your posts will appear here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Simple Grid Item
struct SimpleGridItemView: View {
    let post: PostItem
    let index: Int
    let onTap: () -> Void
    
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    // Portrait aspect ratio for all items
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    private var itemWidth: CGFloat {
        (screenWidth - 32) / 2 // Account for padding and spacing
    }
    
    // Increased height for better visibility
    private var itemHeight: CGFloat {
        itemWidth * 1.5 // Increased from 1.4 to 1.5 for better proportions
    }
    
    private var displayMediaItem: MediaFile? {
        getDisplayMediaItem(from: post.mediaFiles)
    }
    
    var body: some View {
        ZStack {
            // Main content
            if let mediaItem = displayMediaItem, let mediaURL = mediaItem.url {
                SimpleMediaView(
                    url: mediaURL,
                    isVideo: mediaItem.type?.lowercased() == "video"
                )
                
            } else {
                // Use enhanced doodle for posts without images
                EnhancedDoodleTextCard(
                    caption: post.caption ?? "No caption",
                    colorScheme: colorScheme
                )
                
            }
        }
        .frame(width: itemWidth, height: itemHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            VStack {
                Spacer()
                HStack {
                    RichAnimatedStatsView(
                        likes: post.totalLikes ?? 0,
                        comments: post.totalComments ?? 0
                    )
                    Spacer()
                }
                .padding(.bottom, 12)
                .padding(.horizontal, 12)
            }
                .allowsHitTesting(false), // <-- Allow taps to pass through to the parent view
            alignment: .bottomLeading
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .contentShape(Rectangle()) // Ensure tap area is constrained to the frame
        .onTapGesture {
            // Immediate feedback without async delay
            isPressed = true
            
            // Call the callback immediately
            onTap()
            
            // Reset animation state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
        }
        .id("post-\(post.id)-\(index)") // Ensure unique identity
    }
    
    private func getDisplayMediaItem(from: [MediaFile]?) -> MediaFile? {
        guard let mediaFiles = post.mediaFiles, !mediaFiles.isEmpty else { return nil }
        
        // Prefer images over videos
        if let imageFile = mediaFiles.first(where: { $0.type?.lowercased() == "image" }) {
            return imageFile
        }
        
        return mediaFiles.first
    }
    
    private var statsOverlay: some View {
        HStack {
            RichAnimatedStatsView(
                likes: post.likeCount ?? 0,
                comments: post.totalComments ?? 0
            )
            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}



// MARK: - Simple Media View
struct SimpleMediaView: View {
    let url: String
    let isVideo: Bool
    
    @State private var videoThumbnail: UIImage? = nil
    
    var body: some View {
        ZStack {
            if isVideo {
                // Video Thumbnail Handling
                if let thumbnail = videoThumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .overlay(playButtonOverlay)
                        .clipped()
                } else {
                    Color.gray.opacity(0.2)
                        .overlay(ProgressView())
                        .task {
                            await loadThumbnailIfNeeded(from: URL(string: url))
                        }
                }
            } else {
                // Image Handling via AsyncImage
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                            
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                            
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                )
                            
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                    }
                }
            }
        }
    }
    
    private func loadThumbnailIfNeeded(from url: URL?) async {
        guard let url = url, videoThumbnail == nil else { return }
        do {
            videoThumbnail = try await UIImage.thumbnailImage(for: url)
        } catch {
            print("Thumbnail generation failed: \(error.localizedDescription)")
        }
    }
    
    private var playButtonOverlay: some View {
        Image(systemName: DeveloperConstants.systemImage.playCircleFill)
            .resizable()
            .frame(width: 40, height: 40)
            .foregroundColor(.white)
            .shadow(radius: 5)
    }
}


// MARK: - Simple Video Overlay
struct SimpleVideoOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
            
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                        .offset(x: 1)
                )
        }
    }
}

// MARK: - Enhanced Doodle Text Card
struct EnhancedDoodleTextCard: View {
    let caption: String
    let colorScheme: ColorScheme
    
    @State private var animationOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Enhanced gradient background
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                        ? [Color.black, Color.gray.opacity(0.3)]
                        : [Color.white, Color.blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            
            // Enhanced decorative elements
            EnhancedDoodleElements(colorScheme: colorScheme, rotationAngle: rotationAngle)
            
            // Content
            VStack(spacing: 12) {
                Spacer()
                
                // Decorative icon with animation
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(y: animationOffset)
                
                Text(caption)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.horizontal, 12)
                    .lineLimit(5)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animationOffset = 3
            }
            withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Enhanced Doodle Elements
struct EnhancedDoodleElements: View {
    let colorScheme: ColorScheme
    let rotationAngle: Double
    
    var body: some View {
        ZStack {
            // Animated corner doodles
            VStack {
                HStack {
                    EnhancedDoodleShape()
                        .stroke(
                            LinearGradient(
                                colors: colorScheme == .dark
                                ? [Color.white.opacity(0.4), Color.blue.opacity(0.3)]
                                : [Color.black.opacity(0.4), Color.purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 18, height: 18)
                        .rotationEffect(.degrees(rotationAngle))
                    
                    Spacer()
                    
                    EnhancedDoodleShape()
                        .stroke(
                            LinearGradient(
                                colors: colorScheme == .dark
                                ? [Color.white.opacity(0.3), Color.pink.opacity(0.3)]
                                : [Color.black.opacity(0.3), Color.blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 15, height: 15)
                        .rotationEffect(.degrees(-rotationAngle))
                }
                Spacer()
                HStack {
                    EnhancedDoodleShape()
                        .stroke(
                            LinearGradient(
                                colors: colorScheme == .dark
                                ? [Color.white.opacity(0.35), Color.green.opacity(0.3)]
                                : [Color.black.opacity(0.35), Color.orange.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(rotationAngle * 0.5))
                    
                    Spacer()
                    
                    EnhancedDoodleShape()
                        .stroke(
                            LinearGradient(
                                colors: colorScheme == .dark
                                ? [Color.white.opacity(0.4), Color.yellow.opacity(0.3)]
                                : [Color.black.opacity(0.4), Color.red.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 14, height: 14)
                        .rotationEffect(.degrees(-rotationAngle * 0.7))
                }
            }
            .padding(10)
        }
    }
}

// MARK: - Enhanced Doodle Shape
struct EnhancedDoodleShape: Shape {
    private let shapeType = Int.random(in: 0...4)
    
    func path(in rect: CGRect) -> Path {
        switch shapeType {
            case 0:
                return createStarPath(in: rect)
            case 1:
                return createHeartPath(in: rect)
            case 2:
                return createCirclePath(in: rect)
            case 3:
                return createTrianglePath(in: rect)
            default:
                return createDiamondPath(in: rect)
        }
    }
    
    private func createStarPath(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        for i in 0..<5 {
            let angle = Double(i) * .pi * 2 / 5 - .pi / 2
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
    
    private func createHeartPath(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width/2, y: height))
        path.addCurve(
            to: CGPoint(x: 0, y: height/4),
            control1: CGPoint(x: width/2, y: height*3/4),
            control2: CGPoint(x: 0, y: height/2)
        )
        path.addArc(
            center: CGPoint(x: width/4, y: height/4),
            radius: width/4,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addArc(
            center: CGPoint(x: width*3/4, y: height/4),
            radius: width/4,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addCurve(
            to: CGPoint(x: width/2, y: height),
            control1: CGPoint(x: width, y: height/2),
            control2: CGPoint(x: width/2, y: height*3/4)
        )
        return path
    }
    
    private func createCirclePath(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.addEllipse(in: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        return path
    }
    
    private func createTrianglePath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
    
    private func createDiamondPath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Rich Animated Stats View
struct RichAnimatedStatsView: View {
    let likes: Int
    let comments: Int
    
    @State private var isVisible = false
    @State private var heartBeat = false
    @State private var commentPulse = false
    @State private var glowIntensity: Double = 0.5
    
    var body: some View {
        HStack(spacing: 12) {
            // Animated Like Button
            RichStatItem(
                icon: "heart.fill",
                count: formatCount(likes),
                baseColor: .red,
                accentColor: .pink,
                isAnimating: heartBeat
            )
            .scaleEffect(heartBeat ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: heartBeat)
            
            // Animated Comment Button
            RichStatItem(
                icon: "message.fill",
                count: formatCount(comments),
                baseColor: .blue,
                accentColor: .cyan,
                isAnimating: commentPulse
            )
            .scaleEffect(commentPulse ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: commentPulse)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            // Rich blur effect background
            ZStack {
                // Glassmorphism background
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.8),
                                Color.black.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        // Blur effect
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .opacity(0.9)
                    )
                
                // Animated border glow
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(glowIntensity),
                                Color.blue.opacity(glowIntensity * 0.7),
                                Color.purple.opacity(glowIntensity * 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .shadow(
                        color: .white.opacity(glowIntensity * 0.3),
                        radius: 4,
                        x: 0,
                        y: 0
                    )
            }
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                isVisible = true
            }
            
            // Start periodic animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                heartBeat = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                commentPulse = true
            }
            
            // Glow animation
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowIntensity = 1.0
            }
        }
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000.0)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        } else {
            return "\(count)"
        }
    }
}

// MARK: - Rich Stat Item
struct RichStatItem: View {
    let icon: String
    let count: String
    let baseColor: Color
    let accentColor: Color
    let isAnimating: Bool
    
    @State private var shimmerOffset: CGFloat = -100
    @State private var iconRotation: Double = 0
    
    var body: some View {
        HStack(spacing: 6) {
            // Animated icon with shimmer effect
            ZStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [baseColor, accentColor, baseColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(iconRotation))
                    .shadow(color: baseColor.opacity(0.5), radius: 2, x: 0, y: 1)
                
                // Shimmer overlay
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 20, height: 2)
                    .offset(x: shimmerOffset)
                    .mask(
                        Image(systemName: icon)
                            .font(.system(size: 12, weight: .bold))
                    )
            }
            .onAppear {
                // Icon rotation animation
                withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                    iconRotation = 360
                }
                
                // Shimmer animation
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 100
                }
            }
            
            // Enhanced count text
            Text(count)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            // Individual item background with glow
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    RadialGradient(
                        colors: [
                            baseColor.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: 20
                    )
                )
                .shadow(
                    color: baseColor.opacity(0.3),
                    radius: isAnimating ? 4 : 2,
                    x: 0,
                    y: 0
                )
        )
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let icon: String
    let count: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color)
            Text(count)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}
