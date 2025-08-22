//
//  AboutAppScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 06-04-2025.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        let request = URLRequest(url: url)
        webView.load(request)
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct WebContentView: View {
    let urlString: String
    
    init(urlString: String) {
        self.urlString = urlString

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let url = URL(string: urlString) {
                WebView(url: url)
                    .ignoresSafeArea(edges: .bottom) // Only bottom, nav bar stays clean
            } else {
                Text("Invalid URL")
                    .foregroundColor(.red)
            }
        }
    }
}
