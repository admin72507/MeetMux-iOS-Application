//
//  CustomHomeNavBar.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 23-02-2025.
//

import SwiftUI

struct CustomeHomeNavBar: View {
    let title: String
    let subtitle: String
    let hasNotification: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.white)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .resizable()
                        .frame(width: 10, height: 5)
                        .foregroundColor(.white)
                }
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    print("Search tapped")
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    print("Notifications tapped")
                }) {
                    ZStack {
                        Image(systemName: "bell")
                            .font(.title3)
                            .foregroundColor(.white)
                        if hasNotification {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .offset(x: 8, y: -8)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .background(Color.blue)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CustomeHomeNavBar(
            title: "Home",
            subtitle: "Bollineni hills, block 57, villa no 8, Nookampalayam, Arasank...",
            hasNotification: true
        )
    }
}
