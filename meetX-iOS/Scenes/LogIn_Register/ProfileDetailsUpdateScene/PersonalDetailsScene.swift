//
//  PersonalDetailsScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 10-02-2025.
//

import SwiftUI
import AlertToast

struct PersonalDetailsScene: View {
    
    @EnvironmentObject var keyboardResponder    : KeyboardHelper
    @State private var nameLimitAlert: Bool     = false
    @State private var bioLimitAlert: Bool      = false
    @State private var emailToastAlert: Bool    = false
    @State private var showDatePicker: Bool     = false
    @State private var selectedDate             : Date = Date()
    @Binding var selectedGender                 : Int
    @Binding var username                       : String
    @Binding var bioText                        : String
    @Binding var emailAddress                   : String
    @Binding var formattedDate                  : String
    var fromEditProfile                         : Bool
    let helperFunctions                         : HelperFunctions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            NameInputView(username: $username,
                          nameLimitAlert: $nameLimitAlert,
                          helperFunction: helperFunctions,
                          fromProfileEdit: fromEditProfile)
            
            BioSectionView(bioText: $bioText,
                           limitAlert: $bioLimitAlert,
                           helperFunction: helperFunctions)
            
            EmailInputView(emailAddress: $emailAddress,
                           emailToastAlert: $emailToastAlert,
                           helperFunction: helperFunctions)
            
            if !fromEditProfile {
                GenderSelectionView(selectedGender: $selectedGender,
                                    helperFunction: helperFunctions)
                
                DateOfBirthView(selectedDate: $selectedDate,
                                formattedDate: $formattedDate,
                                showDatePicker: $showDatePicker)
            }
        }
    }
}

//MARK: - Name Input View
struct NameInputView: View {
    @Binding var username           : String
    @Binding var nameLimitAlert     : Bool
    let helperFunction              : HelperFunctions
    let fromProfileEdit: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            RedAsteriskTextView(title: Constants.fullName)
            Text(fromProfileEdit ? Constants.changeYourDisplayName : Constants.fullNameDesc)
                .fontStyle(size: 12, weight: .light)
                .foregroundStyle(.secondary)
            
            TextField(Constants.fullNamePlaceholder, text: $username)
                .keyboardType(.namePhonePad)
                .fontStyle(size: 12, weight: .regular)
                .foregroundColor(ThemeManager.foregroundColor)
                .onChange(of: username) { oldValue, newValue in
                    if newValue.count >= 20 {
                        username = String(oldValue.prefix(20))
                    }
                }
                .toast(isPresenting: $nameLimitAlert) {
                    self.helperFunction.toastSystemImage(Constants.fullNameErrorTitle, Constants.fullNameErrorBody)
                }
                .styledTextField()
        }
    }
}

// MARK: - Bio Segment
struct BioSectionView: View {
    @Binding var bioText           : String
    @Binding var limitAlert         : Bool
    let helperFunction              : HelperFunctions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            RedAsteriskTextView(title: Constants.bioSectionTitle)
            Text(Constants.bioSectionSubTitle)
                .fontStyle(size: 12, weight: .light)
                .foregroundStyle(.secondary)
            
            TextField(Constants.bioPlaceholder, text: $bioText)
                .keyboardType(.default)
                .fontStyle(size: 12, weight: .regular)
                .foregroundColor(ThemeManager.foregroundColor)
                .onChange(of: bioText) { oldValue, newValue in
                    if newValue.count >= DeveloperConstants.LoginRegister.bioCharacterLimt {
                        bioText = String(oldValue.prefix(DeveloperConstants.LoginRegister.bioCharacterLimt))
                    }
                }
                .toast(isPresenting: $limitAlert) {
                    self.helperFunction.toastSystemImage(Constants.bioLimitReached, Constants.bioErrorBodyLimit)
                }
                .styledTextField()
        }
    }
}

