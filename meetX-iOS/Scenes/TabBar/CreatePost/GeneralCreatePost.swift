//
//  GeneralCreatePost.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 19-05-2025.
//

import SwiftUI
import AVFoundation
import PhotosUI

// MARK: - Layer 1
struct GeneralCreatePostView: View {
    @ObservedObject var viewModel: CreatePostObservable

    // Selected Location
    @Binding var selectedLocation: String
    @Binding var selectedTagConnections: Set<ConnectedUser>

    // Selected Tags
    let onDeleteTappedOnTag: (ConnectedUser) -> Void

    // Selected Activity List
    @Binding var selectedActivityList: ActivitiesModel

    private let characterLimit = DeveloperConstants.General.postCharacterLimit
    let onItemSelected: (PostSectionList) -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading) {

                        HStack(alignment: .top) {
                            ProfileFeedImageView(
                                imageUrl: viewModel.userDataManager.getSecureUserData().profilePicture ?? "",
                                userName: viewModel.userDataManager.getSecureUserData().userName ?? Constants.unknownUser
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(
                                    viewModel.userDataManager.getSecureUserData().userName ?? Constants.unknownUser
                                )
                                .fontStyle(size: 18, weight: .semibold)
                                .foregroundColor(ThemeManager.foregroundColor)

                                Toggle(isOn: $viewModel.isPublicPost) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(Constants.toggleControlTitleText)
                                            .fontStyle(size: 10, weight: .light)
                                            .foregroundColor(.gray)
                                            .fixedSize(horizontal: false, vertical: true)

                                        Text(
                                            viewModel.isPublicPost
                                            ? Constants.publicPost
                                            : Constants.privatepost
                                        )
                                        .fontStyle(size: 12, weight: .semibold)
                                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: ThemeManager.staticPinkColour))
                            }

                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        VStack(alignment: .leading, spacing: 6) {
                            // Title section
                            VStack(alignment: .leading, spacing: 4) {
                                viewModel.helperFunctions.styledAsteriskText("Write whats on your mind...*")
                                    .fontStyle(size: 12, weight: .semibold)
                                    .foregroundStyle(ThemeManager.foregroundColor)

                                viewModel.helperFunctions.styledAsteriskText("Please write a minimum of \(DeveloperConstants.General.numberOfCharactersNeeded) characters to make a post.")
                                    .fontStyle(size: 10, weight: .light)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            .padding(.top)

                            // FIXED: TextEditor section with proper validation handling
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $viewModel.postDescriptionText)
                                    .padding(4)
                                    .fontStyle(size: 14, weight: .regular)
                                    .foregroundColor(ThemeManager.foregroundColor)
                                    .onChange(of: viewModel.postDescriptionText) { _, newValue in
                                        let trimmed = viewModel.cleanedDescription
                                        if trimmed.count > characterLimit {
                                            viewModel.postDescriptionText = String(trimmed.prefix(characterLimit))
                                        }
                                        // REMOVED: Manual validation trigger - let Combine handle it
                                        // The Combine publishers will automatically handle validation
                                    }
                                    .onReceive(viewModel.$postDescriptionText.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)) { _ in
                                        // Additional debounced validation trigger for complex scenarios
                                        viewModel.triggerValidation()
                                    }
                                    .toolbar {
                                        ToolbarItemGroup(placement: .keyboard) {
                                            HStack {
                                                // Character count
                                                Text("\(viewModel.postDescriptionText.count)/\(characterLimit)")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)

                                                Spacer()

                                                Button("Done") {
                                                    hideKeyboard()
                                                    // Trigger validation when keyboard dismisses
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                        viewModel.triggerValidation()
                                                    }
                                                }
                                                .fontStyle(size: 14, weight: .regular)
                                                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                                            }
                                        }
                                    }

                                if viewModel.postDescriptionText.isEmpty {
                                    Text(Constants.writeAPostText)
                                        .fontStyle(size: 12, weight: .light)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 12)
                                }
                            }
                            .frame(minHeight: 200)
                            .padding(.horizontal)
                        }

                        // Character count
                        HStack {
                            Spacer()
                            Text("\(viewModel.cleanedDescription.count)/\(characterLimit)")
                                .fontStyle(size: 12, weight: .light)
                                .foregroundColor(.gray)
                                .padding(.trailing)
                        }
                    }

                    GeneralPostSupporterListScene(
                        singleMenuItem: (viewModel.selectedSegment == .GeneralPost
                                         ? viewModel.postSections.first ?? PostSection()
                                         : viewModel.selectedSegment == .plannedActivity
                                         ? viewModel.postSections[1]
                                         : viewModel.postSections.last) ?? PostSection(),
                        onItemSelected: { item in
                            onItemSelected(item)
                        },
                        selectedLocation: $selectedLocation,
                        selectedTagConnections: $selectedTagConnections,
                        onDeleteTappedOnTag: { user in
                            onDeleteTappedOnTag(user)
                            // Trigger validation after tag deletion
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                viewModel.triggerValidation()
                            }
                        },
                        selectedActivityList: $selectedActivityList,
                        selectedMedia: $viewModel.selectedMediaItems,
                        photoPickerItem: $viewModel.pickerImagesAndVideo,
                        selectedDateAndTime: $viewModel.selectedDateAndTime,
                        selectedGender: $viewModel.selectedGender,
                        selectedLiveDuration: $viewModel.selectedLiveDuration,
                        latAndLongAvailable: viewModel.userCurrentLocationChecker()
                    )
                    .padding(.top, 16)
                    .onTapGesture {
                        hideKeyboard()
                    }
                }
                .padding(.bottom, 45)
                .onTapGesture {
                    hideKeyboard()
                    // Trigger validation when tapping outside to dismiss keyboard
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.triggerValidation()
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .background(ThemeManager.backgroundColor)
        .onAppear {
            // Trigger validation on appear to ensure correct initial state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                viewModel.triggerValidation()
            }
        }
        .onChange(of: viewModel.selectedSegment) { _, _ in
            // Trigger validation when segment changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.triggerValidation()
            }
        }
        .onChange(of: viewModel.selectedMediaItems) { _, _ in
            // Trigger validation when media changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.triggerValidation()
            }
        }
        .onChange(of: viewModel.userLatitude) { _, _ in
            // Trigger validation when user location changes (for live posts)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.triggerValidation()
            }
        }
        .onChange(of: viewModel.userLongitude) { _, _ in
            // Trigger validation when user location changes (for live posts)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.triggerValidation()
            }
        }
    }
}

