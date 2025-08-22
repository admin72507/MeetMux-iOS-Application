//
//  ExploreScene.swift
//  meetX-iOS
//
//  Simplified version to fix loading issues

import SwiftUI
import CoreLocation

struct ExploreScene: View {
    @Binding var isTabBarPresented: Bool
    @StateObject private var statefulViewModel: ExploreViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: ExploreViewModel, isTabBarPresented: Binding<Bool>) {
        _statefulViewModel = StateObject(wrappedValue: viewModel)
        self._isTabBarPresented = isTabBarPresented
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ThemeManager.backgroundColor.edgesIgnoringSafeArea(.top)
                VStack {
                    contentView
                }
                .customNavigationBarForExplore(
                    title: "Explore",
                    onTitleTapped: { statefulViewModel.recenter() },
                    onSearchTapped: {
                        statefulViewModel.routeManager.navigate(to: CreateRecommendedRoute())
                    },
                    filterTapped: {
                        if statefulViewModel.hasLocationAccess {
                            statefulViewModel.showFilterSection.toggle()
                        }
                    },
                    hideFilterButton: !statefulViewModel.hasLocationAccess || statefulViewModel.feedItems.isEmpty
                )
                navigationBarBackground(geometry: geometry)
                if !statefulViewModel.newPostsAvailable.isEmpty {
                    newPostNotificationBanner
                }
                if shouldShowCarousel {
                    CarouselView(
                        feedItems: statefulViewModel.feedItems,
                        isLoadingMore: statefulViewModel.isLoadingMore,
                        onItemSelected: { selectedItem in
                            statefulViewModel.selectFeedItem(selectedItem)
                        },
                        onLoadMore: {
                            statefulViewModel.loadMoreData()
                        },
                        shouldLoadMore: { item in
                            statefulViewModel.shouldLoadMore(for: item)
                        },
                        viewModel: statefulViewModel
                    )
                    .transition(.move(edge: .bottom))
                    .padding(.bottom, 60)
                }
            }
        }
        .sheet(isPresented: $statefulViewModel.showFilterSection) {
            FilterBottomSheetView(
                viewModel: statefulViewModel,
                isPresented: $statefulViewModel.showFilterSection
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            handleViewAppear()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                handleSceneActivation()
            }
        }
        .refreshable {
            await handlePullToRefresh()
        }
    }

    // MARK: - Content View (Simplified)
    @ViewBuilder
    private var contentView: some View {
        if !statefulViewModel.hasLocationAccess {
            locationDisabledView
        } else if statefulViewModel.isLoading {
            loadingView
        } else if statefulViewModel.feedItems.isEmpty {
            noActivitiesView
            mapView
        } else {
            mapView
        }
    }

    private var mapView: some View {
        GoogleMapView(
            locationManager: statefulViewModel.locationManager,
            recenterMap: $statefulViewModel.recenterMap,
            feedItems: statefulViewModel.feedItems,
            onInteraction: { _ in },
            selectedFeedItem: statefulViewModel.selectedFeedItem,
            shouldMoveToSelectedItem: true
        )
        .edgesIgnoringSafeArea(.all)
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ThemeManager.staticPurpleColour))
                .scaleEffect(1.5)

            Text("Loading nearby activities...")
                .font(.headline)
                .foregroundColor(ThemeManager.foregroundColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var locationDisabledView: some View {
        VStack(spacing: 30) {
            Image(systemName: "location.slash.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(ThemeManager.gradientNewPinkBackground)

            VStack(spacing: 16) {
                Text("Location Access Disabled")
                    .fontStyle(size: 16, weight: .semibold)
                    .foregroundColor(ThemeManager.foregroundColor)

                Text("Location access is currently disabled. Please enable it in Settings to explore nearby content.")
                    .fontStyle(size: 14, weight: .light)
                    .foregroundColor(ThemeManager.foregroundColor.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            VStack(spacing: 16) {
                Button(action: {
                    statefulViewModel.openAppSettings()
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text("Open Settings")
                    }
                    .fontStyle(size: 16, weight: .semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(ThemeManager.staticPurpleColour)
                    .cornerRadius(25)
                }

                Button(action: {
                    statefulViewModel.requestLocationAccess()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Check Again")
                    }
                    .fontStyle(size: 14, weight: .light)
                    .foregroundColor(ThemeManager.foregroundColor)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(ThemeManager.staticPurpleColour.opacity(0.1))
                    .cornerRadius(20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }

    private var noActivitiesView: some View {
        HStack(spacing: 20) {
            // Icon section
            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(ThemeManager.gradientNewPinkBackground)

            // Content section
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No Activities Nearby")
                        .fontStyle(size: 18, weight: .semibold)
                        .foregroundColor(ThemeManager.foregroundColor)

                    Text("Be the first to share what you're up to!")
                        .fontStyle(size: 14, weight: .regular)
                        .foregroundColor(ThemeManager.foregroundColor.opacity(0.7))
                }

                // Action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        statefulViewModel.routeManager.navigate(to: CreatePostRoute())
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Activity")
                        }
                        .fontStyle(size: 14, weight: .semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(ThemeManager.staticPurpleColour)
                        .cornerRadius(20)
                    }

                    Button(action: {
                        statefulViewModel.refreshData()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                        .fontStyle(size: 14, weight: .medium)
                        .foregroundColor(ThemeManager.foregroundColor.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                    }
                }

                // Error message
                if let errorMessage = statefulViewModel.errorMessage {
                    Text(errorMessage)
                        .fontStyle(size: 12, weight: .medium)
                        .foregroundColor(.red)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }


    private var newPostNotificationBanner: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    statefulViewModel.acknowledgeNewPosts()
                    statefulViewModel.recenter()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.white)
                        Text("\(statefulViewModel.newPostsAvailable.count) new post\(statefulViewModel.newPostsAvailable.count > 1 ? "s" : "")")
                            .fontStyle(size: 14, weight: .semibold)
                            .foregroundColor(.white)
                        Text("• Tap to view")
                            .fontStyle(size: 12, weight: .light)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(ThemeManager.staticPurpleColour)
                            .shadow(radius: 8)
                    )
                }
                .transition(.scale.combined(with: .opacity))
                Spacer()
            }
            .padding(.top, 120)
            Spacer()
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: statefulViewModel.newPostsAvailable.count)
    }

    // MARK: - Helper Views
    private func navigationBarBackground(geometry: GeometryProxy) -> some View {
        VStack {
            ThemeManager.backgroundColor
                .frame(height: HelperFunctions.hasNotch(in: geometry.safeAreaInsets) ? 110 : 70)
                .shadow(color: ThemeManager.staticPurpleColour.opacity(0.1), radius: 2, x: 0, y: 2)
                .edgesIgnoringSafeArea(.top)
            Spacer()
        }
    }

    // MARK: - Computed Properties
    private var shouldShowCarousel: Bool {
        !statefulViewModel.feedItems.isEmpty && statefulViewModel.hasLocationAccess
    }

    // MARK: - Event Handlers (Simplified)
    private func handleViewAppear() {
        print("🎬 ExploreScene appeared")
        if statefulViewModel.locationManager.authorizationStatus == .notDetermined {
            statefulViewModel.requestLocationAccess()
        } else if statefulViewModel.hasLocationAccess && statefulViewModel.feedItems.isEmpty && !statefulViewModel.isLoading {
            statefulViewModel.loadInitialData()
        }
    }

    private func handleSceneActivation() {
        // Don't auto-refresh on scene activation to prevent unnecessary loading
        print("🔄 App became active")
    }

    private func handlePullToRefresh() async {
        print("🔄 Pull to refresh")
        statefulViewModel.refreshData()
        while statefulViewModel.isLoading {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }
}
