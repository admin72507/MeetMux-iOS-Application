//
//  CarousalScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 06-06-2025.
//

import SwiftUI

struct CarouselView: View {
    
    let feedItems: [PostItem]
    let isLoadingMore: Bool
    let onItemSelected: (PostItem) -> Void
    let onLoadMore: () -> Void
    let shouldLoadMore: (PostItem) -> Bool
    
    @State private var showDetailView = false
    @State private var focusedIndex: Int = 0
    @State private var lastFocusedIndex: Int? = nil
    @State private var selectedItem: PostItem? = nil
    @ObservedObject var viewModel: ExploreViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Loading indicator at top if loading more
            if isLoadingMore {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ThemeManager.staticPurpleColour))
                        .scaleEffect(0.8)
                    Text("Loading more...")
                        .fontStyle(size: 12, weight: .medium)
                        .foregroundColor(ThemeManager.foregroundColor.opacity(0.7))
                }
                .padding(.horizontal)
            }
            
            GeometryReader { proxy in
                let width = proxy.size.width
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: -10) {
                        ForEach(feedItems.indices, id: \.self) { index in
                            GeometryReader { geo in
                                let midX = geo.frame(in: .global).midX
                                let scale = calculateScale(midX: midX, screenWidth: width)
                                let zIndex = calculateZIndex(midX: midX, screenWidth: width)
                                
                                CardView(
                                    feedItem: feedItems[index],
                                    scale: scale,
                                    onCardTapped: {
                                       // onItemSelected(feedItems[index])
                                        selectedItem = feedItems[index]
                                    }, viewModel: viewModel
                                )
                                .sheet(item: $selectedItem) { item in
                                    carousalDetailView(for: item)
                                }
                                .presentationDetents([.medium, .large])
                                .presentationDragIndicator(.visible)
                                .frame(width: 320, height: 240)
                                .scaleEffect(scale)
                                .animation(.easeInOut(duration: 0.3), value: scale)
                                .zIndex(zIndex)
                                .onAppear {
                                    updateFocus(midX: midX, index: index, screenWidth: width)
                                    
                                    // Check if we should load more
                                    if shouldLoadMore(feedItems[index]) {
                                        onLoadMore()
                                    }
                                }
                                .onChange(of: midX) { _, newMidX in
                                    updateFocus(midX: newMidX, index: index, screenWidth: width)
                                }
                            }
                            .frame(width: 320, height: 240)
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.trailing, (width - 320) / 2)
                }
            }
            .frame(height: 280)
        }
        .onAppear {
            // Set the first item as focused when the view appears
            guard !feedItems.isEmpty else { return }
            focusedIndex = 0
            lastFocusedIndex = 0
            onItemSelected(feedItems[0])
        }
    }
    
    // MARK: - Update Focus
    private func updateFocus(midX: CGFloat, index: Int, screenWidth: CGFloat) {
        guard !feedItems.isEmpty else { return }
        
        if isFocused(midX: midX, screenWidth: screenWidth), focusedIndex != index {
            focusedIndex = index
            
            // Debounce to prevent frequent calls
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if lastFocusedIndex != index {
                    lastFocusedIndex = index
                    onItemSelected(feedItems[index])
                }
            }
        }
    }
    
    // MARK: - Scaling Effect
    private func calculateScale(midX: CGFloat, screenWidth: CGFloat) -> CGFloat {
        let distance = abs(midX - screenWidth / 2)
        return distance < 70 ? 1.0 : 0.8
    }
    
    // MARK: - Z-Index for Overlapping Below
    private func calculateZIndex(midX: CGFloat, screenWidth: CGFloat) -> Double {
        let distance = abs(midX - screenWidth / 2)
        return -distance / 10 // Normalized z-index
    }
    
    // MARK: - Focus Check
    private func isFocused(midX: CGFloat, screenWidth: CGFloat) -> Bool {
        return abs(midX - screenWidth / 2) < 70
    }
}

// MARK: - Extension
extension CarouselView {
    
    func carousalDetailView(for item: PostItem) -> some View {
        
        CardDetailView(
            feedItem: item,
            isPresented: Binding(
                get: { selectedItem != nil },
                set: { if !$0 { selectedItem = nil } }
            ),
            onEndActivity: {
                viewModel.removePost(item)
            },
            onDismiss: { receivedFeedItem in
                viewModel.updateCounts(receivedFeedItem: receivedFeedItem)
            }
        )
    }
}

