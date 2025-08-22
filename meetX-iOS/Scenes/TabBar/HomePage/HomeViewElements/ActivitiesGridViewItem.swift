//
//  ActivitiesGridViewItem.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 27-03-2025.
//
import SwiftUI

struct ActivitiesGridViewItem: View {
    
    let subActivity: SubActivitiesModel
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // Icon or Placeholder
            iconView
                .padding(.bottom, 10)
            
            // Title
            Text(truncatedTitle(subActivity.title))
                .fontStyle(size: 10, weight: isSelected ? .bold : .regular)
                .foregroundStyle(ThemeManager.foregroundColor)
                .lineLimit(1)
                .truncationMode(.tail)
            
            // Selection Indicator
            Rectangle()
                .frame(height: 2)
                .foregroundStyle(isSelected ? ThemeManager.gradientNewPinkBackground :
                                    LinearGradient(
                                        colors: [Color.clear.opacity(0.3), Color.clear.opacity(0.1)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                )
        }
        // Add back elevation animation
        .scaleEffect(isSelected ? 1.03 : 1.0)
    }
    
    @ViewBuilder
    private var iconView: some View {
        if let iconName = subActivity.iconIOS,
           !iconName.isEmpty,
           UIImage(systemName: iconName) != nil {
            
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40) // Fixed size to prevent layout jumping
                .foregroundStyle(isSelected
                                 ? AnyShapeStyle(ThemeManager.gradientNewPinkBackground)
                                 : AnyShapeStyle(Color.gray))
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .shadow(color: isSelected ? .black.opacity(0.3) : .clear,
                        radius: isSelected ? 4 : 0, x: 0, y: 2)
        } else {
            // Placeholder circle with first letter
            ZStack {
                Circle()
                    .fill(
                        isSelected
                        ? AnyShapeStyle(ThemeManager.gradientNewPinkBackground)
                        : AnyShapeStyle(Color.gray.opacity(0.3))
                    )
                    .frame(width: 40, height: 40) // Fixed size
                
                Text(String(subActivity.title.prefix(1)).uppercased())
                    .font(.system(size: isSelected ? 22 : 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .shadow(color: isSelected ? .black.opacity(0.3) : .clear,
                    radius: isSelected ? 4 : 0, x: 0, y: 2)
        }
    }
    
    func truncatedTitle(_ title: String) -> String {
        if title.count > 16 {
            let index = title.index(title.startIndex, offsetBy: 8)
            return String(title[..<index]) + "..."
        } else {
            return title
        }
    }
}

// MARK: - Alternative Version with Better Performance
struct ActivitiesGridViewItemOptimized: View {
    
    let subActivity: SubActivitiesModel
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // Icon Container with fixed frame to prevent layout shifts
            ZStack {
                if let iconName = subActivity.iconIOS,
                   !iconName.isEmpty,
                   UIImage(systemName: iconName) != nil {
                    
                    Image(systemName: iconName)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(isSelected
                                         ? AnyShapeStyle(ThemeManager.gradientNewPinkBackground)
                                         : AnyShapeStyle(Color.gray))
                } else {
                    Circle()
                        .fill(
                            isSelected
                            ? AnyShapeStyle(ThemeManager.gradientNewPinkBackground)
                            : AnyShapeStyle(Color.gray.opacity(0.3))
                        )
                        .overlay(
                            Text(String(subActivity.title.prefix(1)).uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
            .frame(width: 44, height: 44) // Fixed container size
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .shadow(color: isSelected ? .black.opacity(0.3) : .clear,
                    radius: isSelected ? 4 : 0, x: 0, y: 2)
            .padding(.bottom, 10)
            
            Text(truncatedTitle(subActivity.title))
                .fontStyle(size: 10, weight: isSelected ? .bold : .regular)
                .foregroundStyle(ThemeManager.foregroundColor)
                .lineLimit(1)
                .truncationMode(.tail)
            
            // Selection indicator
            Capsule()
                .frame(width: isSelected ? 30 : 0, height: 2)
                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                .opacity(isSelected ? 1 : 0)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
    }
    
    func truncatedTitle(_ title: String) -> String {
        if title.count > 16 {
            let index = title.index(title.startIndex, offsetBy: 8)
            return String(title[..<index]) + "..."
        } else {
            return title
        }
    }
}
