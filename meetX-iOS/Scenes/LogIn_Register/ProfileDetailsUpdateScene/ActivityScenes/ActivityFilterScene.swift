//
//  InterestFilterScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 11-02-2025.
//

import SwiftUI

struct ActivityMainFilterView: View {
    
    @Environment(\.colorScheme) var deviceTheme
    @Binding var isPresented                    : Bool
    @Binding var selectedMainActivites          : Set<Int>
    @State private var searchText               : String = ""
    let activityModel                           : ActivitiesModel
    
    
    var filteredActivities: [Activities] {
        let allCategories = activityModel.categories.sorted { $0.name < $1.name }
        
        if searchText.isEmpty {
            return allCategories
        } else {
            return allCategories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text(Constants.filterByCategory)
                        .fontStyle(size: DeveloperConstants.General.mainHeadingSize, weight: .semibold)
                    
                    Text(Constants.filterByDesc)
                        .fontStyle(size: 12, weight: .light)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: DeveloperConstants.systemImage.closeXmark)
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            
            // Search Bar
            TextField("\(Constants.searchText) \(Constants.pageTitleMain)", text: $searchText)
                .keyboardType(.default)
                .padding()
                .fontStyle(size: 12, weight: .regular)
                .foregroundColor(ThemeManager.foregroundColor)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                .shadow(color: ThemeManager.staticPurpleColour.opacity(0.2), radius: 3, x: 0, y: 0)
                .padding(.horizontal, 20)
                .overlay(
                    HStack {
                        Spacer()
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: DeveloperConstants.systemImage.closeXmark)
                                    .foregroundColor(ThemeManager.staticPurpleColour)
                            }
                            .padding(.trailing, 30)
                        }
                    })
            
            Button(action : {
                selectedMainActivites.count > 0 ? selectedMainActivites.removeAll() : nil
            }) {
                Text("\(Constants.selectedMainActivites) \(selectedMainActivites.count)")
                    .fontStyle(size: 12, weight: .light)
                    .foregroundStyle(ThemeManager.foregroundColor)
                
                Text(Constants.resetButton)
                    .fontStyle(size: 14, weight: .semibold)
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
            }
            .padding(.top, 10)
            
            if filteredActivities.isEmpty {
                EmptyStateView(
                    imageName: DeveloperConstants.noResultImages.randomElement() ?? DeveloperConstants.systemImage.maginifyingGlassImage,
                    message: Constants.noSearchResultFound)
            }else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(filteredActivities, id: \.id) { category in
                            Button(action : {
                                toggleSelection(for: category.id)
                            }) {
                                Spacer()
                                HStack {
                                    Text(category.name)
                                        .fontStyle(size: 15, weight: .regular)
                                        .foregroundColor(selectedMainActivites.contains(category.id) ? ThemeManager.foregroundColor : .gray)
                                    Spacer()
                                    Image(
                                        systemName: selectedMainActivites.contains(category.id) ? DeveloperConstants.systemImage.circleImage : DeveloperConstants.systemImage.justCircleImage)
                                    .scaleEffect(selectedMainActivites.contains(category.id) ? 1.2 : 1.0)
                                    .opacity(selectedMainActivites.contains(category.id) ? 1 : 0.6)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedMainActivites.contains(category.id))
                                    .foregroundColor(ThemeManager.staticPurpleColour)
                                }
                                .frame(maxWidth : .infinity)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.all)
        .padding(.top, 20)
        .background(Color.dynamicBackground(for: deviceTheme))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func toggleSelection(for categoryID: Int) {
        if selectedMainActivites.contains(categoryID) {
            selectedMainActivites.remove(categoryID)
        } else {
            selectedMainActivites.insert(categoryID)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
