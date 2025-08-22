//
//  TagActivityChipsScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 27-05-2025.
//
import SwiftUI

//// MARK: - Activity Chips
struct TagActivityChipsView: View {
    @Binding var selectedActivityList: ActivitiesModel
    
    @State private var isExpanded: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 8)
    ]
    private let rowHeight: CGFloat = 36
    private let collapsedRows: Int = 2
    let onDeleteTappedOnTag: (SubActivitiesModel) -> Void
    
    // Flatten all subcategories from categories into a single array
    private var allSubActivities: [SubActivitiesModel] {
        selectedActivityList.categories.flatMap { $0.subcategories }
    }
    
    var body: some View {
        if !allSubActivities.isEmpty {
            VStack(spacing: 8) {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(allSubActivities) { subactivity in
                        Button(action: {
                            removeSubActivity(subactivity)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: DeveloperConstants.systemImage.closeXmark)
                                    .font(.caption)
                                    .foregroundStyle(
                                        colorScheme == .light
                                        ? AnyShapeStyle(ThemeManager.gradientBackground)
                                        : AnyShapeStyle(ThemeManager.gradientNewPinkBackground)
                                    )
                                Text(subactivity.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(ThemeManager.foregroundColor)
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: 120, alignment: .leading)
                                    .frame(height: 30)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                            .fixedSize(horizontal: true, vertical: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .frame(
                    maxHeight: isExpanded ? .infinity : (rowHeight * CGFloat(collapsedRows) + CGFloat((collapsedRows - 1) * 8)),
                    alignment: .top
                )
                .clipped()
                
                if allSubActivities.count > 4 {
                    HStack {
                        Divider()
                            .frame(maxWidth: .infinity, maxHeight: 1)
                            .background(Color.gray.opacity(0.5))
                        
                        Button(action: { withAnimation { isExpanded.toggle() } }) {
                            Text(isExpanded ? Constants.viewLess : Constants.viewMore)
                                .fontStyle(size: 12, weight: .semibold)
                                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                                .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                            .frame(maxWidth: .infinity, maxHeight: 1)
                            .background(Color.gray.opacity(0.5))
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    // Remove the subactivity from selectedActivityList by filtering it out
    private func removeSubActivity(_ subactivity: SubActivitiesModel) {
        let newCategories = selectedActivityList.categories.map { category -> Activities in
            let filteredSubs = category.subcategories.filter { $0.id != subactivity.id }
            return Activities(id: category.id, name: category.name, subcategories: filteredSubs)
        }
        // Update the binding
        selectedActivityList = ActivitiesModel(categories: newCategories)
        // Callback
        onDeleteTappedOnTag(subactivity)
    }
}
