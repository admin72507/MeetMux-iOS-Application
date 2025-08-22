//
//  FollowAndFollowers.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 22-05-2025.
//
import SwiftUI
import Kingfisher
import AlertToast

struct FollowAndFollowersScene: View {
    
    @StateObject private var viewModel = FollowFollowersObservable()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Always show search bar and segmented control
            VStack(spacing: 10) {
                SearchBar(
                    text: $viewModel.followFollowingSearchText,
                    searchText: viewModel.selectedSegment == .Following
                    ? Constants.searchFollowingText
                    : Constants.searchFollowersText
                )
                
                // Show segment control with counts if available
                HStack {
                    CustomSegmentedControl(
                        selectedSegment: $viewModel.selectedSegment,
                        titleProvider: { $0.title },
                        onSegmentChanged: { index in
                            print(index)
                        }
                    )
                    .frame(height: 45)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .padding(.top, 10)
            .background(ThemeManager.backgroundColor)
            
            // Show either results or no results view
            if viewModel.filteredConnections.isEmpty && !viewModel.isSearchLoading {
                noResultsView
            } else {
                connectionsListView
            }
        }
        .toast(isPresenting: $viewModel.showToastMessage) {
            HelperFunctions().apiErrorToastCenter(
                "Following and Followers", viewModel.errorMessage)
        }
        .generalNavBarInControlRoom(
            title: "Following and Followers",
            subtitle: "Check out your FOFO",
            image: DeveloperConstants.systemImage.fofoImage,
            onBacktapped: { dismiss() }
        )
    }
    
    private var noResultsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer()
                
                // Dynamic no results message based on current state
                VStack(spacing: 12) {
                    Image(systemName: getNoResultsIcon())
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text(getNoResultsTitle())
                        .fontStyle(size: 16, weight: .medium)
                        .foregroundColor(ThemeManager.foregroundColor)
                    
                    Text(getNoResultsMessage())
                        .fontStyle(size: 14, weight: .regular)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 300) // Ensure minimum height for tapping
        }
        .onTapGesture {
            // Hide keyboard when tapping on empty area
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // Helper functions for dynamic messages
    private func getNoResultsIcon() -> String {
        if !viewModel.followFollowingSearchText.isEmpty {
            return "magnifyingglass"
        }
        
        switch viewModel.selectedSegment {
            case .Following:
                return "person.2"
            case .Followers:
                return "person.3"
        }
    }
    
    private func getNoResultsTitle() -> String {
        if !viewModel.followFollowingSearchText.isEmpty {
            return "No Search Results"
        }
        
        switch viewModel.selectedSegment {
            case .Following:
                return "No Following"
            case .Followers:
                return "No Followers"
        }
    }
    
    private func getNoResultsMessage() -> String {
        if !viewModel.followFollowingSearchText.isEmpty {
            return "No results found for '\(viewModel.followFollowingSearchText)'. Try adjusting your search terms."
        }
        
        switch viewModel.selectedSegment {
            case .Following:
                return "You're not following anyone yet. Start connecting with people to see them here!"
            case .Followers:
                return "No one is following you yet. Share your profile to gain followers!"
        }
    }
    
    private var connectionsListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredConnections) { user in
                    ConnectionRowWrapper(
                        user: user,
                        segment: viewModel.selectedSegment,
                        onAction: {
                            // Trigger your action: Unfollow or Remove
                            print("\(viewModel.selectedSegment == .Following ? "Unfollow" : "Remove") \(user.name ?? "")")
                            Loader.shared.startLoading()
                            viewModel.handleUnfollow(user: user)
                        },
                        onLoadMore: {
                            viewModel.loadMoreIfNeeded(currentItem: user)
                        }, viewModel: viewModel
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 4)
            )
            .padding(.horizontal)
        }
        .gesture(
            // Hide keyboard when scrolling
            DragGesture()
                .onChanged { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
        .onTapGesture {
            // Hide keyboard when tapping on empty area
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private struct ConnectionRowWrapper: View {
        let user: FollowingFollowersItem
        let segment: DeveloperConstants.FollowFollowersList
        let onAction: () -> Void
        let onLoadMore: () -> Void
        
        var viewModel : FollowFollowersObservable
        
        var body: some View {
            ConnectionRowFollowUnfollow(
                user: user,
                segment: segment,
                onAction: onAction,
                viewModel: viewModel
            )
            .onAppear {
                onLoadMore()
            }
        }
    }
}

struct ConnectionRowFollowUnfollow: View {
    let user: FollowingFollowersItem
    let segment: DeveloperConstants.FollowFollowersList
    let onAction: () -> Void
    var viewModel : FollowFollowersObservable
    
    @State private var isPressed = false
    
    var actionLabel: String {
        switch segment {
            case .Following:
                return Constants.unFollow
            case .Followers:
                return Constants.followBackText
        }
    }
    
    var systemImage: String {
        switch segment {
            case .Following:
                return DeveloperConstants.systemImage.personUnFollowImage
            case .Followers:
                return DeveloperConstants.systemImage.personFollowBack
        }
    }
    
    var body: some View {
        HStack {
            userProfileImage
            
            VStack(alignment: .leading, spacing: 5) {
                Text(user.name ?? Constants.unknownText)
                    .fontStyle(size: 14, weight: .regular)
                    .foregroundColor(ThemeManager.foregroundColor)
                    .padding(.leading, 8)
                
                Text(user.username ?? Constants.unknownText)
                    .fontStyle(size: 12, weight: .light)
                    .foregroundColor(ThemeManager.foregroundColor)
                    .padding(.leading, 8)
            }
            .onTapGesture {
                viewModel.navigateToProfile(user)
            }
            
            Spacer()
            
            switch segment {
                case .Following:
                    Button(action: onAction) {
                        HStack(spacing: 4) {
                            Image(systemName: systemImage)
                            Text(actionLabel)
                        }
                        .fontStyle(size: 12, weight: .medium)
                        .foregroundColor(ThemeManager.foregroundColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(segment == .Following ? .gray.opacity(0.5) : ThemeManager.staticPinkColour.opacity(0.5))
                        .clipShape(Capsule())
                    }
                case .Followers:
                    if user.isFollowing == false {
                        Button(action: onAction) {
                            HStack(spacing: 4) {
                                Image(systemName: systemImage)
                                Text(actionLabel)
                            }
                            .fontStyle(size: 12, weight: .medium)
                            .foregroundColor(ThemeManager.foregroundColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(segment == .Following ? .gray.opacity(0.5) : ThemeManager.staticPinkColour.opacity(0.5))
                            .clipShape(Capsule())
                        }
                    }
            }
            
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
    
    private var userProfileImage: some View {
        Group {
            if let urlString = user.profilePicUrls, let url = URL(string: urlString) {
                let scale = UIScreen.main.scale
                KFImage(url)
                    .resizable()
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 40 * scale, height: 40 * scale)))
                    .cacheOriginalImage()
                    .loadDiskFileSynchronously()
                    .fade(duration: 0.25)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    .onTapGesture {
                        viewModel.navigateToProfile(user)
                    }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(user.name?.prefix(1) ?? "?")
                            .font(.headline)
                    )
                    .onTapGesture {
                        viewModel.navigateToProfile(user)
                    }
            }
        }
    }
}
