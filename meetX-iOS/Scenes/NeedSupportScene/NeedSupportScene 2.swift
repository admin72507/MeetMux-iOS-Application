//
//  NeedSupportScene 2.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 23-03-2025.
//


struct NeedSupportScene: View {
    @StateObject private var viewModel = NeedSupportViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            headerView
                .padding()
            
            Form {
                inputSection(title: Constants.mobileNumberTitle) {
                    TextField(Constants.placeHolderText, text: $viewModel.mobileNumber)
                        .keyboardType(.phonePad)
                        .styledTextFieldSupport()
                        .fontStyle(size: 12, weight: .regular)
                }
                
                inputSection(title: Constants.selectYourIssue) {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(Constants.issues, id: \.self) { issue in
                            RadioButtonField(label: issue, isSelected: viewModel.selectedIssue == issue) {
                                viewModel.selectedIssue = issue
                            }
                            .contentShape(Rectangle()) // Expands tappable area
                            .padding(.vertical, 5)
                        }
                    }
                }
                
                inputSection(title: Constants.additionalDetails) {
                    TextField(Constants.describeRequest, text: $viewModel.requestDetails)
                        .styledTextFieldSupport()
                        .fontStyle(size: 12, weight: .regular)
                }
            }
            .scrollContentBackground(.hidden)
            
            Spacer()
            footerView
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    struct RadioButtonField: View {
        var label: String
        var isSelected: Bool
        var action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Image(systemName: isSelected ? DeveloperConstants.systemImage.largeCircleImage : DeveloperConstants.systemImage.circleHexagonal)
                        .foregroundColor(ThemeManager.staticPurpleColour)
                    
                    Text(label)
                        .fontStyle(size: 12, weight: isSelected ? .regular : .light)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle()) // Ensures whole row is tappable
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Text(Constants.contactSupportHeading)
                .fontStyle(size: 18, weight: .semibold)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text(Constants.needHelpToSubTitle)
                .fontStyle(size: 14, weight: .light)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    private var footerView: some View {
        VStack(spacing: 16) {
            Label {
                Button(action: viewModel.callSupport) {
                    Text(DeveloperConstants.General.supportMobileNumber)
                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        .fontStyle(size: 12, weight: .semibold)
                }
            } icon: {
                Image(systemName: DeveloperConstants.systemImage.phoneImage)
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
            }
            
            Label {
                Button(action: viewModel.sendEmail) {
                    Text(Constants.sendEmailToSupport)
                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                        .fontStyle(size: 12, weight: .semibold)
                }
            } icon: {
                Image(systemName: DeveloperConstants.systemImage.paperPlaneImage)
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)
            }
            
            Button(action: viewModel.submitRequest) {
                Text(Constants.submitRequest)
                    .applyCustomButtonStyle()
                    .pressEffect()
            }
        }
    }
    
    private func inputSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        Section(header: Text(title)
            .fontStyle(size: 14, weight: .semibold)
            .foregroundStyle(ThemeManager.foregroundColor)
            .textCase(nil)) {
                content()
            }
    }
}