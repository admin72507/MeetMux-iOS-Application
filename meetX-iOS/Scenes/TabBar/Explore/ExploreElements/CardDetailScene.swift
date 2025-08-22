import SwiftUI
import Combine
import AVKit
import Kingfisher

// MARK: - Detail View for Card Tap Animation
struct CardDetailView: View {
    @StateObject private var viewModel: CardDetailViewModel
    @Binding var isPresented: Bool
    private var onEndActivity: (() -> Void)?
    private var onDismiss: (
        (
            _ feedItem: PostItem
        ) -> Void
    )?
    
    init(
        feedItem: PostItem,
        isPresented: Binding<Bool>,
        onEndActivity: (() -> Void)? = nil,
        onDismiss: (
            (
                _ feedItem: PostItem
            ) -> Void
        )? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: CardDetailViewModel(feedItem: feedItem))
        self._isPresented = isPresented
        self.onEndActivity = onEndActivity
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Media Section - Full width
                    mediaSectionLive
                        .offset(y: max(-viewModel.scrollOffset * 0.5, -50))
                        .animation(.easeOut(duration: 0.6), value: viewModel.scrollOffset)
                    
                    // Content Section with padding
                    contentSection
                
                }
                .background(GeometryReader { proxy in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("scroll")).minY)
                })
            }
            .padding(.top, 20)
            .ignoresSafeArea()
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                viewModel.updateScrollOffset(value)
            }
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        endLiveButton
                        Spacer()
                    }
                }
            )
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            viewModel.setupInitialMedia()
        }
        .onDisappear {
            viewModel.cleanup()
            onDismiss?(viewModel.feedItem)
        }
        .toast(isPresenting: $viewModel.showErrorToast) {
            HelperFunctions().apiErrorToastCenter(
                "Live Activity!!", viewModel.errorMessage ?? "")
        }
        .onChange(of: viewModel.dismissCurrentViewEndPost) { _, newValue in
            if newValue {
                isPresented.toggle()
                onEndActivity?()
            }
        }
        .sheet(isPresented: $viewModel.showJoinedUserToast) {
            PeopleTagsDetailView(
                peopleTags: viewModel.feedItem.joinedUserTags ?? [],
                onUserTapAction: { receivedUser in
                    viewModel.showJoinedUserToast.toggle()
                    viewModel.showTheSelectedUserProfile = receivedUser.userId
                },
                title: Constants.joinUserTitle
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: viewModel.showTheSelectedUserProfile) { _, newValue in
            isPresented.toggle()
            viewModel.moveToTaggedUserProfile(for: newValue)
        }
        .sheet(isPresented: $viewModel.showCommentView) {
            CommentsBottomSheet(post: $viewModel.feedItem)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("End Activity", isPresented: $viewModel.showEndConfirmation) {
            Button("End Activity", role: .destructive) {
                viewModel.handleEndLivePost()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to end this activity? \n \n Make sure to end it before it ends automatically, because once it ends, you won't be able to re-start it")
        }
    }
    
    // MARK: - Alternative Floating End Live Button (if you prefer it floating)
    private var endLiveButton: some View {
        Group {
            if viewModel.currentUserId == viewModel.feedItem.user?.userId {
                Button(action: {
                    viewModel.showEndConfirmation.toggle()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("End Live")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [ThemeManager.staticPinkColour, ThemeManager.staticPurpleColour],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color.red.opacity(0.4),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                }
                .buttonStyle(EndLiveButtonStyle())
                .opacity(viewModel.animateContent ? 1 : 0)
                .offset(y: viewModel.animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.9), value: viewModel.animateContent)
            }
        }
    }

    
    // MARK: - Enhanced Button Style for End Live
    struct EndLiveButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .brightness(configuration.isPressed ? -0.1 : 0)
                .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        }
    }
        
        // MARK: - Content Section
        private var contentSection: some View {
            VStack(alignment: .leading, spacing: 24) {
                // User Info Section
                userInfoSection
                    .opacity(viewModel.animateContent ? 1 : 0)
                    .offset(y: viewModel.animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: viewModel.animateContent)
                
                // Interest Button (centered)
                if viewModel.currentUserId != viewModel.feedItem.user?.userId {
                    HStack {
                        Spacer()
                        interestButtonView
                            .opacity(viewModel.animateContent ? 1 : 0)
                            .offset(y: viewModel.animateContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.3), value: viewModel.animateContent)
                        Spacer()
                    }
                }
                
                // Stats Section with Action Buttons
                interactiveStatsSection
                    .opacity(viewModel.animateContent ? 1 : 0)
                    .offset(y: viewModel.animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: viewModel.animateContent)
                
                // Caption Section
                captionSection
                    .opacity(viewModel.animateContent ? 1 : 0)
                    .offset(y: viewModel.animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.5), value: viewModel.animateContent)
                
                // Tagged Users Section
                if let taggedUsers = viewModel.feedItem.peopleTags, !taggedUsers.isEmpty {
                    taggedUsersSection(taggedUsers)
                        .opacity(viewModel.animateContent ? 1 : 0)
                        .offset(y: viewModel.animateContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: viewModel.animateContent)
                }
                
                // Joined Users Section
                if let joinedUsers = viewModel.feedItem.joinedUserTags, !joinedUsers.isEmpty {
                    joinedUsersSection(joinedUsers)
                        .opacity(viewModel.animateContent ? 1 : 0)
                        .offset(y: viewModel.animateContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.7), value: viewModel.animateContent)
                }
                
                eventStartSection
                    .opacity(viewModel.animateContent ? 1 : 0)
                    .offset(y: viewModel.animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: viewModel.animateContent)
                
                // End Date Section
                endDateSection
                    .opacity(viewModel.animateContent ? 1 : 0)
                    .offset(y: viewModel.animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: viewModel.animateContent)
                
