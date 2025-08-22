//
//  TagChipsView.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 27-05-2025.
//

import SwiftUI

// MARK: Support Views
// MARK: - Tag User connections
struct TagChipsView: View {
    @Binding var selectedTagConnections: Set<ConnectedUser>
    @State private var isExpanded: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]
    private let rowHeight: CGFloat = 36
    private let collapsedRows: Int = 2
    let onDeleteTappedOnTag: (ConnectedUser) -> Void
    
    var body: some View {
        if !selectedTagConnections.isEmpty {
            VStack(spacing: 8) {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(Array(selectedTagConnections), id: \.userId) { user in
                        Button(action: {
                            selectedTagConnections.remove(user)
                            onDeleteTappedOnTag(user)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: DeveloperConstants.systemImage.closeXmark)
                                    .font(.caption)
                                    .foregroundStyle(
                                        colorScheme == .light
                                        ? AnyShapeStyle(ThemeManager.gradientBackground)
                                        : AnyShapeStyle(ThemeManager.gradientNewPinkBackground)
                                    )
                                Text(user.username ?? "Unknown")
                                    .fontStyle(size: 12, weight: .semibold)
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
                if selectedTagConnections.count > 4 {
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
}
