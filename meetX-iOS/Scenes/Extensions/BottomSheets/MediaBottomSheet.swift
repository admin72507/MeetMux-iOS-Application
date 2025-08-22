//
//  MediaBottomSheet.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 08-02-2025.
//

import SwiftUI

struct AddPhotoBottomSheet: View {
    @Binding var isPresented: Bool
    let title: String
    
    // Data for TableView
    let options: [(title: String, icon: String, action: () -> Void)]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .fontStyle(size: 14, weight: .semibold)
                    .foregroundColor(ThemeManager.foregroundColor)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: DeveloperConstants.systemImage.closeXmarkNormal)
                        .fontStyle(size: 14, weight: .semibold)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding()
            
            List {
                ForEach(options, id: \.title) { option in
                    Button(action: {
                        isPresented = false
                        option.action()
                    }) {
                        HStack {
                            Text(option.title)
                                .fontStyle(size: 14, weight: .regular)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: option.icon)
                                .fontStyle(size: 14, weight: .regular)
                                .foregroundColor(.primary)
                        }
                        .padding()
                    }
                    .listRowBackground(Color(uiColor: .systemBackground))
                    .padding(.bottom, 5)
                    
                }

            }
            .listStyle(.plain)
            .background(.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Preview
#Preview {
    AddPhotoBottomSheet(
        isPresented: .constant(true), title: "jhfytfytu",
        options: [
            (title: "Choose Photo", icon: "photo.on.rectangle", action: { print("Photo Library") }),
            (title: "Take Photo", icon: "camera", action: { print("Camera") })
        ]
    )
    .frame(height: 250)
}
