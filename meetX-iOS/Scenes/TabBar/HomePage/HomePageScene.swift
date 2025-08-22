//
//  HomePageScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-12-2024.
//

import SwiftUI
import DotLottie

struct HomePageScene: View {
    
    @Binding var isTabBarPresented: Bool
    @ObservedObject var viewModel: HomeObservable
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var showScrollToTopButton: Bool = false
    @State private var isFirstAppear = true
    @State private var dragStartOffset: CGFloat = 0
    
    init(
        isTabBarPresented: Binding<Bool>,
        viewModel: HomeObservable
    ) {
        self._isTabBarPresented = isTabBarPresented
        self.viewModel = viewModel
    }
    
    @ViewBuilder
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ThemeManager.backgroundColor.ignoresSafeArea()
                
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack {
                            TitleWithFadedDivider(title: Constants.passionsAndPursuitsText)
                                .padding(.leading, 16)
                            
                            if !viewModel.getDisplayedSubActivities().isEmpty {
                                displayedSubActivitiesView
                                    .padding(.vertical, 10)
                                    .padding(.leading, 10)
                            }
                            
                            TitleWithFadedDivider(title: Constants.liveAndTrendingText)
                                .padding(.leading, 16)
                            
                            segmentControlView()
                            
                            if viewModel.filteredPosts.count > 0 {
                                handleLiveActivityFeedItems()
                                    .id("feedItems")
                            } else {
                                VStack(spacing: 16) {
                                    LottieLoaderView(webURL: "https://lottie.host/30051391-364e-4bcd-b06a-9e54a7e1944a/8NXgZ149Q8.lottie")
                                        .frame(width: 200, height: 200)
                                    
                                    Text("No feeds available at the moment")
                                        .fontStyle(size: 14, weight: .light)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                            }
                        }
                        .scrollIndicators(.hidden)
                        .background(
                            GeometryReader { proxy in
                                let currentOffset = proxy.frame(in: .global).minY
                                Color.clear
                                    .onAppear {
                                        lastScrollOffset = currentOffset
                                    }
                                    .onChange(of: currentOffset) { oldValue, newValue in
                                        handleScrollOffsetChange(oldOffset: oldValue, newOffset: newValue)
                                    }
                            }
                        )
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                let translation = value.translation.height
                                handleDragScroll(translation: translation)
                            }
                            .onEnded { _ in
                                dragStartOffset = 0
                            }
                    )
                    .customHomeNavigationBar(
                        title: LocationStorage.isUsingCurrentLocation
                        ? viewModel.mainLocationName
                        : LocationStorage.mainLocationName,
                        subtitle: LocationStorage.isUsingCurrentLocation
                        ? viewModel.entireLocationName
                        : LocationStorage.entireLocationName,
                        hasNotification: false,
                        onTitleTapped: { viewModel.checkLocationAndOpenLocationSelector() },
                        onSearchTapped: {
                            viewModel.routeManager.navigate(to: CreateRecommendedRoute())
                        },
                        onNotificationTapped: {
                            viewModel.routeManager.navigate(to: NotificationSceneRoute())
                        }
                    )
                    .overlay(
                        scrollToTopOverlay(showButton: showScrollToTopButton, scrollProxy: scrollProxy)
                    )
                }
                .onAppear() {
                    UserDefaults.standard.set(true, forKey: "UserLoggedInNoOldLoginScreen")
                    viewModel.activateSocket()
                    // Reset scroll state on appear
                    isTabBarPresented = true
                    showScrollToTopButton = false
                    scrollOffset = 0
                    lastScrollOffset = 0
                }
                .onDisappear() {
                    viewModel.pauseSocket()
                }
                
                VStack {
                    ThemeManager.backgroundColor
                        .frame(height: HelperFunctions.hasNotch(in: geometry.safeAreaInsets) ? 110 : 70)
                        .shadow(color: ThemeManager.staticPurpleColour.opacity(0.1), radius: 2, x: 0, y: 2)
                        .edgesIgnoringSafeArea(.top)
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $viewModel.isShareSheetPresented) {
            ShareSheet(items: viewModel.shareItems)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showBottomSheet) {
            BottomSheetContent(
                title: Constants.locationAccessDisabled,
                subtitle: Constants.enableLocationText,
                message: Constants.locationAccessInstructions,
                primaryButtonTitle: Constants.openSettingsText,
                secondaryButtonTitle: "",
                primaryAction: { viewModel.openAppSettings() },
                secondaryAction: nil,
                hideSecondaryButton: true,
                showSheet: $viewModel.showBottomSheet
            )
            .presentationDragIndicator(.visible)
            .presentationDetents([.fraction(0.35)])
        }
        .sheet(isPresented: $viewModel.isLocationSelectionSheetPresent) {
            LocationSearchView { mainName,entireName,lat,lon in
                viewModel.mainLocationName = mainName
                viewModel.entireLocationName = entireName
                viewModel.latitude = lat
                viewModel.longitude = lon
                Loader.shared.stopLoading()
                viewModel.refreshData()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showCommentView) {
            if let selectedPostID = viewModel.commentViewPostId,
               let index = viewModel.filteredPosts.firstIndex(where: { $0.postID == selectedPostID }) {
                CommentsBottomSheet(
                    post: $viewModel.filteredPosts[index],
                    updateCountAction: { updatedCount in
                        viewModel.filteredPosts[index].totalComments = updatedCount
                        viewModel.updateCount(for: selectedPostID)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Scroll Handling Methods
    private func handleScrollOffsetChange(oldOffset: CGFloat, newOffset: CGFloat) {
        let offsetDifference = newOffset - oldOffset
        
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.3)) {
                if offsetDifference < -15 {
                    self.isTabBarPresented = false
                    if newOffset < -150 {
                        self.showScrollToTopButton = true
                    }
                } else if offsetDifference > 15 {
                    self.isTabBarPresented = true
                    self.showScrollToTopButton = false
                }
                
                if newOffset > -50 {
                    self.showScrollToTopButton = false
                }
                
                self.scrollOffset = newOffset
                VideoPlaybackManager.shared.pauseCurrent()
            }
        }
        
        lastScrollOffset = newOffset
    }
    
    private func handleDragScroll(translation: CGFloat) {
        if dragStartOffset == 0 {
            dragStartOffset = translation
        }
        
        let dragDifference = translation - dragStartOffset
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if dragDifference > 30 {
                isTabBarPresented = true
                showScrollToTopButton = false
            } else if dragDifference < -30 {
                isTabBarPresented = false
                if scrollOffset < -150 {
                    showScrollToTopButton = true
                }
            }
        }
    }
}

