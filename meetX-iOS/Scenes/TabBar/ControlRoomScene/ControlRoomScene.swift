//
//  MenuScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 25-12-2024.
//

import SwiftUI
import AlertToast

import SwiftUI

struct ControlRoomScene: View {
    @StateObject private var viewModel: ControlRoomObservable = .init()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let menus = viewModel.controlCenterObject?.menus {
                    ForEach(menus.indices, id: \.self) { index in
                        let menuSection = menus[index]
                        ControlRoomSectionView(
                            singleMenuItem: menuSection,
                            onItemSelected: { menuItem in
                                viewModel.handleMenuSelection(menuItem)
                            }
                        )
                        .padding(.bottom, 10)
                    }
                }
                Text(Constants.greetText)
                    .fontStyle(size: 14, weight: .light)
                    .foregroundStyle(.gray.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Spacer()
                    .frame(height: 80)
            }
            .padding(.top)
            .scrollIndicators(.hidden)
        }
        .dashboardNavigationBar(title: Constants.DashboardText) {
            viewModel.routeManager.navigate(to: CreateRecommendedRoute())
        }
        .onAppear() {
            Loader.shared.startLoading()
            viewModel.loadControlCenterIfNeeded {
                viewModel.privacySettingsValueHandler()
                Loader.shared.stopLoading()
            }
        }
        .sheet(isPresented: $viewModel.showLogOutBottomSheet) {
            LogoutConfirmationSheet(isPresented: $viewModel.showLogOutBottomSheet) {
                viewModel.logOutHandler()
            }
        }
        .sheet(isPresented: $viewModel.contactSupportBottomSheet) {
            ContactSupportSheet(showSupportOptions: $viewModel.contactSupportBottomSheet)
        }
        .sheet(isPresented: $viewModel.shareAppSheetShown) {
            ShareSheet(items:
                        [Constants.checkOutThisAppText,
                         URL(string: DeveloperConstants.appShareDeeplink) ?? ""
                        ]
            )
                .presentationDetents([.medium])
        }
        .toast(isPresenting: $viewModel.isInviteLinkCopied) {
            HelperFunctions().generalToastControlSystem("", Constants.linkCopiedTOClipboardText)
        }
        .sheet(isPresented: $viewModel.isNeedHelpTapped) {
            NeedSupportScene(retrivedMobileNumber: (viewModel.cleanMobileNumberWithCountryCode(viewModel.userDataManager.getSecureUserData().mobileNumber ?? "")))
                .presentationDragIndicator(.visible)
        }
        .toast(isPresenting: $viewModel.shareLinkCopied) {
            HelperFunctions().generalToastControlSystem("", Constants.linkCopiedTOClipboardText)
        }
        .sheet(isPresented: $viewModel.rateOurAppInAppStore) {
            RateUsSheet(isPresented: $viewModel.rateOurAppInAppStore)
        }
        .sheet(isPresented: $viewModel.moveUserToContactList) {
            ReferFriendView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Section View
// MARK: - Alternative with better error handling
struct ControlRoomSectionView: View {
    let singleMenuItem: MenuSection
    let onItemSelected: (MenuItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section title
            Text(singleMenuItem.sectionTitle)
                .fontStyle(size: 16, weight: .semibold)
                .foregroundStyle(ThemeManager.foregroundColor)
                .padding(.horizontal)
            
            // Items container
            Group {
                if singleMenuItem.items.isEmpty {
                    // Empty state
                    Text("No items available")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    VStack(spacing: 0) {
                        ForEach(singleMenuItem.items, id: \.id) { item in
                            ControlRoomItemRow(item: item) {
                                onItemSelected(item)
                            }
                            
                            // Divider between items
                            if item.id != singleMenuItem.items.last?.id {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 4)
            )
        }
        .padding(.horizontal)
    }
}


// MARK: - Item Row View
struct ControlRoomItemRow: View {
    let item: MenuItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: item.iosIcon == DeveloperConstants.systemImage.hourGlassFillMenu
                      ? DeveloperConstants.systemImage.hourGlassFill
                      : item.iosIcon)
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                    .frame(width: 24)
                
                Text(item.itemName)
                    .fontStyle(size: 14, weight: .light)
                    .foregroundColor(ThemeManager.foregroundColor)
                
                Spacer()
                
                Image(systemName: DeveloperConstants.systemImage.arrowForward)
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
