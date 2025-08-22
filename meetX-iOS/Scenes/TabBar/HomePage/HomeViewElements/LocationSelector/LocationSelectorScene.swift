//
//  LocationSelectorScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 19-05-2025.
//

import SwiftUI

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LocationObservable()
    var onSelectLocation: (
        _ mainName: String,
        _ entireName: String,
        _ lat: Double?,
        _ lon: Double?
    ) -> Void

    var body: some View {
        VStack(spacing: 0) {
            
            VStack(alignment: .leading, spacing: 8) {
                // MARK: - Title
                Text(Constants.chooseLocationText)
                    .fontStyle(size: 16, weight: .semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(Constants.chooseLocationSubtitle)
                    .fontStyle(size: 12, weight: .light)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding([.top, .leading])
            
            // MARK: - Search Bar
            HStack {
                TextField(Constants.searchLocations, text: $viewModel.searchText)
                    .padding(.vertical, 10)
                    .padding(.leading, 16)
                    .fontStyle(size: 14, weight: .light)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: DeveloperConstants.systemImage.closeXmark)
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 12)
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 8)
            
            // MARK: - Locate Me Button
            Button(action: {
                viewModel.useCurrentLocation()
            }) {
                HStack {
                    Image(systemName: DeveloperConstants.systemImage.locationCircleFill)
                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                    
                    Text(Constants.locateMeDescription)
                        .fontStyle(size: 14, weight: .light)
                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                }
                .frame(maxWidth: .infinity)
            }
            .background(ThemeManager.backgroundColor)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 8)
            
            // MARK: - Search Results / Recent Searches Container
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.searchText.isEmpty {
                        if viewModel.recentSearches.isEmpty {
                            Text(Constants.noRecentSearchText)
                                .fontStyle(size: 14, weight: .light)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        } else {
                            Text(Constants.recenctSearchText)
                                .fontStyle(size: 16, weight: .light)
                                .foregroundStyle(.gray)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.recentSearches, id: \.self) { item in
                                HStack(spacing: 5) {
                                    Image(systemName: DeveloperConstants.systemImage.locationMagnifyingglass)
                                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                                    
                                    Text(item)
                                        .fontStyle(size: 14, weight: .regular)
                                        .onTapGesture {
                                            viewModel.selectLocation(item)
                                        }
                                    
                                    Spacer()
                                
                                    Button(action: {
                                        viewModel.deleteRecentSearch(item)
                                    }) {
                                        Image(systemName: DeveloperConstants.systemImage.trashCan)
                                            .foregroundColor(.red)
                                            .fontWeight(.light)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }

                        }
                    } else {
                        if viewModel.searchResults.isEmpty {
                            Text("No search results found")
                                .fontStyle(size: 14, weight: .regular)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        } else {
                            Text("Choose from search results")
                                .fontStyle(size: 16, weight: .light)
                                .foregroundStyle(.gray)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.searchResults, id: \.self) { result in
                                HStack(spacing: 5) {
                                    Image(systemName: DeveloperConstants.systemImage.locationMagnifyingglass)
                                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                                    
                                    Text(result)
                                        .fontStyle(size: 14, weight: .regular)
                                        .onTapGesture {
                                            viewModel.selectLocation(result)
                                        }
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 4)
                )
                .padding(.horizontal)
            }
            .padding(.top, 8)
        }
        .onReceive(viewModel.locationSelected) { (mainName, entireName, lat, lon) in
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onSelectLocation(
                    mainName,
                    entireName,
                    lat,
                    lon
                )
            }
        }
        .background(ThemeManager.backgroundColor)
        .ignoresSafeArea(edges: .bottom)
    }
}