// MARK: - Extension
extension HomePageScene {
    
    // Common Segment Control
    func segmentControlView() -> some View {
        CustomSegmentedControl(
            selectedSegment: $viewModel.selectedSegment,
            titleProvider: { $0.title },
            showLiveIndicator: true,
            onSegmentChanged: { index in
                switch index {
                    case 0: viewModel.selectedSegment = .all
                    case 1: viewModel.selectedSegment = .plannedActivity
                    case 2: viewModel.selectedSegment = .liveActivity
                    default: viewModel.selectedSegment = .all
                }
            }
        )
        .frame(height: 45)
        .padding(.horizontal)
        .padding(.top, 10)
        .id("segmentControl")
    }
    
    // overlay
    func scrollToTopOverlay(
        showButton: Bool,
        scrollProxy: ScrollViewProxy
    ) -> some View {
        Group {
            if showButton {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                scrollProxy.scrollTo("segmentControl", anchor: .top)
                                // Reset tab bar state when scrolling to top
                                isTabBarPresented = true
                                showScrollToTopButton = false
                            }
                        }) {
                            Image(systemName: DeveloperConstants.systemImage.upArrowImage)
                                .font(.system(size: 24))
                                .foregroundColor(ThemeManager.foregroundColor)
                                .padding()
                                .background(ThemeManager.gradientNewPinkBackground)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
    }
    