// MARK: - Layer 2
// MARK: - General Post bottom options
struct GeneralPostSupporterListScene: View {
    let singleMenuItem: PostSection
    let onItemSelected: (PostSectionList) -> Void

    @Binding var selectedLocation: String
    @Binding var selectedTagConnections: Set<ConnectedUser>
    let onDeleteTappedOnTag: (ConnectedUser) -> Void

    //Activities binding
    @Binding var selectedActivityList: ActivitiesModel

    // Selected Media Bindings
    @Binding var selectedMedia: [SelectedMedia]
    @Binding var photoPickerItem: [PhotosPickerItem]

    // Selected Date and Time
    @Binding var selectedDateAndTime : String

    // Selected Gender
    @Binding var selectedGender: String

    // Live Duration
    @Binding var selectedLiveDuration: String

    // Current location Available
    var latAndLongAvailable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title OUTSIDE of the card
            Text(singleMenuItem.sectionTitle ?? "")
                .fontStyle(size: 16, weight: .semibold)
                .foregroundStyle(ThemeManager.foregroundColor)
                .padding(.horizontal)

            Text(singleMenuItem.sectionSubtitle ?? "")
                .fontStyle(size: 12, weight: .light)
                .foregroundStyle(ThemeManager.foregroundColor)
                .padding(.horizontal)

