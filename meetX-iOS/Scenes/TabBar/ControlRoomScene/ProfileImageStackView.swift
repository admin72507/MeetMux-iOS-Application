//
//  ProfileImageStackView.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 16-02-2025.
//
import SwiftUI
import Kingfisher

struct ProfileStackView: View {
    @State private var selectedIndex = 0
    @ObservedObject var viewModel: ProfileMeAndOthersObservable
    
    private var imageUrls: [String] {
        viewModel.userProfileDetailsModel?.profilePicUrls ?? []
    }
    
    private var userName: String {
        viewModel.userProfileDetailsModel?.name ?? ""
    }
    
    private var userUsername: String {
        viewModel.userProfileDetailsModel?.username ?? ""
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(geometry.size.width - 20, 0)

            VStack {
                ZStack {
                    ForEach(imageUrls.indices, id: \.self) { index in
                        ProfileImageView(
                            imageName: imageUrls[index],
                            name: userName,
                            subtitle: userUsername,
                            index: index,
                            totalCount: imageUrls.count,
                            width: availableWidth,
                            selectedIndex: $selectedIndex,
                            viewModel: viewModel
                        )
                    }
                }
                .frame(width: availableWidth, height: availableWidth * 0.85)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        selectedIndex = (selectedIndex + 1) % max(imageUrls.count, 1)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(width: geometry.size.width, height: availableWidth * 0.85)
        }
        .frame(height: UIScreen.main.bounds.width * 0.85)
    }
}

struct ProfileImageView: View {
    let imageName: String
    let name: String
    let subtitle: String
    let index: Int
    let totalCount: Int
    let width: CGFloat
    
    @Binding var selectedIndex: Int
    @ObservedObject var viewModel: ProfileMeAndOthersObservable
    
    @State private var showSheetShared = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var imageLoadingProgress: Double = 0.0
    @State private var imageLoadFailed = false
    @State private var uiImage: UIImage? = nil
    @State private var showQRSheet = false
    
    var body: some View {
        ZStack {
            if imageName != "" {
                KFImageView(imageURL: URL(string: imageName), width: width)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width, height: width * 0.85) // <-- match all overlays
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 5)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: width, height: width * 0.85)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 5)
            }
            
            VStack {
                Spacer()
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: width * 0.35)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        showSheetShared = true
                    }) {
                        Image(systemName: DeveloperConstants.systemImage.squareAndUpArow)
                            .font(.system(size: 25))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                            .scaleEffect(buttonScale)
                    }
                }
                .padding(.top, 10)
                .padding(.trailing, 10)
                
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .fontStyle(size: 40, weight: .bold)
                            .foregroundColor(.white)
                        
                        Text(subtitle)
                            .fontStyle(size: 20, weight: .semibold)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            showQRSheet = true
                        }) {
                            Image(systemName: DeveloperConstants.systemImage.qrcodeImage)
                                .font(.system(size: 25))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                                .scaleEffect(buttonScale)
                        }
                        
                        if viewModel.typeOfProfile == .personal {
                            Button(action: {
                                RouteManager.shared.navigate(to: navigateToEditProfile(
                                    fullName: viewModel.userProfileDetailsModel?.name ?? "",
                                    email: viewModel.userProfileDetailsModel?.email ?? "", 
                                    bio: viewModel.userProfileDetailsModel?.about ?? "",
                                    selectedActivities: Set(viewModel.userProfileDetailsModel?.userActivities ?? []), s3ImageUrls: viewModel.userProfileDetailsModel?.notSignedUrls ?? [],
                                    signedProfileImageUrl: viewModel.userProfileDetailsModel?.profilePicUrls ?? []
                                )
                                )
                            }) {
                                Image(systemName: DeveloperConstants.systemImage.squareAndPencil)
                                    .font(.system(size: 25))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                                    .scaleEffect(buttonScale)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .scaleEffect(selectedIndex == index ? 1.0 : 0.9)
        .opacity(selectedIndex == index ? 1.0 : 0.7)
        .rotationEffect(.degrees(Double((index - selectedIndex) * -5)))
        .offset(y: CGFloat((index - selectedIndex) * 15))
        .blur(radius: selectedIndex == index ? 0 : 5)
        .zIndex(selectedIndex == index ? 1 : -Double(index))
        .sheet(isPresented: $showSheetShared) {
            ShareSheet(items: [
                Constants.shareYourProfile,
                viewModel.userProfileDetailsModel?.deepLink ?? ""
            ])
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showQRSheet) {
            if let qrCode = viewModel.userProfileDetailsModel?.qrCode,
               let base64String = qrCode.components(separatedBy: ",").last,
               let imageData = Data(base64Encoded: base64String),
               let uiImage = UIImage(data: imageData),
               let qrImage = Image(uiImage: uiImage) as Image? {
                
                QRBottomSheetView(
                    qrImage: qrImage,
                    shareImage: uiImage,
                    deeplinkURL: viewModel.userProfileDetailsModel?.deepLink ?? "",
                    username: viewModel.userProfileDetailsModel?.username ?? ""
                ) {
                    showQRSheet = false
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                
            } else {
                Text("Failed to load QR code")
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

struct KFImageView: View {
    let imageURL: URL?
    let width: CGFloat
    
    var body: some View {
        Group {
            if let imageURL = imageURL {
                KFImage(imageURL)
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .onFailureImage(UIImage(named: "placeholder_error"))
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: width * 0.85)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 5)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: width, height: width * 0.85)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 5)
            }
        }
    }
}
