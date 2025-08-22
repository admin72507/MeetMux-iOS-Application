//
//  ShareApplication.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 06-04-2025.
//

import SwiftUI

// Main view with share button
struct ShareAppView: View {
    
    @State private var isSharing            = false
    let appDeepLink: String
    
    init(appDeepLink: String) {
        self.appDeepLink = appDeepLink
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Share the love 💙")
                .font(.title2)
                .bold()
            
            Text("Let your friends know about us.")
                .foregroundColor(.gray)
            
            Button {
                isSharing = true
            } label: {
                Label("Share App", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .sheet(isPresented: $isSharing) {
                ShareSheet(items: [appDeepLink])
            }
        }
        .padding()
    }
}

#Preview {
    ShareAppView(appDeepLink: "www.meetmux.com")
}
