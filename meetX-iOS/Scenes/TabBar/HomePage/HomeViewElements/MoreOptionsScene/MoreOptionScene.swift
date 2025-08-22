//
//  MoreOptionScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 06-06-2025.
//

import SwiftUI
import Kingfisher

// Updated MoreOptionsBottomSheet view to match chat options design:
struct MoreOptionsBottomSheet: View {
    let postId: String
    @ObservedObject var viewModel: HomeObservable
    @Binding var isPresented: Bool
    
    private var feedItem: PostItem? {
        return viewModel.feedItemsObjects?.posts?.first { $0.postID == postId }
    }
    
    private var isMyPost: Bool {
        let currentUserId = viewModel.getCurrentUserID
        return currentUserId == feedItem?.user?.userId
    }
    
    private var options: [OptionItem] {
        var optionsList: [OptionItem] = []
        
        guard let feedItem = feedItem else {
            return optionsList
        }
        
        // Visit Profile Option
        optionsList.append(
            OptionItem(
                icon: "person.circle",
                title: "Visit Profile",
                subtitle: "View this person's profile",
                iconColor: .orange,
                isDestructive: false,
                action: {
                    isPresented = false
                    viewModel.moveToUserProfileHome(for: feedItem)
                }
            )
        )
        
        // Post Details Option
        optionsList.append(
            OptionItem(
                icon: "doc.text",
                title: "Post Details",
                subtitle: "View all about this post",
                iconColor: .blue,
                isDestructive: false,
                action: {
                    isPresented = false
                    viewModel.moveToPostDetails(for: feedItem)
                }
            )
        )
        
        // Mute Post Option
        optionsList.append(
            OptionItem(
                icon: "speaker.slash",
                title: "Mute Post",
                subtitle: "Turn off notifications for this post",
                iconColor: .gray,
                isDestructive: false,
                action: {
                    isPresented = false
                    // Handle mute post action
                }
            )
        )
        
        // Report Post Option (only for other's posts)
        if !isMyPost {
            optionsList.append(
                OptionItem(
                    icon: "exclamationmark.triangle",
                    title: "Report Post",
                    subtitle: "Report this conversation",
                    iconColor: .red,
                    isDestructive: true,
                    action: {
                        isPresented = false
                        // Handle report post action
                        //   viewModel.actionHandler?(feedItem, .reportPost)
                    }
                )
            )
        }
        
        return optionsList
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 24)
            
            // Header
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    // User profile image with Kingfisher
                    KFImage(URL(string: feedItem?.user?.profilePicUrl ?? ""))
                        .placeholder {
                            Circle()
                                .fill(Color(.tertiarySystemGroupedBackground))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .fontStyle(size: 16, weight: .medium)
                                        .foregroundColor(.secondary)
                                )
                        }
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feedItem?.user?.name ?? "User")
                            .fontStyle(size: 16, weight: .semibold)
                            .foregroundColor(.primary)
                        
                        Text("Post Options")
                            .fontStyle(size: 14, weight: .light)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            
            // Options Card
            VStack(spacing: 0) {
                ForEach(options.indices, id: \.self) { index in
                    OptionRowView(option: options[index])
                    
                    // Add separator between options (except for last item)
                    if index < options.count - 1 {
                        Divider()
                            .padding(.leading, 52) // Align with text content
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 24)
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .presentationDetents([isMyPost ? .height(350) : .height(380)])
        .presentationDragIndicator(.hidden)
    }
}

// Data model for option items
struct OptionItem {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let isDestructive: Bool
    let action: () -> Void
}

// Updated helper view for option rows to match chat options design
struct OptionRowView: View {
    let option: OptionItem
    
    var body: some View {
        Button(action: option.action) {
            HStack(spacing: 16) {
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .fontStyle(size: 16, weight: .medium)
                        .foregroundColor(option.isDestructive ? .red : .primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(option.subtitle)
                        .fontStyle(size: 14, weight: .light)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Icon on the left
                Image(systemName: option.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: 24, height: 24)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// You'll also need to update your HomeObservable to handle the new actions.
// Add these cases to your action enum (wherever it's defined):

enum PostAction {
    case like
    case comment
    case share
    case moreOptions
    case editPost      // Add this
    case hidePost      // Add this
    case reportPost    // Add this
    case mutePost      // Add this
}
