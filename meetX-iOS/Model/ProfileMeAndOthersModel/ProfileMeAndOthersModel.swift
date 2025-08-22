//
//  ProfileMeAndOthersModel.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 29-05-2025.
//

import Foundation

struct UserProfileResponse: Codable {
    let posts: [PostItem]
    let success: Bool?
    let pagination: PagenationProfile?
    let user: UserProfileData?
}

struct PagenationProfile: Codable {
    let totalPosts: Int?
    let totalPages: Int?
    let currentPage: Int?
    let limitPerPage: Int?
}

// MARK: - UserProfile
struct UserProfileData: Codable {
    let about: String?
    let connections: Int?
    let countryCode: String?
    let createdAt: String?
    let deepLink: String?
    let deletedAt: String?
    let socialScore: SocialScore?
    let dob: String?
    let email: String?
    let fcmToken: String?
    var followers: Int?
    let following: Int?
    let gender: String?
    let interests: [SubActivitiesModel]?
    let isDeactivated: Bool?
    let isPrivate: Bool?
    let isProfileCompleted: Bool?
    let isVerified: Bool?
    let lastLogin: String?
    let latitude: Double?
    let longitude: Double?
    let mobileNumber: String?
    let name: String?
    let postCount: Int?
    let profilePicUrls: [String]?
    let notSignedUrls: [String]?
    let qrCode: String?
    let updatedAt: String?
    let userId: String?
    let userActivities: [Int]?
    let username: String?
    let verificationPhotoProcessed: Bool?
    var isFollowing: Bool?
    var isConnected: Bool?
    var isConnectionRequested: Bool?
    var isFollowRequested: Bool?
    
    enum CodingKeys: String, CodingKey {
        case about, connections, countryCode, createdAt, deepLink, deletedAt, dob, email, fcmToken
        case followers, following, gender, interests, isDeactivated, isPrivate, isProfileCompleted, socialScore
        case isVerified, lastLogin, latitude, longitude, mobileNumber, name, postCount
        case profilePicUrls, qrCode, updatedAt, userId, userActivities = "user_activities"
        case username, verificationPhotoProcessed, isFollowing, isConnected, isFollowRequested, isConnectionRequested, notSignedUrls
    }
}

struct CommentSection: Codable, Identifiable {
    var id: String?
    let text: String?
    let userId: String?
    let userName: String?
    let createdAt: String?
    let profilePicUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "comment_id"
        case text
        case userId
        case userName
        case createdAt = "created_at"
        case profilePicUrl
    }
}

// MARK: - Extension to handle the button action change
// MARK: - Recommended Clean Implementation
extension UserProfileData {
    mutating func updateFromConnectResponse(_ response: ConnectAndFollowModel) {
        // Update connection status based on chat details
        switch response.chat.status {
            case "pending":
                self.isConnectionRequested = true
                self.isConnected = false
            case "accepted":
                self.isConnectionRequested = false
                self.isConnected = true
            case "cancelled", "disconnected":
                self.isConnectionRequested = false
                self.isConnected = false
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
            case "cancelled", "unfollowed":
                self.isFollowRequested = false
                self.isFollowing = false
            default:
                break
        }
    }
}

// MARK: - UserProfileData Extension for Follow System
extension UserProfileData {
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