            VStack(spacing: 0) {
                if let menusItem = singleMenuItem.subCategories {
                    ForEach(menusItem, id: \.id) { item in
                        GeneralPostSupporterListItemScene(
                            item: item,
                            action: {
                                onItemSelected(item)
                            },
                            selectedLocation: $selectedLocation,
                            selectedTagConnections: $selectedTagConnections,
                            onDeleteTappedOnTag: { user in
                                onDeleteTappedOnTag(user)
                            },
                            selectedActivityList: $selectedActivityList,
                            selectedMedia: $selectedMedia,
                            photoPickerItem: $photoPickerItem,
                            selectedDateAndTime: $selectedDateAndTime,
                            selectedGender: $selectedGender,
                            selectedLiveDuration: $selectedLiveDuration,
                            latAndLongAvailable: latAndLongAvailable
                        )
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

// MARK: - Layer 3 (Final Layer)
struct GeneralPostSupporterListItemScene: View {
    let item: PostSectionList
    let action: () -> Void

    @Binding var selectedLocation: String
    @Binding var selectedTagConnections: Set<ConnectedUser>
    @Environment(\.colorScheme) private var colorScheme
    let onDeleteTappedOnTag: (ConnectedUser) -> Void

    //Activities binding
    @Binding var selectedActivityList: ActivitiesModel

    // Selected Media Bindings
    @Binding var selectedMedia: [SelectedMedia]
    @Binding var photoPickerItem: [PhotosPickerItem]

    // Selected Date and Time
    @Binding var selectedDateAndTime : String

    // Selected Gender
    @Binding var selectedGender: String

    // Live Duration
    @Binding var selectedLiveDuration: String

    // Current location Available
    var latAndLongAvailable: Bool

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: item.icon ?? "")
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                    .frame(width: 24)

                VStack(alignment: .leading) {
                    HelperFunctions().styledAsteriskText(item.title ?? "")
                        .fontStyle(size: 12, weight: .semibold)
                        .foregroundStyle(ThemeManager.foregroundColor)
                        .padding(.bottom, 2)

                    Text(item.subtitle ?? "")
                        .fontStyle(size: 10, weight: .light)
                        .padding(.bottom, 5)

                    showDataBasedOnSelection()
                }
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

    @ViewBuilder
    private func showDataBasedOnSelection() -> some View {
        switch item.icon {

            case DeveloperConstants.systemImage.figureWalkMotion:
                TagActivityChipsView(selectedActivityList: $selectedActivityList) { removedSubActivity in
                    print("Removed subactivity: \(removedSubActivity.title)")
                }

            case DeveloperConstants.systemImage.locationNorth:
                if !$selectedLocation.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HStack(spacing: 8) {
                        Button(action: {
                            withAnimation {
                                $selectedLocation.wrappedValue = ""
                            }
                        }) {
                            Image(systemName: DeveloperConstants.systemImage.closeXmark)
                                .font(.caption)
                                .foregroundStyle(
                                    colorScheme == .light
                                    ? AnyShapeStyle(ThemeManager.gradientBackground)
                                    : AnyShapeStyle(ThemeManager.foregroundColor)
                                )

                            Text($selectedLocation.wrappedValue)
                                .fontStyle(size: 12, weight: .semibold)
                                .lineLimit(2)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    EmptyView()
                }

            case DeveloperConstants.systemImage.tagPeopleImage:
                TagChipsView(
                    selectedTagConnections: $selectedTagConnections,
                    onDeleteTappedOnTag: { user in
                        onDeleteTappedOnTag(user)
                    })

            case DeveloperConstants.systemImage.photoOnRectangleAngled:
                if selectedMedia.count != 0 {
                    MediaThumbnailScrollView(selectedMedia: $selectedMedia,
                                             photoPickerItem: $photoPickerItem)
                }

            case DeveloperConstants.systemImage.selectDataAnTime:
                if !selectedDateAndTime.isEmpty {
                    Text(selectedDateAndTime)
                        .fontStyle(size: 12, weight: .semibold)
                        .foregroundStyle(ThemeManager.foregroundColor)
                }

            case DeveloperConstants.systemImage.genderIcon:
                if selectedGender != "" {
                    Text(selectedGender)
                        .fontStyle(size: 12, weight: .semibold)
                        .foregroundStyle(ThemeManager.foregroundColor)
                }

            case DeveloperConstants.systemImage.liveDuration:
                if selectedLiveDuration != "" {
                    Text(selectedLiveDuration)
                        .fontStyle(size: 12, weight: .semibold)
                        .foregroundStyle(ThemeManager.foregroundColor)
                }

            case DeveloperConstants.systemImage.simpleLocationIcon:
                if latAndLongAvailable {
                    Text("Your current location will be used")
                        .fontStyle(size: 12, weight: .semibold)
                        .foregroundStyle(ThemeManager.foregroundColor)
                }else {
                    Text("Please enable location access in settings")
                        .fontStyle(size: 12, weight: .semibold)
                        .foregroundStyle(ThemeManager.foregroundColor)
                }

            case .none:
                EmptyView()
            case .some(_):
                EmptyView()
        }
    }
}
