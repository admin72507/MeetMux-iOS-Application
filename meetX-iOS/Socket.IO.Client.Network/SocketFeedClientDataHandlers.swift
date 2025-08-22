//
//  SocketFeedClientDataHandlers.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 11-07-2025.
//

import Combine
import Foundation

extension SocketFeedClient {

    // Handle new_post as array of PostItem
    func handleNewPostArrayResponse(data: [Any]) {
        guard let first = data.first else {
            logger.info("❌ Empty new post response")
            return
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: first, options: [])

            // Try to decode as array of PostItem first
            if let postItemsArray = try? JSONDecoder().decode([PostItem].self, from: jsonData) {
                logger.info("✅ Successfully decoded new posts array: \(postItemsArray.count) posts")

                if postItemsArray.count > 1 {
                    newPostsBatchSubject.send(postItemsArray)
                } else if let singlePost = postItemsArray.first {
                    newPostSubject.send(singlePost)
                }
                return
            }

            // Fallback: Try single PostItem
            if let postItem = try? JSONDecoder().decode(PostItem.self, from: jsonData) {
                logger.info("✅ Successfully decoded single new post: \(postItem.id)")
                newPostSubject.send(postItem)
                return
            }

            // Fallback: Try as FeedItems structure
            let feedItems = try JSONDecoder().decode(FeedItems.self, from: jsonData)
            if let posts = feedItems.posts, !posts.isEmpty {
                logger.info("✅ Successfully decoded new posts from FeedItems: \(posts.count) posts")

                if posts.count > 1 {
                    newPostsBatchSubject.send(posts)
                } else if let firstPost = posts.first {
                    newPostSubject.send(firstPost)
                }
            }

        } catch {
            logger.info("❌ Failed to decode new post array: \(error)")
        }
    }

    // Handle Main Data Response (Pagination/Initial Load)
    func handleFeedPostsResponse(data: [Any]) {
        guard let first = data.first else {
            logger.info("❌ Empty data response")
            let error = NSError(domain: "EmptyResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
            feedItemsSubject.send(completion: .failure(error))
            return
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: first, options: [])
            let feedItems = try JSONDecoder().decode(FeedItems.self, from: jsonData)
            logger.info("✅ Successfully decoded feed items: \(feedItems.posts?.count ?? 0) posts")
            feedItemsSubject.send(feedItems)
        } catch {
            logger.info("❌ Failed to decode feed items: \(error)")
            if let rawDict = first as? [String: Any] {
                let fallbackError = NSError(domain: "DecodingFailedButRawDataAvailable", code: 1, userInfo: rawDict)
                feedItemsSubject.send(completion: .failure(fallbackError))
            } else {
                feedItemsSubject.send(completion: .failure(error))
            }
        }
    }

    // MARK: - Like Response Handler
    func handleLikeResponse(data: [Any]) {
        guard let first = data.first as? [String: Any] else {
            logger.info("❌ Empty or invalid like response")
            return
        }

        let likeResponse = LikeResponse(
            postId: first["postId"] as? String ?? "",
            totalLikes: first["totalLikes"] as? Int ?? 0,
            success: first["success"] as? Bool ?? false,
            message: first["message"] as? String ?? ""
        )

        logger.info("✅ Like response - PostID: \(String(describing: likeResponse.postId)), Success: \(String(describing: likeResponse.success)), Message: \(String(describing: likeResponse.message))")

        likeUpdateSubject.send(likeResponse)
    }
}