//MARK: - Email Input
struct EmailInputView: View {
    @Binding var emailAddress       : String
    @Binding var emailToastAlert    : Bool
    let helperFunction              : HelperFunctions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            RedAsteriskTextView(title: Constants.emailAddressTitle)
            Text(Constants.enterPrimaryEmail)
                .fontStyle(size: 12, weight: .light)
                .foregroundStyle(.secondary)
            
            TextField(Constants.enterEmail, text: $emailAddress)
                .keyboardType(.emailAddress)
                .fontStyle(size: 12, weight: .regular)
                .foregroundColor(ThemeManager.foregroundColor)
                .onChange(of: emailAddress) { oldValue, newValue in
                    if newValue.count > 30 {
                        emailAddress = String(oldValue.prefix(30))
                        emailToastAlert = true
                    }
                }
                .toast(isPresenting: $emailToastAlert) {
                    self.helperFunction.toastSystemImage(Constants.emailVerificationFail,
                                                         Constants.emailError)
                }
                .styledTextField()
        }
    }
}

//MARK: - Gender Selection
struct GenderSelectionView: View {
    @Binding var selectedGender     : Int
    let helperFunction              : HelperFunctions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            RedAsteriskTextView(title: Constants.genderTitle)
            Text(Constants.genderDesc)
                .fontStyle(size: 12, weight: .light)
                .foregroundStyle(.secondary)
            
            Menu {
                ForEach(genderOptions) { gender in
                    Button(action: { selectedGender = gender.id }) {
                        Label(gender.name, systemImage: gender.icon)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: DeveloperConstants.systemImage.personFillImage)
                        .foregroundColor(.purple)
                    Text(helperFunction.genderIDToString(selectedGender))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fontStyle(size: 12, weight: .regular)
                    Image(systemName: DeveloperConstants.systemImage.downArrowImage)
                        .foregroundColor(.purple)
                }
                .styledTextField()
            }
        }
    }
}

//MARK: - Date of Birth
struct DateOfBirthView: View {
    @Binding var selectedDate: Date
    @Binding var formattedDate: String
    @Binding var showDatePicker: Bool
    
    @State private var tempSelectedDate: Date = Date()
    
    var viewModel = ProfileDetailViewModel()
    
    // Create proper date range - from 1950 to current date
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 1950, month: 1, day: 1)) ?? Date()
        let endDate = Date() // Current date
        return startDate...endDate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            RedAsteriskTextView(title: Constants.dateOfBirth)
            
            Text(Constants.dateOfBirthDesc)
                .fontStyle(size: 12, weight: .light)
                .foregroundStyle(.secondary)
            
            Button(action: {
                hideKeyboard()
                tempSelectedDate = selectedDate
                showDatePicker.toggle()
            }) {
                HStack {
                    Text(formattedDate.isEmpty ? Constants.selectDatrOfBirth : formattedDate)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fontStyle(size: 12, weight: .regular)
                    
                    Image(systemName: DeveloperConstants.systemImage.calenderImage)
                        .foregroundColor(.purple)
                }
                .styledTextField()
            }
            
        }
        .onAppear {
            // Initialize tempSelectedDate if selectedDate is not set
            if selectedDate == Date() {
                let calendar = Calendar.current
                tempSelectedDate = calendar.date(from: DateComponents(year: 1990, month: 1, day: 1)) ?? Date()
            } else {
                tempSelectedDate = selectedDate
            }
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationView {
                VStack(spacing: 20) {
                    // Date Picker - Full graphical calendar in modal
                    DatePicker(
                        "",
                        selection: $tempSelectedDate,
                        in: dateRange,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .accentColor(.purple)
                    .tint(.purple)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle(Constants.dateOfBirth)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(Constants.cancelText) {
                            showDatePicker = false
                        }
                        .foregroundColor(.red)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(Constants.doneText) {
                            selectedDate = tempSelectedDate
                            formattedDate = viewModel.dateFormatter.string(from: tempSelectedDate)
                            showDatePicker = false
                        }
                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                    }
                }
            }
            .presentationDetents([.medium, .large]) // Allows half-screen or full-screen
        }
    }
}
