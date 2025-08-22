//
//  MenuScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 28-05-2025.
//
import SwiftUI

struct GenderWheelPickerView: View {
    @Binding var isPresented: Bool
    @Binding var selectedGender: String
    
    let options: [String]
    var onSelect: (String) -> Void
    
    @State private var tempSelection: String = ""
    
    var body: some View {
        VStack {
            
            HStack {
                Spacer()
                Button("Done") {
                    isPresented = false
                    onSelect(tempSelection)
                }
                .fontStyle(size: 14, weight: .regular)
                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                .padding()
            }
            
            Picker("Select Gender", selection: $tempSelection) {
                ForEach(options, id: \.self) { gender in
                    Text(gender).tag(gender)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            
            Spacer()
        }
        .onAppear {
            self.tempSelection = selectedGender.isEmpty ? options.first ?? "" : selectedGender
        }
    }
}

