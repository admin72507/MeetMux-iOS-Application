//
//  MyLiveActivitiesAScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 08-06-2025.
//

import SwiftUI
import Combine

// MARK: - Main View
struct MyLiveActivitiesScene: View {
    @StateObject private var viewModel = MyLiveActivitiesObservable()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with segmented control
            VStack(spacing: 12) {
                HStack {
                    CustomSegmentedControl(
                        selectedSegment: $viewModel.selectedSegment,
                        titleProvider: { segment in segment.title },
                        showLiveIndicator: true,
                        onSegmentChanged: { index in
                            // FIXED: Corrected the segment mapping logic
                            viewModel.onSegmentChanged(to: index == 0 ? .plannedActivity : .liveActivity)
                        }
                    )
                    .frame(height: 48)
                }
                .padding(.horizontal, 20)
                
                // Quick stats bar
                HStack(spacing: 20) {
                    StatChipView(
                        title: "Planned",
                        count: viewModel.plannedCount,
                        color: .orange,
                        isSelected: viewModel.selectedSegment == .plannedActivity
                    )
                    
                    StatChipView(
                        title: "Live",
                        count: viewModel.liveCount,
                        color: .red,
                        isSelected: viewModel.selectedSegment == .liveActivity
                    )
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 16)
            .padding(.bottom, 12)
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Content area
            ZStack {
                if viewModel.isLoading && viewModel.allActivities.isEmpty {
                    LoadingView()
                } else if viewModel.filteredActivities.isEmpty {
                    EmptyStateViewMyLiveActivity(
                        selectedSegment: viewModel.selectedSegment,
                        onRefresh: {
                            viewModel.refreshData()
                        }
                    )
                } else {
                    handleScrollContent(viewModel: viewModel)
                }
            }
        }
        .generalNavBarInControlRoom(
            title: "My Live Activities",
            subtitle: "Make your presence felt",
            image: DeveloperConstants.systemImage.calenderImage,
            onBacktapped: { dismiss() }
        )
        .onAppear {
            if viewModel.allActivities.isEmpty {
                viewModel.loadInitialData()
            }
        }
        .toast(isPresenting: $viewModel.showToastMessage) {
            viewModel.helperFunctions.apiErrorToastCenter("My Live Activities!!!", viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $viewModel.showAllPeopleTag) {
            PeopleTagsDetailView(
                peopleTags: viewModel.peopleTagList,
                onUserTapAction: { receivedUser in
                    viewModel.moveToTaggedUserProfile(for: receivedUser.userId)
                },
                title: Constants.joinUserTitle
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showCommentsBottomSheet) {
            if let selectedPostID = viewModel.commentViewPostId,
               let index = viewModel.filteredActivities.firstIndex(where: { $0.postID == selectedPostID }) {
                CommentsBottomSheet(post: $viewModel.filteredActivities[index])
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Stat Chip View
struct StatChipView: View {
    let title: String
    let count: Int
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .opacity(isSelected ? 1.0 : 0.5)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .primary : .secondary)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(color.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text("Loading activities...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Enhanced Empty State View
struct EmptyStateViewMyLiveActivity: View {
    let selectedSegment: DeveloperConstants.MyLiveActivitisSegments
    let onRefresh: () -> Void
    
    private var emptyStateConfig: (icon: String, title: String, subtitle: String, gradient: [Color]) {
        switch selectedSegment {
            case .plannedActivity:
                return (
                    "calendar.badge.plus",
                    "No Planned Activities",
                    "Start planning your next adventure and connect with like-minded people!",
                    [.orange, .pink]
                )
            case .liveActivity:
                return (
                    "dot.radiowaves.left.and.right",
                    "No Live Activities",
                    "Go live now and share what you're doing in real-time!",
                    [.red, .purple]
                )
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: emptyStateConfig.gradient.map { $0.opacity(0.1) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: emptyStateConfig.icon)
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: emptyStateConfig.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text(emptyStateConfig.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(emptyStateConfig.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 32)
            }
            
            Button(action: onRefresh) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Refresh")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: emptyStateConfig.gradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: emptyStateConfig.gradient.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Enhanced Scroll Content
struct handleScrollContent: View {
    @ObservedObject var viewModel: MyLiveActivitiesObservable
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.filteredActivities, id: \.id) { activity in
                    ActivityCardView(
                        activity: activity,
                        onEndActivity: { activityId in
                            viewModel.handleEndPlannedLivePost(
                                activityId,
                                viewModel.selectedSegment
                            )
                        },
                        onOptionsPressed: { _ in
                            print("Options pressed")
                        }, onPeopleTagPressed: { receivedTags in 
                            viewModel.peopleTagList = receivedTags
                        }, onJoinedUserIconTapped: { receivedTags in
                            viewModel.peopleTagList = receivedTags
                        }, onLikeTapped: { postIdReceived in
                            viewModel.handleLikeLivePost(postId: postIdReceived)
                        }, onCommentsTapped: { selectedPostId in
                            viewModel.commentViewPostId = selectedPostId
                            viewModel.showCommentsBottomSheet.toggle()
                        }
                    )
                    .onAppear {
                        if let lastThreeActivities = Array(viewModel.filteredActivities.suffix(3)).first,
                           activity.id == lastThreeActivities.id {
                            viewModel.loadMoreIfNeeded()
                        }
                    }
                }
                
                if viewModel.isLoadingMore {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        Text("Loading more activities...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .refreshable {
            viewModel.refreshData()
        }
    }
}