//                HStack {
//                    Spacer()
//                    endLiveButton
//                    Spacer()
//                }
                
                Spacer(minLength: 80)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .background(
                LinearGradient(
                    colors: [
                        Color.clear,
                        ThemeManager.backgroundColor.opacity(0.95),
                        ThemeManager.backgroundColor
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        
        // MARK: - Media Section
        private var mediaSectionLive: some View {
            Group {
                if let mediaFiles = viewModel.feedItem.mediaFiles, !mediaFiles.isEmpty {
                    VStack(spacing: 16) {
                        // Media Display with rounded corners and shadow
                        GeometryReader { geometry in
                            TabView(selection: $viewModel.currentMediaIndex) {
                                ForEach(Array(mediaFiles.enumerated()), id: \.offset) { index, media in
                                    mediaItemView(media: media, geometry: geometry)
                                        .tag(index)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .onChange(of: viewModel.currentMediaIndex) { _, newIndex in
                                viewModel.handleMediaChange(newIndex: newIndex)
                            }
                        }
                        .frame(height: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 16)
                        
                        // Enhanced Page Control
                        if mediaFiles.count > 1 {
                            enhancedPageControl(totalItems: mediaFiles.count)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
        
        private func mediaItemView(media: MediaFile, geometry: GeometryProxy) -> some View {
            Group {
                if media.type?.lowercased() == "video" {
                    videoPlayerView(url: media.url)
                } else {
                    imageView(url: media.url)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        
        private func videoPlayerView(url: String?) -> some View {
            ZStack {
                if let urlString = url, URL(string: urlString) != nil {
                    if let player = viewModel.player {
                        VideoPlayer(player: player)
                    } else {
                        loadingPlaceholder
                    }
                    
                    // Only show mute button when controls are visible
                    VStack {
                        HStack {
                            Spacer()
                            
                            // Mute/Unmute Button - Improved Design
                            if viewModel.showVideoControls {
                                Button(action: viewModel.toggleMute) {
                                    Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(.black.opacity(0.7))
                                                .overlay(
                                                    Circle()
                                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                                )
                                        )
                                        .scaleEffect(viewModel.showVideoControls ? 1.0 : 0.8)
                                }
                                .padding(.trailing, 20)
                                .padding(.top, 20)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                            }
                        }
                        Spacer()
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showVideoControls)
                } else {
                    videoUnavailablePlaceholder
                }
            }
        }
        
        private var loadingPlaceholder: some View {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        Text("Loading video...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                )
        }
        
        private var videoUnavailablePlaceholder: some View {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    VStack(spacing: 12) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Video unavailable")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                )
        }
        
        private func imageView(url: String?) -> some View {
            KFImage(URL(string: url ?? ""))
                .placeholder {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            VStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                                Text("Loading...")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        )
                }
                .resizable()
                .scaledToFill()
        }
        
        private func enhancedPageControl(totalItems: Int) -> some View {
            HStack(spacing: 12) {
                ForEach(0..<totalItems, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            index == viewModel.currentMediaIndex
                            ? LinearGradient(
                                colors: [ThemeManager.staticPinkColour, ThemeManager.staticPinkColour.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: index == viewModel.currentMediaIndex ? 24 : 8,
                            height: 8
                        )
                        .scaleEffect(index == viewModel.currentMediaIndex ? 1.0 : 0.8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentMediaIndex)
                        .onTapGesture {
                            viewModel.handlePageControlTap(index: index)
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.black.opacity(0.3))
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        
        // MARK: - User Info Section
        private var userInfoSection: some View {
            HStack(spacing: 16) {
                userProfileImage
                    .onTapGesture {
                        isPresented = false
                        viewModel.moveToUserProfileHome(for: viewModel.feedItem)
                    }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.feedItem.user?.userId == viewModel.currentUserId ? "You" : (viewModel.feedItem.user?.name ?? "Unknown"))
                        .fontStyle(size: 18, weight: .bold)
                        .foregroundColor(ThemeManager.foregroundColor)
                    
                    Text(viewModel.feedItem.user?.username ?? "")
                        .fontStyle(size: 14, weight: .medium)
                        .foregroundColor(ThemeManager.foregroundColor.opacity(0.7))
                    
                    activityTypeSection
                }
                
                Spacer()
                
                remainingLiveTime
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        
        private var userProfileImage: some View {
            KFImage(URL(string: viewModel.feedItem.user?.profilePicUrl ?? ""))
                .placeholder {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    ThemeManager.staticPinkColour.opacity(0.3),
                                    ThemeManager.staticPinkColour.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.title3)
                        )
                }
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [ThemeManager.staticPinkColour.opacity(0.5), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: ThemeManager.staticPinkColour.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        
        private var remainingLiveTime: some View {
            Group {
                if let result = HelperFunctions.convertUTCToISTAndCalculateDifference(utcString: viewModel.feedItem.endDate ?? "") {
                    VStack(spacing: 4) {
                        Text("Live End's in")
                            .fontStyle(size: 11, weight: .semibold)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(String(format: "%.1f", result.hoursFromNow)) hrs")
                            .fontStyle(size: 13, weight: .bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                    .scaleEffect(viewModel.animatePulse ? 1.05 : 1.0)
                    .opacity(viewModel.animatePulse ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: viewModel.animatePulse)
                }
            }
        }
        
        // MARK: - Interest Button View
        private var interestButtonView: some View {
            Button(action: viewModel.handleInterestTap) {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.interestButtonImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            viewModel.interestButtonImage == "heart.fill"
                            ? LinearGradient(
                                colors: [Color.white.opacity(0.9), Color.white],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : ThemeManager.gradientNewPinkBackground
                        )
                        .scaleEffect(viewModel.isInterestSelected ? 1.1 : 1.0)
                    
                    Text(viewModel.interestButtonTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(
                            viewModel.interestButtonImage == "heart.fill"
                            ? LinearGradient(
                                colors: [Color.white.opacity(0.9), Color.white],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : ThemeManager.gradientNewPinkBackground
                        )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Group {
                        if viewModel.interestButtonImage == "heart.fill" {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(ThemeManager.gradientNewPinkBackground)
                        } else {
                            Color.clear
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .strokeBorder(ThemeManager.gradientNewPinkBackground)
                )
                .shadow(
                    color: viewModel.isInterestSelected
                    ? ThemeManager.staticPinkColour.opacity(0.4)
                    : Color.clear,
                    radius: viewModel.isInterestSelected ? 12 : 0,
                    x: 0,
                    y: viewModel.isInterestSelected ? 6 : 0
                )
                .scaleEffect(viewModel.isInterestSelected ? 1.05 : 1.0)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        
        // MARK: - Activity Type Section
        private var activityTypeSection: some View {
            Group {
                if let tag = viewModel.feedItem.activityTags?.first?.subcategories?.first?.title {
                    HStack(spacing: 8) {
                        Image(systemName: DeveloperConstants.systemImage.figureWalking)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(tag)
                            .fontStyle(size: 14, weight: .semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.gray.opacity(0.8),
                                        Color.gray.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .shadow(color: Color.gray.opacity(0.3), radius: 6, x: 0, y: 3)
                }
            }
        }
        
        // MARK: - Interactive Stats Section
        private var interactiveStatsSection: some View {
            HStack(spacing: 0) {
                // Likes
             //   if let totalLikes = viewModel.feedItem.totalLikes {
                    Button(action: viewModel.handleLikeTap) {
                        statItemView(
                            icon: viewModel.feedItem.userContext?.hasLiked ?? false ? "heart.fill" : "heart",
                            color: .red,
                            count: viewModel.feedItem.totalLikes ?? 0,
                            label: "Likes"
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                     
                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.2))
              //  }
                
                // Comments
            //    if let totalComments = viewModel.feedItem.totalComments {
                    Button(action: viewModel.handleCommentTap) {
                        statItemView(
                            icon: "message.fill",
                            color: .blue,
                            count: viewModel.feedItem.totalComments ?? 0,
                            label: "Comments"
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.2))
           //     }
                
                // Joined
                if let totalJoined = viewModel.feedItem.joinedUserTags?.count {
                    Button(action: viewModel.handleJoinedTap) {
                        statItemView(
                            icon: "person.2.fill",
                            color: .green,
                            count: totalJoined,
                            label: "Joined"
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        
        private func statItemView(icon: String, color: Color, count: Int, label: String) -> some View {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(count)")
                        .fontStyle(size: 16, weight: .bold)
                        .foregroundColor(ThemeManager.foregroundColor)
                    
                    Text(label)
                        .fontStyle(size: 12, weight: .medium)
                        .foregroundColor(ThemeManager.foregroundColor.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        
        // MARK: - Caption Section
        private var captionSection: some View {
            Group {
                if let caption = viewModel.feedItem.caption, !caption.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "quote.bubble.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(ThemeManager.staticPinkColour)
                            
                            Text("Caption")
                                .fontStyle(size: 16, weight: .bold)
                                .foregroundColor(ThemeManager.foregroundColor)
                            
                            Spacer()
                        }
                        
                        Text(caption)
                            .fontStyle(size: 15, weight: .regular)
                            .foregroundColor(ThemeManager.foregroundColor.opacity(0.9))
                            .lineLimit(viewModel.isTextExpanded ? nil : 3)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.isTextExpanded)
                        
                        if viewModel.needsShowMoreButton(text: caption) {
                            Button(action: viewModel.toggleTextExpansion) {
                                Text(viewModel.isTextExpanded ? "Show Less" : "Show More")
                                    .fontStyle(size: 14, weight: .semibold)
                                    .foregroundColor(ThemeManager.staticPinkColour)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
            }
        }
        
        // MARK: - Tagged Users Section
        private func taggedUsersSection(_ taggedUsers: [PeopleTags]) -> some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ThemeManager.staticPinkColour)
                    
                    Text("Tagged Users")
                        .fontStyle(size: 16, weight: .bold)
                        .foregroundColor(ThemeManager.foregroundColor)
                    
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(taggedUsers, id: \.userId) { user in
                        taggedUserRow(user)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        
        private func taggedUserRow(_ user: PeopleTags) -> some View {
            HStack(spacing: 12) {
                KFImage(URL(string: user.profilePicUrl))
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.caption)
                            )
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .fontStyle(size: 14, weight: .semibold)
                        .foregroundColor(ThemeManager.foregroundColor)
                        .lineLimit(1)
                    
                    Text("\(user.username)")
                        .fontStyle(size: 12, weight: .medium)
                        .foregroundColor(ThemeManager.foregroundColor.opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .onTapGesture {
                isPresented = false
                viewModel.moveToTaggedUserProfile(for: user.userId)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
        
        // MARK: - Joined Users Section
        private func joinedUsersSection(_ joinedUsers: [PeopleTags]) -> some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                    
                    Text("Joined Users")
                        .fontStyle(size: 16, weight: .bold)
                        .foregroundColor(ThemeManager.foregroundColor)
                    
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(joinedUsers, id: \.userId) { user in
                        joinedUserRow(user)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        
        private func joinedUserRow(_ user: PeopleTags) -> some View {
            HStack(spacing: 12) {
                KFImage(URL(string: user.profilePicUrl))
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.caption)
                            )
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .fontStyle(size: 14, weight: .semibold)
                        .foregroundColor(ThemeManager.foregroundColor)
                        .lineLimit(1)
                    
                    Text("\(user.username)")
                        .fontStyle(size: 12, weight: .medium)
                        .foregroundColor(ThemeManager.foregroundColor.opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
        
        // MARK: - Event Start Section
        private var eventStartSection: some View {
            Group {
                if let startDate = viewModel.feedItem.eventDate {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.orange)
                            
                            Text("Event Start Details")
                                .fontStyle(size: 16, weight: .bold)
                                .foregroundColor(ThemeManager.foregroundColor)
                            
                            Spacer()
                        }
                        
                        if let formattedDate = HelperFunctions.convertUTCToISTAndCalculateDifference(utcString: startDate) {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange.opacity(0.8))
                                
                                Text(formattedDate.0)
                                    .fontStyle(size: 15, weight: .medium)
                                    .foregroundColor(ThemeManager.foregroundColor.opacity(0.9))
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "sun.dust.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.orange.opacity(0.8))
                            
                            Text("Total Duration \(viewModel.feedItem.liveDuration ?? "0")")
                                .fontStyle(size: 15, weight: .medium)
                                .foregroundColor(ThemeManager.foregroundColor.opacity(0.9))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
            }
        }
        
        // MARK: - End Date Section
        private var endDateSection: some View {
            Group {
                if let endDate = viewModel.feedItem.endDate {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                            
                            Text("Event End Details")
                                .fontStyle(size: 16, weight: .bold)
                                .foregroundColor(ThemeManager.foregroundColor)
                            
                            Spacer()
                        }
                        
                        if let formattedDate = HelperFunctions.convertUTCToISTAndCalculateDifference(utcString: endDate) {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red.opacity(0.8))
                                
                                Text(formattedDate.0)
                                    .fontStyle(size: 15, weight: .medium)
                                    .foregroundColor(ThemeManager.foregroundColor.opacity(0.9))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    // MARK: - Supporting Views and Extensions
    
    struct ScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
    
    struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
