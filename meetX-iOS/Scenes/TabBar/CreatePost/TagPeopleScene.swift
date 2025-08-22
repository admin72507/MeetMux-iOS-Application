import SwiftUI
import Combine
import Foundation
import Kingfisher

struct TagPeopleScene: View {
    @ObservedObject var viewModel: TagPeopleViewModel
    @Environment(\.dismiss) private var dismiss
    
    let isNavigationFromMenu: Bool
    
    @State private var userToDelete: ConnectedUser?
    @State private var showDeleteConfirmation: Bool = false
    
    // Helper function to dismiss keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header - always show when not from menu
            if !isNavigationFromMenu {
                headerView
            }
            
            // Search bar - always present to maintain keyboard state
            searchBar
                .padding(.top, isNavigationFromMenu ? 16 : 0)
                .padding(.bottom, isNavigationFromMenu ? 16 : 0)
            
            // Subtitle for menu navigation
            if isNavigationFromMenu {
                Text(Constants.tagUserSubtitleText)
                    .padding(.leading, 16)
                    .fontStyle(size: 12, weight: .light)
                    .foregroundStyle(.gray)
            }
            
            // Selection summary - only when not from menu and has connections
            if !isNavigationFromMenu && !viewModel.filteredConnections.isEmpty {
                selectionSummaryView
            }
            
            // Content area - either connections list or no results
            if viewModel.filteredConnections.isEmpty {
                noResultsView
            } else {
                connectionsListView
            }
        }
        .contentShape(Rectangle()) // Make entire view tappable
        .onTapGesture {
            // Dismiss keyboard when tapping outside search bar
            hideKeyboard()
        }
        .onAppear {
            viewModel.loadInitialConnections()
        }
        .applyNavBarConditionally(
            shouldShow: isNavigationFromMenu,
            title: Constants.connectListTitle,
            subtitle: Constants.browseConnectionsText,
            image: DeveloperConstants.systemImage.clockFill,
            onBackTapped: { dismiss() }
        )
        .toast(isPresenting: $viewModel.showSingleBlockUserAlert) {
            HelperFunctions().apiErrorToastCenter(
                "User Blocked Status!!",
                viewModel.responseMessage
            )
        }
        .confirmationDialog(
            dialogTitle,
            isPresented: $viewModel.showActionSheet,
            titleVisibility: .visible
        ) {
            if let user = viewModel.userToModify {
                if viewModel.actionType == .delete {
                    Button("Remove \(user.name ?? "this user")", role: .destructive) {
                        viewModel.performAction()
                    }
                } else if viewModel.actionType == .block {
                    Button("Block \(user.name ?? "this user")", role: .destructive) {
                        viewModel.performAction()
                    }
                }
            }
            Button(Constants.cancelText, role: .cancel) {
                viewModel.clearAction()
            }
        }
    }
    
    private var dialogTitle: String {
        guard let user = viewModel.userToModify else { return "" }
        
        switch viewModel.actionType {
            case .delete:
                return "Remove \(user.name ?? "user") from your connections?"
            case .block:
                return "Block \(user.name ?? "user") from interacting with you?"
            case .none:
                return ""
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Constants.tagConnectionsTitle)
                .fontStyle(size: 16, weight: .semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(Constants.tagSubtitle)
                .fontStyle(size: 12, weight: .light)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding([.top, .leading])
    }
    
    private var searchBar: some View {
        SearchBar(
            text: $viewModel.searchText,
            searchText: Constants.searchConnectionText
        )
    }
    
    private var selectionSummaryView: some View {
        HStack(spacing: 8) {
            Text("\(Constants.connectionsSelected) \(viewModel.selectedConnections.count)")
                .fontStyle(size: 12, weight: .light)
            
            if !viewModel.selectedConnections.isEmpty {
                Button(Constants.resetSelectedList) {
                    withAnimation {
                        viewModel.resetSelections()
                    }
                }
                .fontStyle(size: 14, weight: .semibold)
                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    
    private var noResultsView: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()
            Text(Constants.noConnectionsFound)
                .fontStyle(size: 14, weight: .regular)
                .foregroundColor(.gray)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle()) // Make tappable for keyboard dismissal
    }
    
    private var connectionsListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.filteredConnections.enumerated()), id: \.element.userId) { index, user in
                    ConnectionRow(
                        user: user,
                        isSelected: viewModel.isSelected(user),
                        isFromMenu: isNavigationFromMenu,
                        onToggle: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.toggleSelection(for: user)
                            }
                        },
                        onDelete: {
                            viewModel.prepareAction(for: user, type: .delete)
                        },
                        onBlock: {
                            viewModel.prepareAction(for: user, type: .block)
                        },
                        onProfileNavigate: {
                            isNavigationFromMenu == true ? nil : dismiss()
                            viewModel.navigateToProfile(user)
                        }
                    )
                    .onAppear {
                        if index == viewModel.filteredConnections.count - 1 {
                            viewModel.loadMoreConnections()
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 4)
            )
            .padding(.horizontal)
        }
        .simultaneousGesture(
            // Dismiss keyboard when scrolling starts
            DragGesture()
                .onChanged { _ in
                    hideKeyboard()
                }
        )
    }
}

struct ConnectionRow: View {
    let user: ConnectedUser
    let isSelected: Bool
    let isFromMenu: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onBlock: () -> Void
    let onProfileNavigate: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if !isFromMenu {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onToggle()
                }
            }
        }) {
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
                    onProfileNavigate()
                }
                
                Spacer()
                
                if isFromMenu {
                    actionMenuButton
                } else {
                    selectionIcon
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                    }
                }
        )
    }
    
    private var userProfileImage: some View {
        Group {
            if let urlString = user.profilePicUrl,
               let url = URL(string: urlString) {
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
                        onProfileNavigate()
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
                        onProfileNavigate()
                    }
            }
        }
    }
    
    private var selectionIcon: some View {
        Image(systemName: isSelected
              ? DeveloperConstants.systemImage.circleImage
              : DeveloperConstants.systemImage.justCircleImage)
        .resizable()
        .frame(width: 20, height: 20)
        .foregroundColor(isSelected ? ThemeManager.staticPinkColour : .gray)
    }
    
    private var actionMenuButton: some View {
        Menu {
            Button(role: .none) {
                onDelete()
            } label: {
                Label("Remove Connection", systemImage: "person.fill.badge.minus")
            }
            
            Button(role: .none) {
                onBlock()
            } label: {
                Label("Block Connection", systemImage: "person.slash.fill")
            }
        } label: {
            Image(systemName: DeveloperConstants.systemImage.editOptionForPostAction)
                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                .frame(width: 30, height: 30)
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    let searchText: String
    
    var body: some View {
        HStack {
            TextField(searchText, text: $text)
                .padding(.vertical, 10)
                .padding(.leading, 16)
                .fontStyle(size: 14, weight: .light)
                .focused($isFocused)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    // Keep keyboard focused when clearing text
                    // isFocused remains true
                }) {
                    Image(systemName: DeveloperConstants.systemImage.closeXmark)
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 12)
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