    func handleLiveActivityFeedItems() -> some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.filteredPosts, id: \.postID) { Item in
                
                switch Item.feedType {
                    case .activityPlaned:
                        if Item.mediaFiles?.count ?? 0 > 0 {
                            PlannedActivityFeedItemScene(
                                viewModel: viewModel,
                                isLive: .constant(false),
                                postId: Item.postID ?? ""
                            )
                            .padding(.vertical, 20)
                            .id("\(Item.postID ?? "")")
                        } else {
                            PlannedActivitiesWithoutMediaScene(
                                viewModel: viewModel,
                                isLive: .constant(false),
                                postId: Item.postID ?? ""
                            )
                            .padding(.vertical, 10)
                            .id("\(Item.postID ?? "")")
                        }
                        
                    case .live:
                        PlannedActivityFeedItemScene(
                            viewModel: viewModel,
                            isLive: .constant(true),
                            postId: Item.postID ?? ""
                        )
                        .padding(.vertical, 20)
                        .id("\(Item.postID ?? "")")
                        
                    case .general:
                        if Item.mediaFiles?.count ?? 0 > 0 {
                            GeneralFeedItemScene(
                                viewModel: viewModel,
                                isLiveAnimating: .constant(false),
                                showBottomViewWithDescription: .constant(true),
                                postId: Item.postID ?? "",
                                viewHeight: UIScreen.main.bounds.height
                            )
                            .padding(.vertical, 10)
                            .id("\(Item.postID ?? "")")
                        } else {
                            GeneralPostWithOutMediaScene.create(
                                viewModel: viewModel,
                                isLiveAnimating: .constant(false),
                                showBottomViewWithDescription: .constant(true),
                                postId: Item.postID ?? "",
                                viewHeight: UIScreen.main.bounds.height
                            )
                            .id("\(Item.postID ?? "")")
                        }
                }
            }
        }
    }
}

extension HomePageScene {
    
    var displayedSubActivitiesView: some View {
        let displayedSubActivities = viewModel.getDisplayedSubActivities()
        
        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // "All" Button
                    ActivitiesGridViewItem(
                        subActivity: SubActivitiesModel(
                            mainCategoryId: 99009922991,
                            mainCategoryName: "All",
                            count: 0,
                            id: 99009922991,
                            title: "All",
                            icon: "square.grid.2x2",
                            iconIOS: "square.grid.2x2"
                        ),
                        isSelected: viewModel.selectedSubActivityID == 99009922991
                    )
                    .id(99009922991)
                    .onTapGesture {
                        // Fix 3: Prevent multiple taps on same item
                        guard viewModel.selectedSubActivityID != 99009922991 else { return }
                        
                        withAnimation {
                            Loader.shared.stopLoading()
                            viewModel.selectedSubActivityID = 99009922991
                            // Fix 2: Call refreshData() after setting the ID to ensure URL is created correctly
                            viewModel.refreshData()
                            proxy.scrollTo(99009922991, anchor: .center)
                        }
                    }
                    
                    ForEach(displayedSubActivities, id: \.id) { subActivity in
                        let isSelected = viewModel.selectedSubActivityID == subActivity.id
                        ActivitiesGridViewItem(
                            subActivity: subActivity,
                            isSelected: isSelected
                        )
                        .id(subActivity.id)
                        .onTapGesture {
                            // Fix 3: Prevent multiple taps on same item
                            guard viewModel.selectedSubActivityID != subActivity.id else { return }
                            
                            withAnimation {
                                Loader.shared.stopLoading()
                                viewModel.selectedSubActivityID = subActivity.id
                                viewModel.refreshData()
                                proxy.scrollTo(subActivity.id, anchor: .leading)
                            }
                        }
                    }
                    
                    if displayedSubActivities.count > 8 {
                        //  addMoreSubActivityView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    var addMoreSubActivityView: some View {
        ActivitiesGridViewItem(
            subActivity: SubActivitiesModel(
                mainCategoryId: 99009922993,
                mainCategoryName: "Show All",
                count: 0,
                id: 99009922993,
                title: "Show All",
                icon: "plus.circle",
                iconIOS: "plus.circle"
            ),
            isSelected: false
        )
        .onTapGesture {
            // Handle add more action
            print("Show All Categories tapped")
        }
    }
}
