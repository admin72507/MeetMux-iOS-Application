//
//  ReferFriendsListScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 17-05-2025.
//

import SwiftUI
import MessageUI
import Contacts

struct ReferFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ReferFriendViewModel()
    @State private var searchText = ""
    @State private var showMessageSheet = false
    
    var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return viewModel.contacts
        } else {
            return viewModel.contacts.filter {
                $0.givenName.localizedCaseInsensitiveContains(searchText) ||
                $0.familyName.localizedCaseInsensitiveContains(searchText) ||
                $0.phoneNumbers.first?.value.stringValue.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List(filteredContacts, id: \.identifier) { contact in
                Button(action: {
                    viewModel.toggleSelection(for: contact)
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(contact.givenName) \(contact.familyName)")
                            if let phone = contact.phoneNumbers.first?.value.stringValue {
                                Text(phone).font(.caption).foregroundColor(.gray)
                            }
                        }
                        Spacer()
                        if viewModel.isSelected(contact) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .toolbar {
                Button("Share") {
                    showMessageSheet = true
                }
                .disabled(viewModel.selectedContacts.isEmpty)
            }
            .onAppear {
                viewModel.requestAndFetchContacts()
            }
            .sheet(isPresented: $showMessageSheet) {
                MessageComposer(
                    recipients: viewModel.selectedPhoneNumbers(),
                    body: "Hey! Check out this awesome app: \(DeveloperConstants.appShareDeeplink)"
                )
            }
            .generalNavBarInControlRoom(
                title: "Refer Friends",
                subtitle: "Select and Share MeetMux",
                image: "paintbrush.fill",
                onBacktapped: { dismiss() }
            )
        }
    }
}

struct MessageComposer: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = recipients
        vc.body = body
        vc.messageComposeDelegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
    }
}
