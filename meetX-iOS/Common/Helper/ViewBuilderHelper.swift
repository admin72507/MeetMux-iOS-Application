//
//  ViewBuilderHelper.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 08-02-2025.
//

import SwiftUI
import Kingfisher

struct CustomNavigationBar: ViewModifier {
    let title: String
    let backButtonHidden: Bool
    let backAction: () -> Void
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                if backButtonHidden == false {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            backAction()
                        }) {
                            Image(systemName: DeveloperConstants.systemImage.backButtonImage)
                                .foregroundColor(ThemeManager.foregroundColor)
                                .padding(.bottom, 5)
                        }
                    }
                }else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            backAction()
                        }) {
                            Image(systemName: DeveloperConstants.systemImage.closeXmarkNormal)
                                .foregroundColor(ThemeManager.foregroundColor)
                                .padding(.bottom, 5)
                        }
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .fontStyle(size: DeveloperConstants.General.mainHeadingSize, weight: .semibold)
                        .foregroundColor(ThemeManager.foregroundColor)
                        .padding(.bottom, 5)
                }
                
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct MainButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .fontStyle(size: 14, weight: .semibold)
            .frame(height: 15)
            .frame(maxWidth: .infinity)
            .padding()
            .background(ThemeManager.gradientBackground)
            .cornerRadius(25)
            .foregroundColor(.white)
            .padding(.horizontal)
            .shadow(color: ThemeManager.staticPurpleColour.opacity(0.5), radius: 5, x: 2, y: 5)
    }
}

struct MainButtonStyleSecondary: ViewModifier {
    func body(content: Content) -> some View {
        content
            .fontStyle(size: 14, weight: .semibold)
            .frame(height: 15)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.gray)
            .cornerRadius(25)
            .foregroundColor(.white)
            .padding(.horizontal)
            .shadow(color: ThemeManager.staticPurpleColour.opacity(0.5), radius: 5, x: 2, y: 5)
    }
}


struct CustomNavigationBarWithRightTabIcon: ViewModifier {
    let title: String
    let tabIcon: String
    let tabIconColour : Color
    let backAction: () -> Void
    let tabBarAction: () -> Void
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        backAction()
                    }) {
                        Image(systemName: DeveloperConstants.systemImage.backButtonImage)
                            .foregroundColor(ThemeManager.foregroundColor)
                            .padding(.bottom, 5)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .fontStyle(size: DeveloperConstants.General.mainHeadingSize, weight: .semibold)
                        .foregroundColor(ThemeManager.foregroundColor)
                        .padding(.bottom, 5)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        tabBarAction()
                    }) {
                        Image(systemName: tabIcon)
                            .foregroundColor(tabIconColour)
                            .padding(.bottom, 5)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
    }
}

//MARK: - Explore Navigation BAr
struct CustomNavigationBarExploreScene: ViewModifier {

    let title               : String
    let onTitleTapped       : () -> Void
    let onSearchTapped      : () -> Void
    let onFilterTapped      : () -> Void
    let hideFilterButton    : Bool

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { onTitleTapped() }) {
                        HStack(spacing: 8) {
                            Image(systemName: DeveloperConstants.systemImage.imageSafari)
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(ThemeManager.gradientBackground)
                                .frame(width: 30, height: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.headline)
                                    .foregroundColor(ThemeManager.foregroundColor)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .fixedSize(horizontal: true, vertical: false)

                                Text(Constants.tapToLocateText)
                                    .font(.footnote)
                                    .foregroundColor(ThemeManager.foregroundColor.opacity(0.5))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 5) {
                        Button(action: { onSearchTapped() }) {
                            Image(systemName: DeveloperConstants.systemImage.searchIcon)
                                .resizable()
                                .foregroundStyle(ThemeManager.gradientBackground)
                                .frame(width: 20, height: 20)
                        }
                        if !hideFilterButton {
                            Button(action: { onFilterTapped() }) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: DeveloperConstants.systemImage.filterImage)
                                        .resizable()
                                        .foregroundStyle(ThemeManager.gradientBackground)
                                        .frame(width: 20, height: 20)
                                }
                            }
                        }
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Custom Tab bar for Create Post
struct CustomNavigationBarCreatePostScene: ViewModifier {
    
