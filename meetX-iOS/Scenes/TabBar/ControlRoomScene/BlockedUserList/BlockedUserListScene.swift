//
//  BlockedUserListScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 25-05-2025.
//
import SwiftUI
import Kingfisher

struct BlockedUserListScene: View {
    @StateObject var viewModel: BlockedUsersObservable = .init()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Always show search bar
            searchBar
                .padding(.top, 16)
                .padding(.bottom, 16)
            
            // Show either results or no results view
            if viewModel.filteredConnections.isEmpty {
                noResultsView
            } else {
                Text(Constants.blockedUserListText)
                    .padding(.leading, 16)
                    .fontStyle(size: 12, weight: .light)
                    .foregroundStyle(.gray)
                
                connectionsListView
            }
        }
        .applyNavBarConditionally(
            shouldShow: true,
            title: Constants.blockedUserList,
            subtitle: Constants.blockerUsersSubtitleText,
            image: DeveloperConstants.systemImage.blockedUserList,
            onBackTapped: { dismiss() }
        )
        .confirmationDialog(
            dialogTitle,
            isPresented: $viewModel.showActionSheet,
            titleVisibility: .visible
        ) {
            if let user = viewModel.userToModify {
                Button("Unblock \(user.name ?? "this user")", role: .destructive) {
                    viewModel.performAction()
                }
            }
            
            Button(Constants.cancelText, role: .cancel) {
                viewModel.clearAction()
            }
        }
    }
    
    private var dialogTitle: String {
        guard let user = viewModel.userToModify else { return "" }
        return "Unblock \(user.name ?? "user") \(Constants.unblockContentSubtitle)"
    }
    
    private var searchBar: some View {
        SearchBar(text: $viewModel.searchText, searchText: Constants.searchBlockedUsersText)
    }
    
    private var noResultsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer()
                
                // Dynamic no results message based on search state
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
        if !viewModel.searchText.isEmpty {
            return "magnifyingglass"
        }
        return "person.badge.minus"
    }
    
    private func getNoResultsTitle() -> String {
        if !viewModel.searchText.isEmpty {
            return "No Search Results"
        }
        return "No Blocked Users"
    }
    
    private func getNoResultsMessage() -> String {
        if !viewModel.searchText.isEmpty {
            return "No results found for '\(viewModel.searchText)'. Try adjusting your search terms."
        }
        return "You haven't blocked anyone yet. Blocked users will appear here when you block them."
    }
    
    private var connectionsListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.filteredConnections.enumerated()), id: \.element.userId) { index, user in
                    ConnectionRowWrapper(
                        user: user,
                        index: index,
                        totalCount: viewModel.filteredConnections.count,
                        onUnblock: {
                            viewModel.prepareAction(for: user)
                        },
                        onLoadMore: {
                            viewModel.loadMoreConnections()
                        },
                        onLoadMoreSearch: {
                            viewModel.loadMoreSearchResults()
                        },
                        isSearching: !viewModel.searchText.isEmpty,
                        viewModel: viewModel
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
        let user: BlockedUser
        let index: Int
        let totalCount: Int
        let onUnblock: () -> Void
        let onLoadMore: () -> Void
        let onLoadMoreSearch: () -> Void
        let isSearching: Bool
        var viewModel: BlockedUsersObservable
        
        var body: some View {
            ConnectionRowSimpleUnblock(user: user, onUnblock: {
                onUnblock()
            }, viewModel: viewModel)
            .onAppear {
                if index == totalCount - 1 {
                    if isSearching {
                        onLoadMoreSearch()
                    } else {
                        onLoadMore()
                    }
                }
            }
        }
    }
}

struct ConnectionRowSimpleUnblock: View {
    let user: BlockedUser
    let onUnblock: () -> Void
    
    var viewModel: BlockedUsersObservable
    @State private var isPressed = false
    
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
            
            Button(action: onUnblock) {
                HStack(spacing: 4) {
                    Image(systemName: DeveloperConstants.systemImage.personUnblockImage)
                    Text(Constants.unBlocktext)
                }
                .fontStyle(size: 12, weight: .medium)
                .foregroundColor(ThemeManager.foregroundColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.gray.opacity(0.5))
                .clipShape(Capsule())
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
            if let urlString = user.profilePicUrl, let url = URL(string: urlString) {
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
            }
        }
    }
}
