//
//  AboutMeScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 14-05-2025.
//

import SwiftUI

struct ProfileMeAndOtherScene: View {

    @StateObject var viewModel: ProfileMeAndOthersObservable
    @StateObject private var viewModelHome: HomeObservable
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0
    @State private var showScrollToTopButton: Bool = false
    @State var connectButtonTitle: String = "Connect"
    @State var followFollowingButtonTitle: String = "Follow"

    private let columns = [
        GridItem(
            .adaptive(minimum: 100),
            spacing: 8
        )
    ]

    init(
        viewModel: ProfileMeAndOthersObservable,
        viewModelHome: HomeObservable
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _viewModelHome = StateObject(wrappedValue: viewModelHome)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ThemeManager.backgroundColor.ignoresSafeArea()

                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(alignment: .center, spacing: 10) {
                            if let userProfileDetailsModel = viewModel.userProfileDetailsModel {
                                VStack {
                                    ProfileStackView(viewModel: viewModel)
                                        .background(Color.clear)
                                }
                                .padding(.horizontal)

                                profileStatsView(userProfileDetailsModel, scrollProxy: scrollProxy)

                                if let socialScore = userProfileDetailsModel.socialScore {
                                    SocialScoreView(socialScore: socialScore)
                                        .padding(.top, 16)
                                }

                                if viewModel.typeOfProfile == .others {
                                    handleInterestButton()
                                        .padding(.top, 10)
                                }
                            }

                            profileDetailsSection()

                            postGridLayout()
                        }
                        .padding(.top)
                        .background(
                            GeometryReader { proxy in
                                let minY = proxy.frame(in: .global).minY
                                Color.clear
                                    .onAppear {
                                        scrollOffset = minY
                                    }
                                    .onChange(of: minY) { _, newOffset in
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            scrollOffset = newOffset
                                            showScrollToTopButton = newOffset < -10
                                            VideoPlaybackManager.shared.pauseCurrent()
                                        }
                                    }
                            }
                        )
                    }
                    .onAppear {
                        viewModel.isLoading = false
                        viewModel.getTheProfileDetails()
                    }
                    .generalNavBarInControlRoom(
                        title: viewModel.typeOfProfile == .personal
                        ? "About Me"
                        : "\(viewModel.userProfileDetailsModel?.name ?? "")'s Profile",
                        subtitle: viewModel.userProfileDetailsModel?.username ?? "",
                        image: "person.text.rectangle",
                        onBacktapped: {
                            dismiss()
                        }
                    )
                    .overlay(
                        Group {
                            if showScrollToTopButton {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            withAnimation {
                                                scrollProxy.scrollTo("segmentControl", anchor: .top)
                                            }
                                        }) {
                                            Image(systemName: DeveloperConstants.systemImage.upArrowImage)
                                                .font(.system(size: 24))
                                                .foregroundColor(ThemeManager.foregroundColor)
                                                .padding()
                                                .background(ThemeManager.gradientNewPinkBackground)
                                                .clipShape(Circle())
                                                .shadow(radius: 4)
                                        }
                                        .padding()
                                    }
                                }
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Extension
extension ProfileMeAndOtherScene {

    func getValue(for index: Int, _ userdetailsModel: UserProfileData) -> String {
        switch index {
            case 0: return "\(userdetailsModel.postCount ?? 0)"
            case 1: return "\(userdetailsModel.following ?? 0)"
            case 2: return "\(userdetailsModel.followers ?? 0)"
            case 3: return "\(userdetailsModel.connections ?? 0)"
            default: return "-"
        }
    }

