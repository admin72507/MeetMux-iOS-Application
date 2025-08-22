//
//  LoaderManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 23-04-2025.
//

import SwiftUI
import Combine
import DotLottie

final class Loader: ObservableObject {
    static let shared = Loader()
    
    @Published var isLoading: Bool = false
    @Published var animationID: UUID = UUID()
    
    private init() {}
    
    func startLoading() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.animationID = UUID()
        }
    }
    
    func stopLoading() {
        DispatchQueue.main.async {
            self.isLoading = false
            self.animationID = UUID()
        }
    }
}

struct GlobalLoaderOverlay: View {
    @ObservedObject var loader = Loader.shared
    
    var body: some View {
        Group {
            if loader.isLoading {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.6), Color.black.opacity(0.2)]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .edgesIgnoringSafeArea(.all)
                    
                    LottieLoaderView(webURL: DeveloperConstants.loaderArray.randomElement() ?? "")
                        .id(loader.animationID)
                        .transition(.opacity)
                }
                .animation(.easeInOut(duration: 0.25), value: loader.isLoading)
            }
        }
    }
}

struct LottieLoaderView: View {
    var webURL: String
    
    var body: some View {
        VStack {
            Spacer()
            DotLottieAnimation(
                webURL: webURL,
                config: .init(autoplay: true, loop: true)
            )
            .view()
            .frame(width: 200, height: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct LottieLoaderLocalFileView: View {
    var animationName: String

    var body: some View {
        VStack {
            Spacer()
            if let _ = Bundle.main.url(forResource: animationName, withExtension: "lottie") {
                DotLottieAnimation(
                    fileName: animationName,
                    config: .init(autoplay: true, loop: true)
                )
                .view()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LottieLoginRegisterLocalFileView: View {
    var animationName: String
    var hasNotch: Bool = false

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let _ = Bundle.main.url(forResource: animationName, withExtension: "lottie") {
                    DotLottieAnimation(
                        fileName: animationName,
                        config: .init(autoplay: true, loop: true)
                    )
                    .view()
                    .frame(
                        width: min(geometry.size.width, geometry.size.height),
                        height: min(geometry.size.width, geometry.size.height)
                    )
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
