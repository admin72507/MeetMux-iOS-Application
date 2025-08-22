//
//  RateUs.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 16-05-2025.
//

import SwiftUI
import StoreKit

struct RateUsSheet: View {
    
    @Binding var isPresented: Bool
    @State private var rating: Int = 0
    @Environment(\.requestReview) private var requestReview
    
    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
            
            Text("Rate Us")
                .fontStyle(size: 16, weight: .semibold)
                .multilineTextAlignment(.center)
                .padding(.top)
            
            Text("How was your experience? Feedback helps us improve.")
                .fontStyle(size: 14, weight: .light)
                .foregroundColor(.gray)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.yellow)
                        .onTapGesture {
                            rating = index
                        }
                }
            }
            .padding(.top, 4)
            
            HStack(spacing: 16) {
                Button(action: {
                    isPresented = false
                }) {
                    Text(Constants.cancelText)
                        .fontStyle(size: 14, weight: .medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(10)
                        .foregroundStyle(ThemeManager.foregroundColor)
                }
                
                Button(action: {
                    isPresented = false
                  //  handleSubmit()
                }) {
                    Text("Submit")
                        .fontStyle(size: 14, weight: .semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ThemeManager.gradientBackground)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .shadow(color: ThemeManager.staticPurpleColour.opacity(0.5), radius: 5, x: 2, y: 5)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .presentationDetents([.height(250)])
    }
    
    private func handleSubmit() {
        isPresented = false
        if rating >= 4 {
            requestReview()
        } else {
            // Optionally collect internal feedback here
            print("Thanks for the feedback!")
        }
    }
}
