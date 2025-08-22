//
//  SearchRecommendationModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 30-05-2025.
//

import Foundation

struct SearchRecommendationsModel: Codable {
    let currentPage: Int
    let limit: Int
    let totalCount: Int
    let data: [RecommendedUser]
}

struct RecommendedUser: Codable, Identifiable, Hashable {
    var id: String { userId }
    
    let userId: String
    let name: String
    let username: String
    let profilePicUrls: String
    let latitude: Double?
    let longitude: Double?
    let userActivities: [Int]?
    let rawDistance: Double?
    let matchPercent: Double?
    let isRealMatch: Bool?
    let distance: String?
    var isFollowing: Bool?
    var isFollowRequested: Bool?
    var isConnected: Bool?
    var isConnectionRequested: Bool?
    var followers: Int? // followers count
    let following: Int? // following count
    var connections: Int? // connection count
    let postCount: Int? // post count
    
    enum CodingKeys: String, CodingKey {
        case userId
        case name
        case username
        case profilePicUrls
        case latitude
        case longitude
        case userActivities = "user_activities"
        case rawDistance
        case matchPercent
        case isRealMatch
        case distance
        case isFollowing
        case isFollowRequested
        case isConnected
        case isConnectionRequested
        case followers
        case following
        case connections
        case postCount
    }
}

// MARK: - RecommendedUser Extension for Follow System
extension RecommendedUser {
    mutating func updateFromFollowResponse(_ response: UnFollowFollowBackResponse, expectedAction: DeveloperConstants.FollowActionType) -> Bool {
        // Validate if the response matches the expected action
        let isValidResponse = validateFollowResponseForAction(response, expectedAction: expectedAction)
        
        if !isValidResponse {
            print("⚠️ Warning: Follow API response doesn't match expected action")
            return false
        }
        
        // Update follow status based on response
        if response.followed {
            // User is now following or follow request is pending
            if let requestPending = response.requestPending {
                if requestPending {
                    // Follow request is pending (private account)
                    self.isFollowRequested = true
                    self.isFollowing = false
                } else {
                    // Follow request accepted immediately (public account)
                    self.isFollowRequested = false
                    self.isFollowing = true
                    // Increment followers count
                    if let currentFollowers = self.followers {
                        self.followers = currentFollowers + 1
                    }
                }
            } else {
                // Default case - user is following
                self.isFollowRequested = false
                self.isFollowing = true
                if let currentFollowers = self.followers {
                    self.followers = currentFollowers + 1
                }
            }
        } else {
            // Handle the case where followed = false but requestPending = true
            // This means a follow request is pending or already sent
            if let requestPending = response.requestPending, requestPending {
                self.isFollowRequested = true
                self.isFollowing = false
            } else {
                // User unfollowed or cancelled follow request
                self.isFollowing = false
                self.isFollowRequested = false
                // Decrement followers count
                if let currentFollowers = self.followers, currentFollowers > 0 {
                    self.followers = currentFollowers - 1
                }
            }
        }
        
        return true
    }
    
    private func validateFollowResponseForAction(_ response: UnFollowFollowBackResponse, expectedAction: DeveloperConstants.FollowActionType) -> Bool {
        guard let message = response.message?.lowercased() else {
            return false
        }
        
        switch expectedAction {
            case .sendFollowRequest:
                // Case 1: Follow is successful (public profile)
                let isPublicFollow = response.followed == true && message.contains("follow")
                
                // Case 2: Follow request is pending (private profile) - new or already sent
                let isPrivateRequestPending = response.requestPending == true &&
                (message.contains("follow request") || message.contains("request"))
                
                // Case 3: Already following but response indicates followed = false with pending request
                // This can happen when the request was already sent
                let isAlreadyRequested = response.followed == false &&
                response.requestPending == true &&
                (message.contains("already") || message.contains("sent"))
                
                return isPublicFollow || isPrivateRequestPending || isAlreadyRequested
                
            case .cancelFollowRequest, .removeFollow:
                // Expected: followed = false, message contains "unfollow" or "cancel"
                return response.followed == false &&
                (message.contains("unfollow") || message.contains("cancel"))
        }
    }
}

// MARK: - RecommendedUser Extension for Connect System
extension RecommendedUser {
    mutating func updateFromConnectResponseSuggestion(_ response: ConnectAndFollowModel) {
        // Update connection status based on chat details
        switch response.chat.status {
            case "pending":
                self.isConnectionRequested = true
                self.isConnected = false
            case "accepted":
                self.isConnectionRequested = false
                self.isConnected = true
                // Increment connections count when accepted
                if let currentConnections = self.connections {
                    self.connections = currentConnections + 1
                }
            case "cancelled", "disconnected":
                self.isConnectionRequested = false
                self.isConnected = false
                // Decrement connections count when cancelled (if it was previously connected)
                if let currentConnections = self.connections, currentConnections > 0 {
                    self.connections = currentConnections - 1
                }
            default:
                break
        }
        
        // Update follow status based on follow details if needed
        switch response.follow.status {
            case "pending":
                self.isFollowRequested = true
                self.isFollowing = false
            case "accepted":
                self.isFollowRequested = false
                self.isFollowing = true
                // Increment followers count when follow is accepted
                if let currentFollowers = self.followers {
                    self.followers = currentFollowers + 1
                }
            case "cancelled", "unfollowed":
                self.isFollowRequested = false
                self.isFollowing = false
                // Decrement followers count when follow is cancelled
                if let currentFollowers = self.followers, currentFollowers > 0 {
                    self.followers = currentFollowers - 1
                }
            default:
                break
        }
    }
}
