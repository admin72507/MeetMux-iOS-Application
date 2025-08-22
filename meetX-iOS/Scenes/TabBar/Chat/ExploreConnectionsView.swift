//
//  ConnectListListView.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 10-07-2025.
//
import SwiftUI
import Kingfisher

struct ExploreConnectionsView: View {
    @ObservedObject var viewModel: ChatLandingObservable
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBarView(
                searchText: $searchText,
                isSearching: $isSearching,
                onSearchChanged: { query in
                    viewModel.searchConnections(query: query)
                }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            // Content
            if viewModel.isLoadingConnections && viewModel.connectionsList.isEmpty {
                // Loading state for initial load
                ConnectionsLoadingView()
            } else if viewModel.connectionsList.isEmpty && !viewModel.isLoadingConnections {
                // Empty state
                ConnectionsEmptyView(
                    searchText: searchText,
                    onRetry: {
                        viewModel.loadConnections()
                    }
                )
            } else {
                // Connections List
                ConnectionsListView(viewModel: viewModel)
            }
        }
        .onAppear {
            if viewModel.connectionsList.isEmpty {
                viewModel.loadConnections()
            }
        }
        .refreshable {
            viewModel.refreshConnections()
        }
    }
}

// MARK: - Search Bar
struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let onSearchChanged: (String) -> Void

    // Add debounce timer
    @State private var searchTimer: Timer?

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))

                TextField("Search connections...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .fontStyle(size: 14, weight: .regular)
                    .onSubmit {
                        onSearchChanged(searchText)
                    }
                    .onChange(of: searchText) { _, newValue in
                        // Cancel previous timer
                        searchTimer?.invalidate()

                        if newValue.isEmpty {
                            onSearchChanged("")
                        } else {
                            // Debounce search for non-empty text
                            searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                onSearchChanged(newValue)
                            }
                        }
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchTimer?.invalidate()
                        onSearchChanged("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)

            if isSearching {
                Button("Cancel") {
                    searchText = ""
                    searchTimer?.invalidate()
                    isSearching = false
                    onSearchChanged("")
                }
                .foregroundColor(.blue)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSearching)
    }
}

// MARK: - Connections List
struct ConnectionsListView: View {
    @ObservedObject var viewModel: ChatLandingObservable

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.connectionsList, id: \.userId) { connection in
                    ConnectionRowView(connection: connection)
                        .onTapGesture {
                            // Handle connection tap - navigate to chat or profile
                            handleConnectionTap(connection)
                        }
                        .onAppear {
                            // Load more when reaching near the end
                            if connection == viewModel.connectionsList.last {
                                viewModel.loadMoreConnections()
                            }
                        }
                }

                // Load More Button/Indicator
                if viewModel.canLoadMoreConnections {
                    if viewModel.isLoadingMoreConnections {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading more...")
                                .fontStyle(size: 14, weight: .regular)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 50)
                    } else {
                        Button(action: {
                            viewModel.loadMoreConnections()
                        }) {
                            Text("Load More")
                                .fontStyle(size: 14, weight: .regular)
                                .foregroundStyle(
                                    ThemeManager.gradientNewPinkBackground
                                )
                                .frame(height: 44)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func handleConnectionTap(_ connection: ConnectedUser) {
        HapticManager.trigger(.medium)
        viewModel.routeManager
            .navigate(
                to: ChatRoomRoute(
                    receiverId: connection.userId ?? "",
                    profilePicture: connection.profilePicUrl ?? ""
                )
            )
    }
}

// MARK: - Connection Row
struct ConnectionRowView: View {
    let connection: ConnectedUser
    @State private var imageLoadFailed: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            Circle()
                .stroke(
                    //  connection.isUserActive == true
                    //  ? Color.green
                    Color.gray.opacity(0.3),
                    // lineWidth: 2
                )
                .frame(width: 56, height: 56)
                .overlay(
                    KFImage(URL(string: connection.profilePicUrl ?? ""))
                        .onFailure { _ in
                            imageLoadFailed = true
                        }
                        .placeholder {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.gray)
                                )
                        }
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 50, height: 50)
                )

            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(connection.name ?? connection.username ?? "Unknown")
                    .fontStyle(size: 16, weight: .semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let username = connection.username {
                    Text("\(username)")
                        .fontStyle(size: 14, weight: .regular)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Action Button
            Button(action: {
                // Handle message action
                print("Message \(connection.name ?? "")")
            }) {
                Image(systemName: "message.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Loading View
struct ConnectionsLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<8, id: \.self) { _ in
                ConnectionRowSkeletonView()
            }
        }
        .padding(.horizontal, 16)
    }
}

struct ConnectionRowSkeletonView: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 12)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 10)
            }

            Spacer()

            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Empty View
struct ConnectionsEmptyView: View {
    let searchText: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: searchText.isEmpty ? "person.2.circle" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(ThemeManager.gradientNewPinkBackground)

            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Connections Found" : "No Results Found")
                    .fontStyle(size: 20, weight: .semibold)
                    .foregroundColor(.primary)

                Text(searchText.isEmpty
                     ? "Connect with people to start chatting"
                     : "Try searching with different keywords")
                .fontStyle(size: 16, weight: .regular)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }

            if searchText.isEmpty {
                Button(action: onRetry) {
                    Text("Retry")
                        .fontStyle(size: 16, weight: .regular)
                        .foregroundColor(.white)
                        .frame(width: 120, height: 44)
                        .background(ThemeManager.gradientNewPinkBackground)
                        .cornerRadius(22)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
}
