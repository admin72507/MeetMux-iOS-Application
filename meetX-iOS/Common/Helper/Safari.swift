//
//  Safari.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 07-02-2025.
//

import SwiftUI
import SafariServices

struct SafariView: View {
    let url: URL
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        SafariViewController(url: url)
            .ignoresSafeArea()
    }
}

struct SafariViewController: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