    let title: String
    let onPostTapped: () -> Void
    let postButtonEnabled: Bool
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                // Top Leading
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: DeveloperConstants.systemImage.postCreationTitleImage)
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(ThemeManager.gradientBackground)
                                .frame(width: 30, height: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.headline)
                                    .foregroundColor(ThemeManager.foregroundColor)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .fixedSize(horizontal: true, vertical: false)
                                
                                Text(Constants.createPostDescription)
                                    .font(.footnote)
                                    .foregroundColor(ThemeManager.foregroundColor.opacity(0.5))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Top Trailing - POST Button
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onPostTapped) {
                        HStack(spacing: 6) {
                            Image(systemName: DeveloperConstants.systemImage.closeXmark)
                           // Text(Constants.closeButtontext)
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundColor(ThemeManager.foregroundColor)
                        .background(ThemeManager.backgroundColor.opacity(0.5))
                        .cornerRadius(10)
                    }
                    .disabled(!postButtonEnabled)
                }
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button(action: {
//                        onPostTapped()
//                    }) {
//                        Image(systemName: DeveloperConstants.systemImage.closeXmarkNormal)
//                            .foregroundColor(ThemeManager.foregroundColor)
//                            .padding(.bottom, 5)
//                    }
//                    .disabled(!postButtonEnabled)
//                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
    }
    
  
    
    @ViewBuilder
    private var postButtonBackground: some View {
        if postButtonEnabled {
            Color.gray
        } else {
            Color.gray.opacity(0.6)
        }
    }
}




// MARK: - HomePage Custom Navgation BAr
struct CustomHomeNavigationBarDesign: ViewModifier {
    let title: String
    let subtitle: String
    let profileImage: String
    let hasNotification: Bool
    let onTitleTapped: () -> Void
    let onSearchTapped: () -> Void
    let onNotificationTapped: () -> Void
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { onTitleTapped() }) {
                        HStack(spacing: 8) {
                            Image(systemName: DeveloperConstants.systemImage.locationPinHome)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 30)
                                .foregroundStyle(ThemeManager.gradientBackground)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 5) {
                                    Text(title)
                                        .fontStyle(size: 18, weight: .semibold)
                                        .foregroundColor(ThemeManager.foregroundColor)
                                        .lineLimit(1)
                                        .truncationMode(.tail)

                                    Image(systemName: DeveloperConstants.systemImage.downArrowImage)
                                        .resizable()
                                        .frame(width: 10, height: 5)
                                        .foregroundColor(ThemeManager.foregroundColor)
                                        .fixedSize()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Text(subtitle)
                                    .fontStyle(size: 12, weight: .light)
                                    .foregroundColor(ThemeManager.foregroundColor)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: 200, alignment: .leading)
                            }
                        }
                        .frame(maxWidth: 250, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 5) {
                        Button(action: { onSearchTapped() }) {
                            Image(systemName: DeveloperConstants.systemImage.searchIcon)
                                .resizable()
                                .foregroundStyle(ThemeManager.gradientBackground)
                                .frame(width: 20, height: 20)
                        }
                        Button(action: { onNotificationTapped() }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: hasNotification ? DeveloperConstants.systemImage.bellWithNotification : DeveloperConstants.systemImage.bellWithoutNotification)
                                    .resizable()
                                    .foregroundStyle(ThemeManager.gradientBackground)
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                }            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
    }
}


// MARK: - General Navigation Bar
struct GenericNavigationBar: ViewModifier {
    let title: String?
    let backButtonImage: String?
    let rightButtons: [(image: String, action: () -> Void)]
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let backButtonImage = backButtonImage {
                        Button(action: { rightButtons.first?.action() }) {
                            Image(systemName: backButtonImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }
                    }
                }
                
                if let title = title {
                    ToolbarItem(placement: .principal) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(ThemeManager.foregroundColor)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 10) {
                        ForEach(rightButtons.indices, id: \.self) { index in
                            Button(action: { rightButtons[index].action() }) {
                                Image(systemName: rightButtons[index].image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
    }
}


//MARK: - Generic back nav button
struct CustomBackButtonModifier: ViewModifier {
    let onBack: () -> Void
    
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onBack) {
                        Image(systemName: DeveloperConstants.systemImage.backButtonImage)
                            .foregroundColor(.primary)
                            .imageScale(.large)
                    }
                }
            }
    }
}

// MARK: - Title with fade effect
struct TitleWithFadedDivider: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .fontStyle(size: 12, weight: .medium)
                .foregroundColor(ThemeManager.foregroundColor)
            
            LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.3), Color.clear]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
        }
    }
}


//MARK: - Clip Bounds
struct RoundedCorners: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}


//MARK: - BlurView
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}


//MARK: - profileImage
struct ProfileFeedImageView: View {
    var imageUrl: String
    var userName: String
    
    private var firstLetter: String {
        return String(userName.prefix(2)).uppercased()
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(ThemeManager.staticPinkColour, lineWidth: 2)
                .frame(width: 60, height: 60)
            
            Circle()
                .stroke(ThemeManager.staticPinkColour, lineWidth: 2)
                .frame(width: 62, height: 62)
            
            if let url = URL(string: imageUrl), !imageUrl.isEmpty {
                KFImage(url)
                    .resizable()
                    .cancelOnDisappear(true)
                    .onFailure { _ in }
                    .placeholder {
                        placeholderView
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50, alignment: .top)
                    .clipped()
                    .clipShape(Circle())
            } else {
                placeholderView
                    .frame(width: 50, height: 50)
            }
        }
        .shadow(radius: 5)
    }
    
    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
            Text(firstLetter)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.gray)
        }
        .clipShape(Circle())
    }
}




