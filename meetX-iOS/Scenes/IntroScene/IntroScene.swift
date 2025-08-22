//
//  PlaceHolderView.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 06-03-2025.
//
import SwiftUI

struct IntroScreenScene: View {
    @StateObject private var viewModel = IntroScreenObservable(totalPages: Constants.introData.count)
    @Environment(\.colorScheme) var colorScheme
    
    let introItems = Constants.introData
    
    var body: some View {
        VStack {
            Spacer()
            
            TabView(selection: $viewModel.currentPage) {
                ForEach(0..<introItems.count, id: \.self) { index in
                    VStack {
                        Image(introItems[index].icon(for: colorScheme))
                            .resizable()
                            .scaledToFit()
                            .frame(height: 500)
                            .foregroundStyle(ThemeManager.gradientBackground)
                            .padding()
                            .scaleEffect(viewModel.animate ? 0.8 : 1.0)
                            .opacity(viewModel.animate ? 0 : 1)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.animate)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Text(introItems[index].title)
                            .fontStyle(size: 16, weight: .semibold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 15)
                            .padding()
                            .scaleEffect(viewModel.animate ? 0.8 : 1.0)
                            .opacity(viewModel.animate ? 0 : 1)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.animate)
                        
                        Text(introItems[index].description)
                            .fontStyle(size: 14, weight: .light)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .scaleEffect(viewModel.animate ? 0.8 : 1.0)
                            .opacity(viewModel.animate ? 0 : 1)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.animate)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            HStack(spacing: 8) {
                ForEach(0..<introItems.count, id: \.self) { index in
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundStyle(viewModel.currentPage == index ? ThemeManager.staticPinkColour : .gray.opacity(0.5))
                        .scaleEffect(viewModel.currentPage == index ? 1.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentPage)
                }
            }
            .padding(.vertical, 10)
            
            HStack {
                Spacer()
                Button(action: {
                    viewModel.stopTimer()
                    viewModel.handleNavigation()
                }) {
                    HStack(alignment: .center, spacing: 5) {
                        Text(Constants.skipSinglePermission)
                            .fontStyle(size: 15, weight: .bold)
                            .foregroundStyle(ThemeManager.gradientBackground)
                            .padding(.horizontal, 20)
                    }
                }
                .pressEffect()
            }
            .padding(.horizontal, 30)
        }
        .onDisappear {
            viewModel.stopTimer()
        }
        .onAppear {
            viewModel.userDataManager.setAppLaunched()
        }
    }
}

struct IntroScreenView_Previews: PreviewProvider {
    static var previews: some View {
        IntroScreenScene()
    }
}
