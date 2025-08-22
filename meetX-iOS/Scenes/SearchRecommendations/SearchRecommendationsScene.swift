//
//  SearchRecommendationsScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 30-05-2025.
//

import SwiftUI
import Kingfisher
import Combine

struct ImprovedSearchBar: View {
    @Binding var text: String
    let placeholder: String
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(placeholder, text: $text)
                    .onTapGesture {
                        isEditing = true
                    }
                    .onSubmit {
                        isEditing = false
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if isEditing {
                Button("Cancel") {
                    isEditing = false
                    text = ""
                    hideKeyboard()
                }
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isEditing)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct RecommendedUsersGridView: View {
    
    @StateObject private var viewModel = SearchRecommendationsObservable()
    @State private var isInitialLoad = true
    @State private var animationOffset: CGFloat = 50
    @State private var animationOpacity: Double = 0
    @State private var searchText: String = ""
    @State private var recentSearches: [String] = []
    
    @Environment(\.dismiss) private var dismiss
    
    let columns = [
        GridItem(.flexible())
    ]
    
    // Debounce publisher for search
    private let searchSubject = PassthroughSubject<String, Never>()
    
    var body: some View {
        ZStack {
            Color(ThemeManager.backgroundColor)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Search Bar (Fixed at top with proper spacing)
                ImprovedSearchBar(text: $searchText, placeholder: Constants.searchAndStartInteractingText)
                    .onChange(of: searchText) { _, newValue in
                        searchSubject.send(newValue)
                    }
                    .frame(height: 60)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .background(Color(ThemeManager.backgroundColor))
                    .zIndex(999) // Ensure search bar is always on top
                
                // MARK: - Scrollable Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // MARK: - Recent Searches (shown when search is active and no current search)
                        if !searchText.isEmpty && searchText.count < 2 && !recentSearches.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(Constants.recentSearchesText)
                                    .fontStyle(size: 14, weight: .semibold)
                                    .padding(.horizontal, 16)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(recentSearches, id: \.self) { recentSearch in
                                        RecentSearchRowView(searchText: recentSearch) {
                                            searchText = recentSearch
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        } else if !searchText.isEmpty && searchText.count < 2 && recentSearches.isEmpty {
                            Text(Constants.noRecentSearchesText)
                                .fontStyle(size: 14, weight: .regular)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                        }
                        
                        // MARK: - Search Results
                        if !searchText.isEmpty && searchText.count >= 2 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(Constants.searchResultsText)
                                    .fontStyle(size: 14, weight: .semibold)
                                    .padding(.horizontal, 16)
                                
                                if viewModel.searchUsersList.isEmpty && !viewModel.isLoading {
                                    EmptySearchResultsView()
                                        .transition(.asymmetric(
                                            insertion: .opacity.combined(with: .scale(scale: 0.8)),
                                            removal: .opacity
                                        ))
                                } else {
                                    LazyVStack(spacing: 12) {
                                        ForEach(Array(viewModel.searchUsersList.enumerated()), id: \.element.id) { index, user in
                                            SearchUserRowView(user: user) {
                                                addToRecentSearches(searchText)
                                                viewModel.moveToUserProfileHome(for: user)
                                            }
                                            .onAppear {
                                                if index >= viewModel.searchUsersList.count - 2 {
                                                    viewModel.loadMoreSearchResults()
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                                
                                if viewModel.isLoading {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                        Spacer()
                                    }
                                    .padding()
                                }
                            }
                        }
                        // MARK: - Recommended Users (shown when not searching)
                        else {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(Constants.suggestedConnectionsText)
                                    .fontStyle(size: 14, weight: .semibold)
                                    .padding(.horizontal, 16)
                                
                                if viewModel.recommendedUsersList.isEmpty && !isInitialLoad {
                                    EmptyStateViewRecommendedUsers()
                                        .transition(.asymmetric(
                                            insertion: .opacity.combined(with: .scale(scale: 0.8)),
                                            removal: .opacity
                                        ))
                                } else {
                                    LazyVGrid(columns: columns, spacing: 20) {
                                        ForEach(Array(viewModel.recommendedUsersList.enumerated()), id: \.element.id) { index, user in
                                            UserCardView(
                                                user: user,
                                                animationDelay: Double(index) * 0.1,
                                                viewModel: viewModel
                                            )
                                            .onAppear {
                                                if index >= viewModel.recommendedUsersList.count - 2 {
                                                    viewModel.getTheRecommendedUsers()
                                                }
                                            }
                                            .onTapGesture {
                                                // Add haptic feedback to distinguish from accidental taps
                                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                                impactFeedback.impactOccurred()
                                                viewModel.moveToUserProfileHome(for: user)
                                            }
                                            .contentShape(Rectangle()) // Define exact tap area
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 8) // Add spacing from search bar
                                    .opacity(animationOpacity)
                                    .offset(y: animationOffset)
                                    .animation(.easeOut(duration: 0.8), value: animationOpacity)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animationOffset)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .refreshable {
                    await refreshData()
                }
            }
        }
        .applyNavBarConditionally(
            shouldShow: true,
            title: Constants.searchAndRecommendationsText,
            subtitle: Constants.searchOrSuggestionsText,
            image: DeveloperConstants.systemImage.recommendationImage,
            onBackTapped: { dismiss() }
        )
        .onAppear {
            loadInitialData()
            loadRecentSearches()
        }
        .onReceive(
            searchSubject
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .removeDuplicates()
        ) { searchQuery in
            if searchQuery.isEmpty {
                viewModel.clearSearchResults()
            } else if searchQuery.count >= 2 {
                viewModel.searchRecommendations(searchQuery)
            }
        }
        // Fixed onTapGesture to use simple closure syntax
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func loadInitialData() {
        if isInitialLoad {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animationOpacity = 1
                animationOffset = 0
            }
            viewModel.getTheRecommendedUsers()
            isInitialLoad = false
        }
    }
    
    private func refreshData() async {
        if searchText.isEmpty {
            viewModel.currentPage = 1
            viewModel.getTheRecommendedUsers()
        } else if searchText.count >= 2 {
            viewModel.searchRecommendations(searchText)
        }
    }
    
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: DeveloperConstants.UserDefaultsInternal.searchRecentSearchesKey) ?? []
    }
    
    private func addToRecentSearches(_ search: String) {
        var searches = UserDefaults.standard.stringArray(forKey: DeveloperConstants.UserDefaultsInternal.searchRecentSearchesKey) ?? []
        
        searches.removeAll { $0 == search }
        
        searches.insert(search, at: 0)
        
        if searches.count > 10 {
            searches = Array(searches.prefix(10))
        }
        
        UserDefaults.standard.set(searches, forKey: DeveloperConstants.UserDefaultsInternal.searchRecentSearchesKey)
        recentSearches = searches
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Search User Row View
struct SearchUserRowView: View {
    let user: UserSearch
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Profile Image
                KFImage(URL(string: user.profilePicUrls ?? user.profilePicUrl ?? ""))
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .retry(maxCount: 3)
                    .cacheOriginalImage()
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name ?? "Unknown")
                        .fontStyle(size: 16, weight: .semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    let username = user.username?.usernameWithAt ?? "@unknown"
                    Text(username)
                        .fontStyle(size: 14, weight: .regular)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: DeveloperConstants.systemImage.chevronRight)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Recent Search Row View
struct RecentSearchRowView: View {
    let searchText: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: DeveloperConstants.systemImage.clockArrowCirclePath)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(searchText)
                    .fontStyle(size: 15, weight: .regular)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: DeveloperConstants.systemImage.arrowUpRight)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty Search Results View
struct EmptySearchResultsView: View {
    @State private var animationOffset: CGFloat = 30
    @State private var animationOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: DeveloperConstants.systemImage.questionMark)
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(Constants.noUsersFoundText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(Constants.noUsersFoundSubText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 40)
        .opacity(animationOpacity)
        .offset(y: animationOffset)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animationOpacity = 1
                animationOffset = 0
            }
        }
    }
}

// MARK: - Updated UserCardView with Follow/Connect Logic
struct UserCardView: View {
    let user: RecommendedUser
    let animationDelay: Double
    @ObservedObject var viewModel: SearchRecommendationsObservable
    
    @State private var isVisible = false
    @State private var isPressed = false
    @State private var showFollowAnimation = false
    
    private var cardHeight: CGFloat {
        380
    }
    
    var body: some View {
        ZStack {
            // ✅ Background Image
            KFImage(URL(string: user.profilePicUrls))
                .placeholder {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.6),
                                    Color.blue.opacity(0.4),
                                    Color.pink.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                .retry(maxCount: 3)
                .cacheOriginalImage()
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            
            // ✅ Overlay Gradient
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // ✅ Foreground Content
            VStack(spacing: 0) {
                // Header section
                HStack(alignment: .top, spacing: 12) {
                    KFImage(URL(string: user.profilePicUrls))
                        .placeholder {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .retry(maxCount: 3)
                        .cacheOriginalImage()
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.purple, Color.pink, Color.blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .scaleEffect(showFollowAnimation ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: showFollowAnimation)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .fontStyle(size: 16, weight: .semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        let formatted = user.username.usernameWithAt
                        Text(formatted)
                            .fontStyle(size: 13, weight: .regular)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer(minLength: 8)
                
                // Bottom stats and actions
                VStack(spacing: 12) {
                    
                    HStack(spacing: 4) {
                        Image(systemName: DeveloperConstants.systemImage.circleImage)
                            .foregroundColor(.green)
                            .scaleEffect(showFollowAnimation ? 1.2 : 1.0)
                        Text("Match - \(String(format: "%.2f", user.matchPercent ?? 0.0))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(ThemeManager.gradientNewPinkBackground)
                    .clipShape(Capsule())
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(animationDelay + 0.4), value: isVisible)
                    
                    // Stats
                    HStack {
                        VStack(spacing: 2) {
                            Text("\(user.postCount ?? 0)")
                                .fontStyle(size: 15, weight: .bold)
                                .foregroundColor(.white)
                            Text(Constants.postText)
                                .fontStyle(size: 10, weight: .medium)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text("\(user.followers ?? 0)")
                                .fontStyle(size: 15, weight: .bold)
                                .foregroundColor(.white)
                            Text(Constants.followersText)
                                .fontStyle(size: 10, weight: .medium)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text("\(user.following ?? 0)")
                                .fontStyle(size: 15, weight: .bold)
                                .foregroundColor(.white)
                            Text(Constants.followingText)
                                .fontStyle(size: 10, weight: .medium)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text("\(user.connections ?? 0)")
                                .fontStyle(size: 15, weight: .bold)
                                .foregroundColor(.white)
                            Text(Constants.connectionText)
                                .fontStyle(size: 10, weight: .medium)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 14)
                    
                    // Action buttons with same logic as profile view
                    handleInterestButton()
                }
                .padding(.bottom, 16)
            }
            .frame(width: UIScreen.main.bounds.width * 0.9, height: 380)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .clipped()
        }
        .frame(width: UIScreen.main.bounds.width * 0.9, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .clipped()
        .shadow(
            color: Color.black.opacity(0.2),
            radius: isVisible ? 8 : 4,
            x: 0,
            y: isVisible ? 4 : 2
        )
        .scaleEffect(isVisible ? 1 : 0.9)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(animationDelay), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
                showFollowAnimation = true
            }
        }
    }
    
    // MARK: - Handle Interest Button - Same logic as ProfileMeAndOthers
    @ViewBuilder
    func handleInterestButton() -> some View {
        HStack(spacing: 10) {
            
            // Follow button Logic - Same as your profile view
            if user.isFollowRequested == true {
                // Follow request is sent already then TITLE --> Follow Requested
                followConnectButton(
                    title: "Follow Requested",
                    icon: "",
                    backgroundColor: .clear,
                    borderColor: Color.orange,
                    onAction: {
                        viewModel.actionFollowButtonTypes.send((userId: user.userId, action: .cancelFollowRequest))
                    }
                )
            } else if user.isFollowing == false {
                // button title Follow
                followConnectButton(
                    title: "Follow",
                    icon: "",
                    backgroundColor: Color.clear,
                    borderColor: Color.white,
                    onAction: {
                        viewModel.actionFollowButtonTypes.send((userId: user.userId, action: .sendFollowRequest))
                    }
                )
            } else {
                // Both above conditions are opposite then user is already following
                followConnectButton(
                    title: "Unfollow",
                    icon: "",
                    backgroundColor: Color.clear,
                    borderColor: Color.red,
                    onAction: {
                        viewModel.actionFollowButtonTypes.send((userId: user.userId, action: .removeFollow))
                    }
                )
            }
            
            // MARK: - Connect Button - Same logic as your profile view
            if user.isConnectionRequested == true {
                // Connection request is sent already then TITLE --> Connection Requested
                followConnectButton(
                    title: "Connection Requested",
                    icon: "",
                    backgroundColor: ThemeManager.gradientNewPinkBackground,
                    borderColor: Color.clear,
                    onAction: {
                        viewModel.connectionActionButtonTypes.send((userId: user.userId, action: .removeConnectionRequest))
                    }
                )
            } else if user.isConnected == false {
                // Not connected - show Connect button
                followConnectButton(
                    title: "Connect",
                    icon: "",
                    backgroundColor: ThemeManager.gradientNewPinkBackground,
                    borderColor: Color.clear,
                    onAction: {
                        viewModel.connectionActionButtonTypes.send((userId: user.userId, action: .sendConnectionRequest))
                    }
                )
            } else {
                // User is already connected - show Remove Connection
                followConnectButton(
                    title: "Remove Connection",
                    icon: "",
                    backgroundColor: ThemeManager.gradientNewPinkBackground,
                    borderColor: Color.clear,
                    onAction: {
                        viewModel.connectionActionButtonTypes.send((userId: user.userId, action: .removeConnection))
                    }
                )
            }
        }
        .padding(.horizontal, 14)
    }
    
    // MARK: - Reusable button component - Fixed the background parameter
    @ViewBuilder
    func followConnectButton(
        title: String,
        icon: String,
        backgroundColor: any ShapeStyle,
        borderColor: Color,
        onAction: @escaping () -> Void
    ) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed.toggle()
            }
            
            onAction()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed.toggle()
                }
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(AnyShapeStyle(backgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor, lineWidth: borderColor == .clear ? 0 : 1.5)
            )
            .clipShape(Capsule())
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Original EmptyStateViewRecommendedUsers (unchanged)
struct EmptyStateViewRecommendedUsers: View {
    @State private var animationOffset: CGFloat = 30
    @State private var animationOpacity: Double = 0
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.2), Color.pink.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.purple.opacity(0.6))
            }
            
            VStack(spacing: 12) {
                Text("No Users Found")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("We couldn't find any recommended users at the moment.\nPull down to refresh and try again.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Animated refresh hint
            VStack(spacing: 8) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.purple)
                    .offset(y: animationOffset)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animationOffset)
                
                Text("Pull to refresh")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.purple)
            }
            .opacity(0.7)
        }
        .padding(.horizontal, 40)
        .opacity(animationOpacity)
        .offset(y: animationOffset)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animationOpacity = 1
                animationOffset = 0
            }
            pulseAnimation = true
        }
    }
}
