//
//  ReferAFriendObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 17-05-2025.
//

import Contacts
import SwiftUI

class ReferFriendViewModel: ObservableObject {
    @Published var contacts: [CNContact] = []
    @Published var selectedContacts: Set<String> = []
    @Published var permissionDenied = false
    let routeManager = RouteManager.shared
    
    func requestAndFetchContacts() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.fetchContacts(from: store)
                } else {
                    self.permissionDenied = true
                }
            }
        }
    }
    
    @MainActor private func fetchContacts(from store: CNContactStore) {
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey
        ] as [CNKeyDescriptor]
        
        let request = CNContactFetchRequest(keysToFetch: keys)
        var results: [CNContact] = []
        
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                DispatchQueue.main.async {
                    if !contact.phoneNumbers.isEmpty {
                        results.append(contact)
                    }
                }
            }
            DispatchQueue.main.async {
                self.contacts = results
            }
        } catch {
            print("Error fetching contacts: \(error)")
        }
    }
    
    func toggleSelection(for contact: CNContact) {
        if selectedContacts.contains(contact.identifier) {
            selectedContacts.remove(contact.identifier)
        } else {
            selectedContacts.insert(contact.identifier)
        }
    }
    
    func isSelected(_ contact: CNContact) -> Bool {
        selectedContacts.contains(contact.identifier)
    }
    
    func selectedPhoneNumbers() -> [String] {
        contacts
            .filter { selectedContacts.contains($0.identifier) }
            .compactMap { $0.phoneNumbers.first?.value.stringValue }
    }
}