    // MARK: - Count view
    @ViewBuilder
    func profileStatsView(_ model: UserProfileData, scrollProxy: ScrollViewProxy) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<DeveloperConstants.elementsInProfile.count, id: \.self) { index in
                Spacer(minLength: 0)

                Button(action: {
                    handleStatsButtonTapped(for: index, scrollProxy: scrollProxy)
                }) {
                    VStack(spacing: 4) {
                        Text(getValue(for: index, model))
                            .fontStyle(size: 22, weight: .heavy)
                            .foregroundStyle(ThemeManager.gradientNewPinkBackground)

                        Text(DeveloperConstants.elementsInProfile[index])
                            .fontStyle(size: 14, weight: .semibold)
                            .foregroundStyle(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Stats Button Handler
    private func handleStatsButtonTapped(for index: Int, scrollProxy: ScrollViewProxy) {
        HapticManager.trigger(.light)
        switch index {
            case 0:
                withAnimation(.easeInOut(duration: 0.8)) {
                    scrollProxy.scrollTo("postGridLayout", anchor: .top)
                }
            case 1,2:
                if viewModel.typeOfProfile == .personal {
                    viewModel.handleFollowingFollowButtonTapped()
                }
            case 3:
                if viewModel.typeOfProfile == .personal {
                    viewModel.handleConnectionsButtonTapped()
                }
            default:
                break
        }
    }

    // MARK: - Info section
    @ViewBuilder
    func profileDetailsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            TitleWithFadedDivider(title: DeveloperConstants.bioSegmentTitles.randomElement() ?? "")
                .padding(.leading, 16)

            handleBioSectionDescription()

            TitleWithFadedDivider(title: DeveloperConstants.hobbiesAndInterestsTitles.randomElement() ?? "")
                .padding(.leading, 16)

            handleActivitiesList()
        }
        .padding(.top, 20)
        .id("segmentControl")
    }

    //MARK: - Post Section
    @ViewBuilder
    func postGridLayout() -> some View {
        VStack(spacing: 8) {
            TitleWithFadedDivider(title: viewModel.handleTitle("General, Planned and Live Posts 😊"))
                .padding(.leading, 16)

            InstagramProfileGridView(
                postDetails: $viewModel.postDetails,
                viewModel: viewModel
            )
        }
        .id("postGridLayout")
    }
}

// MARK: - Extension Profile Page
extension ProfileMeAndOtherScene {

    func handleBioSectionTitle() -> some View {
        Text(viewModel.typeOfProfile == .others ? "" : Constants.bioProfileText)
            .fontStyle(size: 16, weight: .semibold)
            .padding(.horizontal)
    }

    func handleBioSectionDescription() -> some View {
        Text(viewModel.userProfileDetailsModel?.about ?? "")
            .fontStyle(size: 14, weight: .light)
            .padding(.horizontal)
    }
}

// MARK: - Extension Other Profile Handling
extension ProfileMeAndOtherScene {

    // MARK: - Activities List
    func handleActivitiesList() -> some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(viewModel.userProfileDetailsModel?.interests ?? []) { item in
                InterestButton(
                    title: "\(item.title) - \(item.count ?? 0)",
                    icon: item.iconIOS ?? "",
                    isSelected: false,
                    action: { debugPrint("NoActionNeeded") }
                )
            }
        }.padding(.horizontal)
    }

    @ViewBuilder
    func handleInterestButton() -> some View {
        HStack(spacing: 16) {

            // Follow button Logics
            // check if the request is sent already
            if viewModel.userProfileDetailsModel?.isFollowRequested == true {
                // Follow request is sent already then TITLE --> Follow Requested
                commonComponentForInterestsButton(
                    title: "Follow Requested",
                    icon: "person.fill.checkmark",
                    isSelected: false,
                    onAction: {
                        viewModel.actionFollowButtonTypes.send(.cancelFollowRequest)
                    })

            }else if viewModel.userProfileDetailsModel?.isFollowing == false {
                // button title FOllow
                commonComponentForInterestsButton(
                    title: followFollowingButtonTitle, // Follow
                    icon: "person.2.badge.plus.fill",
                    isSelected: false,
                    onAction: {
                        viewModel.actionFollowButtonTypes.send(.sendFollowRequest)
                    })
            } else {
                // Both above conditions are opposite then user is already following
                commonComponentForInterestsButton(
                    title: "UnFollow",
                    icon: "checkmark",
                    isSelected: false,
                    onAction: {
                        viewModel.actionFollowButtonTypes.send(.removeFollow)
                    })
            }

            // MARK: - Connect Button
            if viewModel.userProfileDetailsModel?.isConnectionRequested == true {
                // Connection request is sent already then TITLE --> Connection Requested
                commonComponentForInterestsButton(
                    title: "Connection Requested",
                    icon: "person.fill.checkmark",
                    isSelected: true,
                    onAction: {
                        viewModel.connectionActionButtonTypes.send(.removeConnectionRequest)
                    }
                )
                .frame(maxWidth: .infinity)
            } else if viewModel.userProfileDetailsModel?.isConnected == false {
                // Not connected - show Connect button
                commonComponentForInterestsButton(
                    title: "Connect",
                    icon: "person.fill.badge.plus",
                    isSelected: true,
                    onAction: {
                        viewModel.connectionActionButtonTypes.send(.sendConnectionRequest)
                    }
                )
                .frame(maxWidth: .infinity)
            } else {
                // User is already connected - show Remove Connection
                VStack(spacing: 10) {
                    commonComponentForInterestsButton(
                        title: "Remove Connection",
                        icon: "person.crop.circle.badge.checkmark",
                        isSelected: true,
                        onAction: {
                            viewModel.connectionActionButtonTypes.send(.removeConnection)
                        }
                    )
                    .frame(maxWidth: .infinity)

                    if viewModel.typeOfProfile == .others {
                        commonComponentForInterestsButton(
                            title: "Chat",
                            icon: "message.fill",
                            isSelected: true,
                            onAction: {
                                viewModel.chatActionButtonTypes
                                    .send(.removeConnection)
                            }
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .font(.title2)
        .padding(.horizontal, 16)
    }

    func commonComponentForInterestsButton(
        title: String,
        icon: String,
        isSelected: Bool,
        onAction: @escaping () -> Void
    ) -> some View {
        InterestButton(
            title: title,
            icon: icon,
            isSelected: isSelected,
            action: onAction
        )
        .frame(maxWidth: .infinity)
    }
}
