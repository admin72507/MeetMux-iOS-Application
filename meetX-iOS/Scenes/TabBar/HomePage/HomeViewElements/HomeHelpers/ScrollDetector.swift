//
//  ScrollDetector.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 03-05-2025.
//

import SwiftUI

struct ScrollDetector: UIViewRepresentable {
    var onScroll: (CGFloat) -> Void
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.isUserInteractionEnabled = false
        scrollView.isScrollEnabled = false
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScroll: onScroll)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var onScroll: (CGFloat) -> Void
        
        init(onScroll: @escaping (CGFloat) -> Void) {
            self.onScroll = onScroll
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            onScroll(scrollView.contentOffset.y)
        }
    }
}
