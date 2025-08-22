//
//  MenuComponent.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 21-03-2025.
//

import SwiftUI

struct GenericPickerMenu: View {
    
    @Binding var isVisible: Bool
    @Binding var selectedOption: PickerOption
    let listDetails: [PickerOption]
    
    var body: some View {
        Menu {
            ForEach(listDetails) { option in
                Button(action: {
                    selectedOption = option
                    isVisible = false
                }) {
                    HStack {
                        Text(option.displayText)
                        Spacer()
                        if selectedOption.value == option.value {
                            Image(systemName: DeveloperConstants.systemImage.checkMark)
                                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedOption.value)
                    .foregroundColor(ThemeManager.foregroundColor)
                    .fontStyle(size: 14, weight: .light)
                    .padding(.trailing, 4)
                
                Image(systemName: isVisible ? DeveloperConstants.systemImage.upArrowImage : DeveloperConstants.systemImage.downArrowImage)
                    .font(.system(size: 14))
                    .foregroundColor(ThemeManager.foregroundColor)
            }
            .padding()
        }
        .onTapGesture {
            isVisible.toggle()
        }
    }
}



// MARK: - Model for Picker Options
struct PickerOption: Identifiable {
    let id = UUID()
    let value: String
    let displayText: String
}
