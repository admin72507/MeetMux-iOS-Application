//
//  ErrorView.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 31-12-2024.
//

import SwiftUI

struct ErrorView: View {
    var body: some View {
        ZStack {
            Color.blue // Background color
                .edgesIgnoringSafeArea(.all) // Ensures the color covers the entire screen, ignoring safe areas
            
            Text("Hello, ErrorView!")
                .foregroundColor(.white) // Optional: To make text visible against the background
                .font(.title) // Optional: Adjust font size
        }
    }
}

#Preview {
    ErrorView()
}

