//
//  InterestDetailScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 11-02-2025.
//

import SwiftUI

struct ActivitiesSelectionScene: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var expandedCategories       : Set<String>   = []
    @State var isFilterViewShown                : Bool          = false
    @State private var searchText               : String        = ""
    @State private var hideSaveButton           : Bool          = false
    @State private var selectedMainActivities   : Set<Int>      = []
    @Binding var selectedSubActivites           : Set<Int>
    var activityModel                           : ActivitiesModel
    var onSendData                              : (Set<Int>) -> Void
    @Binding var moveToActivityScreen           : Bool
    @Binding var showNotificationBar: Bool
    @Binding var showDoneButton: Bool

    var fromPostCreationPlannedorLive: Bool = false
    
    @ViewBuilder
    var body: some View {
        
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                
                ThemeManager.backgroundColor.edgesIgnoringSafeArea(.top)
                
                VStack {
                    if showDoneButton {
                        HStack {
                            Spacer()
                            Button(action: {
                                // onSendData(selectedSubActivites)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Done")
                                    .fontStyle(size: 14, weight: .semibold)
                                    .foregroundStyle(
                                        ThemeManager.gradientNewPinkBackground
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                            }
                            .padding(.trailing, 16)
                        }
                    }

                    if !showNotificationBar {
                        headerView
                    }

                    ActivitySearchBarView(
                        searchText: $searchText,
                        hideSaveButton: $hideSaveButton,
                        selectedSubActivites: $selectedSubActivites)
                    
                    
                    ActivitySelectionView(
                        searchText: $searchText,
                        selectedSubActivities: $selectedSubActivites,
                        selectedMainActivities: $selectedMainActivities,
                        fromPostCreationPlannedorLive: fromPostCreationPlannedorLive,
                        activityModel: activityModel
                    )
                    .padding(.top, 0)
                    
                    .sheet(isPresented: $isFilterViewShown, onDismiss: {
                        debugPrint("Dismissed")
                    }) {
                        ActivityMainFilterView(
                            isPresented: $isFilterViewShown,
                            selectedMainActivites: $selectedMainActivities,
                            activityModel: activityModel)
                        .presentationDetents([.fraction(0.5), .large])
                        .presentationDragIndicator(.visible)
                    }
                    .customNavBarWithRightBarButton(
                        title: Constants.pageTitleMain,
                        tabIcon: DeveloperConstants.systemImage.filterButtonTabBar,
                        tabIconColour: ThemeManager.staticPurpleColour,
                        backAction: {
                            onSendData(selectedSubActivites)
                            presentationMode.wrappedValue.dismiss()
                        },
                        rightBarButtonAction: {
                            isFilterViewShown.toggle()
                        })
                    //                    if !hideSaveButton && !selectedSubActivites.isEmpty {
                    //                        ActivitySelectionSaveButtonView() {
                    //
                    //                            moveToActivityScreen.toggle()
                    //                        }
                    //                    }
                }
                if showNotificationBar {
                    VStack {
                        ThemeManager.backgroundColor
                            .frame(height: HelperFunctions.hasNotch(in: geometry.safeAreaInsets) ? 98 : 64)
                            .shadow(color: ThemeManager.staticPurpleColour.opacity(0.1), radius: 2, x: 0, y: 2)
                            .edgesIgnoringSafeArea(.top)
                        Spacer()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear() {
            searchText = ""
        }
        .onDisappear() {
            // only send when the notification bar is not available
            if !showNotificationBar {
                onSendData(selectedSubActivites)
            }
        }
    }
}

// Header Section
private var headerView: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(Constants.activitiesHeaderInPost)
            .fontStyle(size: 16, weight: .semibold)
            .frame(maxWidth: .infinity, alignment: .leading)
        
        Text(Constants.activitiesHeaderSubText)
            .fontStyle(size: 12, weight: .light)
            .foregroundColor(.gray)
            .fixedSize(horizontal: false, vertical: true)
    }
    .padding([.top, .leading])
}

//MARK: - Interest Search Bar
struct ActivitySearchBarView: View {
    @Binding var searchText: String
    @Binding var hideSaveButton : Bool
    @Binding var selectedSubActivites : Set<Int>
    
    var body: some View {
        VStack(spacing: 5) {
            TextField("\(Constants.searchText) \(Constants.pageTitleMain)", text: $searchText)
                .keyboardType(.default)
                .padding()
                .fontStyle(size: 12, weight: .regular)
                .foregroundColor(ThemeManager.foregroundColor)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                .shadow(color: ThemeManager.staticPurpleColour.opacity(0.2), radius: 3, x: 0, y: 0)
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
                            .padding(.trailing, 8)
                        }
                    })
                .onChange(of: searchText) { oldValue, newValue in
                    hideSaveButton = newValue.count == 0 ? false : true
                }
            
            Button(action : {
                selectedSubActivites.count > 0 ? selectedSubActivites.removeAll() : nil
            }) {
                Text("\(Constants.sortButton) \(selectedSubActivites.count)")
                    .fontStyle(size: 12, weight: .light)
                    .foregroundStyle(ThemeManager.foregroundColor)
                
                Text(Constants.resetButton)
                    .fontStyle(size: 14, weight: .semibold)
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
            }
            .padding(.top, 10)
        }
        .padding()
    }
}

//MARK: - Interest save button
struct ActivitySelectionSaveButtonView: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(Constants.saveReturnButton)
                .applyCustomButtonStyle()
        }
    }
}
