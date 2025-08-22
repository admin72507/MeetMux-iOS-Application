//
//  InterestSelectionScreen.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 13-02-2025.
//

import SwiftUI

struct ActivitySelectionView: View {
    @Binding var searchText                 : String
    @Binding var selectedSubActivities      : Set<Int>
    @Binding var selectedMainActivities     : Set<Int>
    
    var fromPostCreationPlannedorLive: Bool
    let activityModel: ActivitiesModel
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]
    @State private var expandedCategories   : Set<Int> = []
    
    var filteredInterests: [SubActivitiesModel] {
        let allItems: [SubActivitiesModel]
        
        allItems = selectedMainActivities.isEmpty
        ? activityModel.categories.flatMap { $0.subcategories }
        : activityModel.categories
            .filter { selectedMainActivities.contains($0.id) }
            .flatMap { $0.subcategories }
        
        return searchText.isEmpty
        ? allItems.sorted { $0.title < $1.title }
        : allItems
            .filter { $0.title.lowercased().contains(searchText.lowercased()) }
            .sorted { $0.title < $1.title }
    }
    
    var body: some View {
        VStack {
            if filteredInterests.isEmpty {
                EmptyStateView(
                    imageName: DeveloperConstants.noResultImages.randomElement() ?? DeveloperConstants.systemImage.maginifyingGlassImage,
                    message: Constants.noSearchResultFound
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
//                        ForEach(activityModel.categories.sorted { $0.name < $1.name }, id: \.id) { activity in
//                            activitySectionView(for: activity)
//                        }
                        ForEach(
                            activityModel.categories,
                            id: \.id
                        ) { activity in
                            activitySectionView(for: activity)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Subviews and Logic
extension ActivitySelectionView {
    
    private func toggleSelection(_ interestID: Int) {
        withAnimation {
            if selectedSubActivities.contains(interestID) {
                selectedSubActivities.remove(interestID)
            } else {
                if fromPostCreationPlannedorLive {
                    selectedSubActivities.removeAll()
                    selectedSubActivities.insert(interestID)
                } else {
                    selectedSubActivities.insert(interestID)
                }
            }
        }
    }
    
    private func toggleCategoryExpansion(_ categoryID: Int) {
        withAnimation {
            if expandedCategories.contains(categoryID) {
                expandedCategories.remove(categoryID)
            } else {
                expandedCategories.insert(categoryID)
            }
        }
    }
    
    @ViewBuilder
    private func activitySectionView(for activity: Activities) -> some View {
        let categoryItems = filteredInterests.filter { subActivity in
            activity.subcategories.contains(where: { $0.id == subActivity.id })
        }
        let isExpanded = expandedCategories.contains(activity.id)
        let displayedItems = isExpanded ? categoryItems : Array(categoryItems.prefix(8))
        
        if !categoryItems.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(activity.name) - \(categoryItems.count)")
                    .fontStyle(size: 14, weight: .regular)
                    .padding(.leading)
                
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(displayedItems) { item in
                        InterestButton(
                            title: item.title,
                            icon: item.icon ?? "",
                            isSelected: selectedSubActivities.contains(item.id),
                            action: { toggleSelection(item.id) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        
        if categoryItems.count > 8 {
            expandCollapseButton(for: activity.id, isExpanded: isExpanded)
        }
    }
    
    @ViewBuilder
    private func expandCollapseButton(for activityId: Int, isExpanded: Bool) -> some View {
        HStack {
            Divider()
                .frame(maxWidth: .infinity, maxHeight: 1)
                .background(Color.gray.opacity(0.5))
            
            Button(action: {
                toggleCategoryExpansion(activityId)
            }) {
                Text(isExpanded ? Constants.viewLess : Constants.viewMore)
                    .fontStyle(size: 12, weight: .semibold)
                    .foregroundColor(ThemeManager.staticPurpleColour)
                    .padding(.horizontal, 8)
            }
            
            Divider()
                .frame(maxWidth: .infinity, maxHeight: 1)
                .background(Color.gray.opacity(0.5))
        }
        .padding(.horizontal)
        .padding(.top, 5)
    }
}

struct InterestButton: View {
    @Environment(\.colorScheme) private var currentTheme
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    private var textColor: Color {
        isSelected ? .white : (currentTheme == .light ? .black : .white)
    }
    
    private var backgroundColor: some View {
        Group {
            if isSelected {
                ThemeManager.gradientNewPinkBackground
            } else {
                Color.clear
            }
        }
    }
    
    private var borderColor: Color {
        isSelected ? .clear : ThemeManager.staticPurpleColour
    }
    
    private var shadowColor: Color {
        ThemeManager.staticPinkColour.opacity(0.5)
    }
    
    private var borderWidth: CGFloat {
        isSelected ? 0 : 1
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : ThemeManager.staticPinkColour)
                
                Text(title)
                    .fontStyle(size: 12, weight: .light)
                    .foregroundColor(textColor)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: 0.5)
            .cornerRadius(20)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}
