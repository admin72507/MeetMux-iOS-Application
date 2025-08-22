//
//  ChatSoundCreator.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 12-07-2025.
//

import AVFoundation

private var audioPlayer: AVAudioPlayer?

private func playNewMessageSound() {
    guard let soundURL = Bundle.main.url(forResource: "message_received", withExtension: "mp3") else {
        print("🔇 Sound file not found")
        return
    }

    do {
        audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
        audioPlayer?.play()
        print("🔔 Played new message sound")
    } catch {
        print("❌ Failed to play sound: \(error)")
    }
}

func playSystemSoundForNewMessage() {
    let tweetSoundID: SystemSoundID = 1016
    AudioServicesPlaySystemSound(tweetSoundID)
    print("🐦 Played tweet system sound for new message")
}