//MARK: - Control Center
struct DashboardNavigationBarModifier: ViewModifier {
    let title: String
    let onSearchTapped: () -> Void
    
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {  }) {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.stack.fill.badge.person.crop")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(ThemeManager.gradientBackground)
                                .frame(width: 30, height: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.headline)
                                    .foregroundColor(ThemeManager.foregroundColor)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .fixedSize(horizontal: true, vertical: false)
                                
                                Text("Command Your World")
                                    .font(.footnote)
                                    .foregroundColor(ThemeManager.foregroundColor.opacity(0.5))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onSearchTapped) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(ThemeManager.gradientBackground)
                    }
                }
            }
    }
}



//MARK: - CustomNavigation Bar Chat system
struct CustomNavigationBarChatScene: ViewModifier {
    
    let title               : String
    let subTitle            : String
    let onTitleTapped       : () -> Void
    let onSearchTapped      : () -> Void
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { onTitleTapped() }) {
                        HStack(spacing: 8) {
                            Image(systemName: DeveloperConstants.systemImage.chatMainBubble)
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(ThemeManager.gradientBackground)
                                .frame(width: 30, height: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.headline)
                                    .foregroundColor(ThemeManager.foregroundColor)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .fixedSize(horizontal: true, vertical: false)
                                
                                Text(subTitle)
                                    .font(.footnote)
                                    .foregroundColor(ThemeManager.foregroundColor.opacity(0.5))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 5) {
                        Button(action: { onSearchTapped() }) {
                            Image(systemName: DeveloperConstants.systemImage.searchIcon)
                                .resizable()
                                .foregroundStyle(ThemeManager.gradientBackground)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
    }
}


//MARK: - Control Scene General Nav bar
struct ControlGeneralNavBarModifier: ViewModifier {
    let title: String
    let subtitle: String
    let image : String
    let onBackTapped: () -> Void
    
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onBackTapped) {
                        HStack(spacing: 8) {
                            Image(systemName: DeveloperConstants.systemImage.backButtonImage)
                                .foregroundStyle(ThemeManager.foregroundColor)
                            
                            Image(systemName: image)
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(ThemeManager.gradientBackground)
                                .frame(width: 30, height: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.headline)
                                    .foregroundColor(ThemeManager.foregroundColor)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                Text(subtitle)
                                    .font(.footnote)
                                    .foregroundColor(ThemeManager.foregroundColor.opacity(0.5))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
    }
}

// MARK: - Privacy settings with save button
struct ControlSaveNavBarModifier: ViewModifier {
    let title: String
    let subtitle: String
    let image : String
    let onBackTapped: () -> Void
    let onSaveTapped: () -> Void
    @Binding var isSaveEnabled: Bool
    
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onBackTapped) {
                        HStack(spacing: 8) {
                            Image(systemName: DeveloperConstants.systemImage.backButtonImage)
                                .foregroundStyle(ThemeManager.foregroundColor)
                            
                            Image(systemName: image)
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(ThemeManager.gradientBackground)
                                .frame(width: 30, height: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.headline)
                                    .foregroundColor(ThemeManager.foregroundColor)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                Text(subtitle)
                                    .font(.footnote)
                                    .foregroundColor(ThemeManager.foregroundColor.opacity(0.5))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if isSaveEnabled {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: onSaveTapped) {
                            HStack(spacing: 6) {
                                Image(systemName: DeveloperConstants.systemImage.saveTray)
                                Text(Constants.saveText)
                            }
                            .font(.headline)
                            .foregroundStyle(isSaveEnabled ? ThemeManager.staticPinkColour : .gray)
                        }
                        .disabled(!isSaveEnabled)
                    }
                }
            }
    }
}

// MARK: - Glow Effect Modifier
struct GlowEffect: ViewModifier {
    let isActive: Bool
    let color: Color
    let radius: CGFloat
    let intensity: Double
    
    init(isActive: Bool = true, color: Color = .red, radius: CGFloat = 10, intensity: Double = 0.4) {
        self.isActive = isActive
        self.color = color
        self.radius = radius
        self.intensity = intensity
    }
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: isActive ? color.opacity(intensity) : Color.clear,
                radius: isActive ? radius * 0.6 : 0
            )
            .shadow(
                color: isActive ? color.opacity(intensity * 0.75) : Color.clear,
                radius: isActive ? radius : 0
            )
            .shadow(
                color: isActive ? color.opacity(intensity * 0.5) : Color.clear,
                radius: isActive ? radius * 1.5 : 0
            )
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isActive)
    }
}
