//
//  ChatRoomObservable+Extension.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 10-07-2025.
//

import Combine
import Foundation

extension ChatRoomViewModel {

    // MARK: - All the message Read
    /// When the user enter the chat room make it read
    /// Also mark the entire conversation as read
    func markAllMessagesAsRead() {
        let unreadMessages = messages.filter {
            !($0.isMessageRead ?? false) && $0.senderId != currentUserId
        }
        for message in unreadMessages {
            socketClient?
                .emitMarkAllMessagesAsRead(
                    senderId: message.senderId ?? "",
                    receiverId: message.receiverId ?? ""
                )
            return
        }
    }

    // MARK: - Private Room Call
    func makePrivateRoomSocketCall(
        receiverId: String,
        onCompletion: @escaping (Result<RecentChat, Error>) -> Void
    ) {
        socketClient?
            .emitMakeRoomPrivate(receiverId: receiverId, completion: { data in
                onCompletion(data)
        })
    }

    // MARK: - Private Room Socket turing off
    func makePrivateRoomSocketCallOff(
        receiverId: String
    ) {
        socketClient?
            .emitMakePrivateRoomTurnOff(receiverId: receiverId)
    }
}
