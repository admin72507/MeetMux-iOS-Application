//
//  InterestScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 11-02-2025.
//

import SwiftUI

struct ActivityScene: View {
    
    @Environment(\.colorScheme) var deviceTheme
    
    @State private var moveToActivityScreen     = false
    @State private var selectedSubActivites     : Set<Int>  = []
    @ObservedObject var profileUpdationViewModel: ProfileDetailViewModel
    @State private var activitiesModelList      : ActivitiesModel = ActivitiesModel(categories: [])
    
    var onDataReceived                          : (Set<Int>) -> Void
    
    init(
        returnSelectedSubCategories: Set<Int>? = [],
        onDataReceived: @escaping (Set<Int>) -> Void,
        profileUpdationViewModel: ProfileDetailViewModel
    ) {
        self.selectedSubActivites = returnSelectedSubCategories ?? []
        self.onDataReceived                 = onDataReceived
        self.profileUpdationViewModel       = profileUpdationViewModel
    }
    
    var body: some View {
        Button(action: {
            Loader.shared.startLoading()
            profileUpdationViewModel.getSubActivitiesList { activitiesModel in
                activitiesModelList = activitiesModel
                moveToActivityScreen.toggle()
            } failure: { error in
                profileUpdationViewModel.showErrorToastActivities = true
            }
        }) {
            VStack(alignment: .leading, spacing: 10) {
                RedAsteriskTextView(title: Constants.pageTitleActivities)
                    .foregroundColor(ThemeManager.foregroundColor)
                
                HStack(alignment: .top, spacing: 10) {
                    
                    Text(Constants.pageDescription)
                        .fontStyle(size: 12, weight: .light)
                        .foregroundColor(.gray)
                        .padding(.bottom, 5)
                    
                    Image(systemName: DeveloperConstants.systemImage.chevronRight)
                        .foregroundColor(ThemeManager.staticPurpleColour)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.dynamicBackground(for: deviceTheme))
            .cornerRadius(12)
            .shadow(color: ThemeManager.staticPurpleColour.opacity(0.2), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .navigationDestination(isPresented: $moveToActivityScreen) {
            ActivitiesSelectionScene(
                selectedSubActivites: $selectedSubActivites,
                activityModel: activitiesModelList,
                onSendData: onDataReceived,
                moveToActivityScreen: $moveToActivityScreen,
                showNotificationBar:
                        .constant(true),
                showDoneButton:
                        .constant(false))
        }
    }
}
