//
//  ProfessionalDetailScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 19-02-2025.
//

import SwiftUI

struct Profession: Identifiable {
    var id = UUID()
    var jobTitle: String = ""
    var companyName: String = ""
    var yearsOfExperience: String = ""
}

struct ProfessionalDetailScene: View {
    @State private var degree: String                       = ""
    @State private var institution: String                  = ""
    @State private var professions: [Profession]            = [Profession()]
    @StateObject private var viewModel                      = ProfessionalSeceneObserver()
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(Constants.lastEnducationText)
                        .fontStyle(size: 18, weight: .semibold)
                    CustomTextField(placeholder: Constants.degreeText, text: $degree)
                    CustomTextField(placeholder: Constants.institutionText, text: $institution)
                    
                    Text(Constants.professionalDetailsText)
                        .fontStyle(size: 18, weight: .semibold)
                    
                    ForEach(professions.indices, id: \.self) { index in
                        VStack(spacing: 10) {
                            CustomTextField(placeholder: Constants.jobTitleText, text: $professions[index].jobTitle)
                            CustomTextField(placeholder: Constants.companyNameText, text: $professions[index].companyName)
                            CustomTextField(placeholder: Constants.yearOfExpText, text: $professions[index].yearsOfExperience)
                            
                            HStack {
                                Spacer()
                                Button(action: {
                                    deleteProfession(at: index)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        professions.append(Profession())
                    }) {
                        HStack {
                            Image(systemName: DeveloperConstants.systemImage.plusCircleFill)
                            Text(Constants.addAnotherProfession)
                        }
                    }
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                    .padding(.top, 10)
                }
                .padding()
            }
            
            Spacer()
            
            if shouldShowSaveButton {
                Button(action: submitDetails) {
                    Text(Constants.saveButtonText)
                        .applyCustomButtonStyle()
                }
                .padding()
            }
        }.onTapGesture {
            hideKeyboard()
        }
    }
    
    private func deleteProfession(at index: Int) {
        professions.remove(at: index)
    }
    
    private var shouldShowSaveButton: Bool {
        !degree.isEmpty || !institution.isEmpty || professions.contains { !$0.jobTitle.isEmpty || !$0.companyName.isEmpty || !$0.yearsOfExperience.isEmpty }
    }
    
    private func submitDetails() {
        print("Education: \(degree) at \(institution)")
        for profession in professions {
            print("Profession: \(profession.jobTitle) at \(profession.companyName), Experience: \(profession.yearsOfExperience)")
        }
    }
}


// Reusable TextField Component
struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
    }
}
