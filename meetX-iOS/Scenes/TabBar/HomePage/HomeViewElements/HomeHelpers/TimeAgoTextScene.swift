//
//  TimeAgoTextScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-05-2025.
//

import SwiftUI

struct TimeAgoText: View {
    let utcString: String
    @ObservedObject private var timer = TimerManager.shared
    @State private var timeAgo: String = ""
    
    var body: some View {
        Text(timeAgo)
            .onAppear {
                updateTimeAgo()
            }
            .onChange(of: timer.now) { _,_ in
                updateTimeAgo()
            }
    }
    
    private func updateTimeAgo() {
        let newTime = timeAgoConvertor(from: utcString, relativeTo: timer.now)
        if newTime != timeAgo {
            timeAgo = newTime
        }
    }
}
