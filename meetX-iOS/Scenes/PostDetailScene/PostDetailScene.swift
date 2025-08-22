//
//  PostDetailScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-06-2025.
//

import SwiftUI
import Kingfisher

struct PostDetailScene: View {
    
    @StateObject var viewModel: PostDetailObservable
    @Environment(\.dismiss) private var dismiss
    @State private var isExpanded = false
    @State private var isAnimatingButton = false
    
    private var shouldShowExpandButton: Bool {
        (viewModel.feedItem?.caption?.count ?? 0) > 100
    }
    
    private var displayCaption: String {
        guard let caption = viewModel.feedItem?.caption, !caption.isEmpty else { return "" }
        
        if shouldShowExpandButton && !isExpanded {
            return String(caption.prefix(100)) + "..."
        }
        return caption
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if let feedItem = viewModel.feedItem {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        // Header with user info and post status
                        headerSection(feedItem: feedItem)
                        
                        // Media section
                        if let mediaFiles = feedItem.mediaFiles, !mediaFiles.isEmpty {
                            mediaSection(mediaFiles: mediaFiles)
                        }
                        
                        // Content section
                        contentSection(feedItem: feedItem)
                        
                        // Activity details section
                        activityDetailsSection(feedItem: feedItem)
                        
                        // Engagement section
                        engagementSection(feedItem: feedItem)
                    }
                }
            } else if viewModel.isLoading {
                loadingView
            } else if viewModel.errorMessage != nil {
                errorView
            }
        }
        .confirmationDialog("End Activity", isPresented: $viewModel.showEndConfirmation) {
            Button("End Activity", role: .destructive) {
                viewModel.handleEndPlannedLivePost(
                    viewModel.feedItem?.postID ?? "",
                    viewModel.isLiveActivity == true
                    ? .liveActivity
                    : .plannedActivity
                )
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to end this activity? \n \n Make sure to end it before it ends automatically, because once it ends, you won't be able to re-start it")
        }
        .confirmationDialog("Delete Post", isPresented: $viewModel.showDeletePostConfirmation) {
            Button("Delete Post", role: .destructive) {
                viewModel.getThePostDetail(
                    postId: viewModel.feedItem?.postID ?? "",
                    actiontype: "delete"
                )
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this post? \n\n Once deleted, this action cannot be undone.")
        }
        .sheet(isPresented: $viewModel.isShareSheetPresented) {
            ShareSheet(items: viewModel.shareItems)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.openCommentsPopUp) {
            if viewModel.feedItem != nil {
                CommentsBottomSheet(post: Binding(
                    get: { viewModel.feedItem! },
                    set: { viewModel.feedItem = $0 }
                ))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $viewModel.showAllPeopleTag) {
            PeopleTagsDetailView(
                peopleTags: viewModel.peopleTagList,
                onUserTapAction: { receivedUser in
                    viewModel.moveToTaggedUserProfile(for: receivedUser.userId)
                },
                title: viewModel.titlePopUp ?? "Tagged User"
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                if let postType = viewModel.feedItem?.postType {
                    postTypeBadge(postType: postType)
                }
            }
            
            if let feedItem = viewModel.feedItem {
                // End button for live/planned activities
                if viewModel.shouldShowEndButton() {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.endActivity()
                        }) {
                            Text("End Activity")
                                .fontStyle(size: 16, weight: .semibold)
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.red, lineWidth: 1)
                                )
                        }
                    }
                }
                
                // Delete button for inactive posts
                if viewModel.getCurrentUserID == feedItem.user?.userId {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.deletePost()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.getThePostDetail(postId: viewModel.postId)
        }
        .onDisappear {
            viewModel.updateCount()
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private func headerSection(feedItem: PostItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                // Profile picture using Kingfisher
                KFImage(URL(string: feedItem.user?.profilePicUrl ?? ""))
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                            )
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 5) {
                    if UserDataManager.shared.getSecureUserData().userId == feedItem.user?.userId {
                        Text("You")
                            .fontStyle(size: 16, weight: .semibold)
                            .foregroundColor(ThemeManager.foregroundColor)
                    } else {
                        Text(feedItem.user?.name ?? "")
                            .fontStyle(size: 16, weight: .semibold)
                            .foregroundColor(ThemeManager.foregroundColor)
                    }
                    
                    HStack(spacing: 8) {
                        Text(feedItem.user?.username ?? "")
                        Text("•")
                    }
                    .fontStyle(size: 12, weight: .regular)
                    .foregroundColor(.gray)
                    
                    TimeAgoText(utcString: "\(feedItem.eventDate ?? "")")
                        .fontStyle(size: 12, weight: .regular)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if !(feedItem.isActive ?? true) {
                    Button(action: {
                        //viewModel.endActivity()
                    }) {
                        Text("Expired Activity")
                            .fontStyle(size: 16, weight: .semibold)
                            .foregroundColor(ThemeManager.foregroundColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }
                }else {
                    if viewModel.getCurrentUserID != feedItem.user?.userId  && feedItem.postType?.lowercased() != "generalactivity" {
                        if feedItem.userContext?.hasShownInterest == true {
                            // Already requested and accepted
                            InterestButton(
                                title: Constants.interestedText,
                                icon: DeveloperConstants.systemImage.checkMark,
                                isSelected: feedItem.userContext?.hasShownInterest ?? true
                            ) {
                                viewModel.handleShowInterest(feedItem: feedItem)
                            }
                            .frame(width: 120)
                        }else if feedItem.userContext?.isInterestRequested == true {
                            // User already sent the request
                            InterestButton(
                                title: "Interest Requested",
                                icon: "hand.raised.fill",
                                isSelected: feedItem.userContext?.isInterestRequested ?? true
                            ) {
                                viewModel.handleShowInterest(feedItem: feedItem)
                            }
                            .frame(width: 120)
                        }else {
                            //normal button
                            InterestButton(
                                title: Constants.interestedText,
                                icon: DeveloperConstants.systemImage.plusImage,
                                isSelected: false
                            ) {
                                viewModel.handleShowInterest(feedItem: feedItem)
                            }
                            .frame(width: 120)
                        }
                    }else {
                        if feedItem.postType?.lowercased() != "generalactivity" {
                            makeEndActivityButton()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - End Activity Button
    @ViewBuilder
    private func makeEndActivityButton() -> some View {
        // End Activity Button - Always visible on top right
        Button(action: {
            viewModel.showEndConfirmation = true
        }) {
            HStack(spacing: 8) {
                // Dynamic icon based on activity type
                Image(systemName: viewModel.isLiveActivity ? "stop.circle.fill" : "calendar.badge.minus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(isAnimatingButton ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isAnimatingButton)
                
                Text(viewModel.isLiveActivity ? "End Live" : "Cancel Plan")
                    .fontStyle(size: 13, weight: .bold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Group {
                    if viewModel.isLiveActivity {
                        // Red gradient for live activities
                        LinearGradient(
                            colors: [ThemeManager.staticPinkColour, ThemeManager.staticPurpleColour],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        // Orange gradient for planned activities
                        LinearGradient(
                            colors: [ThemeManager.staticPinkColour, ThemeManager.staticPurpleColour],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: (viewModel.isLiveActivity ? Color.red : Color.orange).opacity(0.4),
                radius: isAnimatingButton ? 8 : 4,
                x: 0,
                y: isAnimatingButton ? 4 : 2
            )
            .scaleEffect(isAnimatingButton ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAnimatingButton)
        }
    }

    
    // MARK: - Media Section
    @ViewBuilder
    private func mediaSection(mediaFiles: [MediaFile]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(mediaFiles.enumerated()), id: \.offset) { index, mediaFile in
                    EnhancedMediaHandleView(
                        media: mediaFile,
                        index: index,
                        typeFrom: .PostDetail
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    
    // MARK: - Content Section
    @ViewBuilder
    private func contentSection(feedItem: PostItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let caption = feedItem.caption, !caption.isEmpty {
                Text("Caption")
                    .fontStyle(size: 16, weight: .semibold)
                    .foregroundColor(ThemeManager.foregroundColor)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(displayCaption)
                        .fontStyle(size: 12, weight: .medium)
                        .foregroundColor(ThemeManager.foregroundColor)
                        .lineLimit(isExpanded ? nil : 4)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                    
                    if shouldShowExpandButton {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(isExpanded ? "Show less" : "Show more")
                            }
                            .fontStyle(size: 12, weight: .semibold)
                            .foregroundStyle(
                                ThemeManager.gradientNewPinkBackground
                            )
                        }
                    }
                }
            }
            
            // Location
            locationSection(feedItem.location, feedItem.endDate ?? "")
            
            // Activity tags
            if let activityTags = feedItem.activityTags, !activityTags.isEmpty {
                activityTagsSection(activityTags)
            }
            
            // People tags
            if let peopleTags = feedItem.peopleTags, !peopleTags.isEmpty {
                peopleTagsView(peopleTags: peopleTags, title: "Tagged People")
            }
            
            // Joined user tags
            if let peopleTags = feedItem.joinedUserTags, !peopleTags.isEmpty {
                peopleTagsView(peopleTags: peopleTags, title: "Joined Users")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - Activity Tags
    @ViewBuilder
    private func activityTagsSection(_ activityTags: [ActivityTag]?) -> some View {
        if let tags = activityTags, !tags.isEmpty {
            
            // Flatten all subcategories
            let subcategories = tags.flatMap { $0.subcategories ?? [] }
            
            if !subcategories.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Activity Tags")
                        .fontStyle(size: 16, weight: .semibold)
                        .foregroundColor(ThemeManager.foregroundColor)
                    
                    FlowLayout(spacing: 10) {
                        ForEach(subcategories.prefix(12), id: \.id) { tag in
                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                    .font(.caption2)
                                Text(tag.title ?? "")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.12)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1.2
                                            )
                                    )
                            )
                            .foregroundStyle(
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                            )
                            .shadow(color: .blue.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                    }
                }
            }
        }
    }


    
    // MARK: - Location Section
    @ViewBuilder
    private func locationSection(_ location: String?, _ eventEndDate: String = "" ) -> some View {
        if let location = location, !location.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Location & End Date")
                    .fontStyle(size: 16, weight: .semibold)
                    .foregroundColor(ThemeManager.foregroundColor)
                
             //   if let location = location {
                    HStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .foregroundStyle(
                                LinearGradient(colors: [.pink, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .font(.system(size: 18, weight: .medium))
                            .frame(width: 24)
                        
                        Text(location)
                            .fontStyle(size: 12, weight: .regular)
                            .foregroundColor(ThemeManager.foregroundColor)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(ThemeManager.staticPinkColour.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(ThemeManager.staticPinkColour.opacity(0.15), lineWidth: 1.2)
                            )
                    )
               // }
                
                if eventEndDate != "" {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.circle.fill")
                            .foregroundStyle(
                                LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .font(.system(size: 18, weight: .medium))
                            .frame(width: 24)
                        
                        Text("\(HelperFunctions.convertUTCToISTAndCalculateDifference(utcString: eventEndDate)?.date ?? "")")
                            .fontStyle(size: 12, weight: .regular)
                            .foregroundColor(ThemeManager.foregroundColor)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(ThemeManager.staticPurpleColour.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(ThemeManager.staticPurpleColour.opacity(0.15), lineWidth: 1.2)
                            )
                    )
                }
            }
        }
    }
    
    // MARK: - Activity Details Section
    @ViewBuilder
    private func activityDetailsSection(feedItem: PostItem) -> some View {
        if let postType = feedItem.postType,
           (postType == "liveactivity" || postType == "plannedactivity") {
            
            VStack(spacing: 16) {
                Divider()
                    .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity Details")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let duration = HelperFunctions.convertUTCToISTAndCalculateDifference(utcString: feedItem.endDate ?? "") {
                        detailRow(icon: "clock", title: "End Time", value: feedItem.isActive == false ? "Expired Activity" : "\(String(format: "%.1f", duration.hoursFromNow)) hrs Left")
                    }

                    // Gender restriction
                    if let genderRestriction = feedItem.genderRestriction {
                        detailRow(icon: "person.2", title: "Gender Restriction", value: genderRestriction)
                    }
                    
                    // Visibility
                    if let visibility = feedItem.visibility {
                        detailRow(icon: "eye", title: "Visibility", value: visibility.capitalized)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Engagement Section
    @ViewBuilder
    private func engagementSection(feedItem: PostItem) -> some View {
       // private var bottomSection: some View {
            HStack(alignment: .center, spacing: 12) {
                // Enhanced Stats with better spacing and design
                HStack(spacing: 20) {
                    EnhancedStatView(
                        icon: feedItem.userContext?.hasLiked ?? false ? "heart.fill" : "heart",
                        count: feedItem.totalLikes ?? 0,
                        color: .red,
                        label: "Likes"
                    )
                    .onTapGesture {
                        viewModel.handleLikeLivePost(postId: feedItem.postID ?? "")
                    }
                    
                    EnhancedStatView(
                        icon: "bubble.left.fill",
                        count: feedItem.totalComments ?? 0,
                        color: .blue,
                        label: "Comments"
                    )
                    .onTapGesture {
                        viewModel.openCommentsPopUp.toggle()
                    }
                    
                    EnhancedStatView(
                        icon: "person.2.fill",
                        count: feedItem.totalJoinedUsers ?? 0,
                        color: .green,
                        label: "Joined"
                    )
                    .onTapGesture {
                        if feedItem.joinedUserTags?.count ?? 0 > 0 {
                            viewModel.peopleTagList = feedItem.joinedUserTags ?? []
                            viewModel.toggleInterest()
                        }
                    }
                    
                    EnhancedStatView(
                        icon: "sharedwithyou",
                        count: -1,
                        color: ThemeManager.foregroundColor,
                        label: "Share Post"
                    )
                    .onTapGesture {
                        viewModel.sharePost()
                    }
                }
                
                Spacer()
                
                // Enhanced Options Button
                Button(action: {
                   // onOptionsPressed(feedItem)
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(Color(.systemGray6))
                                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                                .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
                        )
                }
                .hidden()
                .scaleEffect(0.95)
                .animation(.easeInOut(duration: 0.15), value: false)
            }
            .padding(.leading, 20)
            .padding(.top, 20)
     //   }
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func postStatusBadge(isActive: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(isActive ? "Active" : "Inactive")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isActive ? .green : .red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill((isActive ? Color.green : Color.red).opacity(0.1))
        )
    }
    
    @ViewBuilder
    private func postTypeBadge(postType: String) -> some View {
        let (color, icon) = postTypeInfo(postType)
        
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            
            Text(postType.capitalized.replacingOccurrences(of: "activity", with: " Activity"))
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
        )
    }
        
    @ViewBuilder
    private func peopleTagsView(peopleTags: [PeopleTags], title: String) -> some View {
        if !peopleTags.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tagged People")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        
                        // Show first 8 tags
                        ForEach(peopleTags.prefix(8)) { person in
                            VStack(spacing: 4) {
                                KFImage(URL(string: person.profilePicUrl))
                                    .onFailure { _ in }
                                    .placeholder {
                                        initialsView(for: person.name)
                                    }
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        viewModel.moveToTaggedUserProfile(for: person.userId)
                                    }
                                
                                Text(person.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                            .frame(width: 50)
                        }
                        
                        // "+N more" Indicator if applicable
                        if peopleTags.count > 6 {
                            let remaining = peopleTags.count - 6
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    
                                    Text("+\(remaining)")
                                        .fontStyle(size: 12, weight: .bold)
                                        .foregroundColor(.primary)
                                }
                                
                                Text("More")
                                    .fontStyle(size: 11, weight: .medium)
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 50)
                        }
                    }
                    .onTapGesture {
                        // Move the user to pop up
                        viewModel.titlePopUp = title
                        viewModel.peopleTagList = peopleTags
                        viewModel.showAllPeopleTag.toggle()
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    private func initialsView(for name: String) -> some View {
        let firstLetter = String(name.prefix(1)).uppercased()
        
        return ZStack {
            Circle()
                .fill(Color.blue.opacity(0.3))
            
            Text(firstLetter)
                .fontStyle(size: 16, weight: .bold)
                .foregroundColor(.white)
        }
        .frame(width: 40, height: 40)
    }

    @ViewBuilder
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontStyle(size: 13, weight: .regular)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .fontStyle(size: 15, weight: .medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func engagementButton(icon: String, count: Int, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text("\(count)")
                    .fontStyle(size: 13, weight: .medium)
                    .foregroundColor(.secondary)
            }
        }
        .disabled(!(viewModel.feedItem?.isActive ?? true))
    }
        
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading post details...")
                .fontStyle(size: 16, weight: .light)
                .foregroundColor(.secondary)
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Error loading post")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Retry") {
                viewModel.getThePostDetail(postId: viewModel.postId)
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(40)
    }
    
    // MARK: - Helper Functions
    // Remove the helper functions that are now in the ViewModel
    
    private func postTypeInfo(_ postType: String) -> (Color, String) {
        switch postType {
            case "liveactivity":
                return (.red, "dot.radiowaves.left.and.right")
            case "plannedactivity":
                return (.orange, "calendar.badge.clock")
            default:
                return (.blue, "text.bubble")
        }
    }
}
