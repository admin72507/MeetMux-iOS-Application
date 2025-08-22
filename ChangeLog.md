//
//  ChangeLog.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 19-07-2025.
//

# Changelog

All notable changes to this Xcode project will be documented in this file.

## [Unreleased]


## [1.0.1] - 2025-07-20
## Build -> [1.8]
- Social Score Addition
- Chat option added for connected users inside profile screen
- Bug Fixing in chat list 
- OTP page crop bug
- Dynamic time convertor in Chat list 

## [1.0.0] - 2025-07-20
## Build -> [1.7]
### Added
- Initial project setup in Xcode 16.3.
 - Added SwiftUI-based user interface for MeetX Demo App.
- Setup `AppIcon` and LaunchScreen assets.
- Integrated Combine for reactive data handling.
 - Added Lottie for animated loaders.
- Created onboarding flow with page control.
- Setup modular structure: `Core`, `UI`, `SDK`, and `DemoApp`.
- Configured basic Unit and UI Tests targets.
- Added documentation folder (`/Docs`) with markdown files.
 Setup GitHub repository and pushed initial commit.
- **MeetX SDK Integration** for real-time chat and communication.
 - **Feed System** with support for:
- Image and video posts.
- Video auto-play with mute/unmute.
- Like, comment, and share functionality.
- **Profile Management**:
- Upload and swipe through profile pictures.
- Profile QR sharing.
- **Chat System**:
- Chat landing with horizontal user list.
- Messaging screen with scroll-to-bottom and options menu.
- **Activity Selection View** with expandable category grids.
- **Location Picker**:
- Search bar, recent locations, and “Locate Me” button.
- **Blocked User List** with paginated search and block/unblock actions.
- **Settings Screen**:
- Multiple toggles with dynamic Save button using Combine.
- Theme picker (Light, Dark, System) with full-screen swipe and animated SF Symbols.
- **Global Loader** using Lottie animations as an overlay.
- **Image/Video Picker**:
 - Supports both media types.
- Compresses videos.
- **AWS Integration**:
- Secure image/video uploads using AWS S3.
- Cognito Identity Pool-based access.
- Integration with Kingfisher for cached loading.
- **Navigation** using a centralized `AppRoutes` system (decoupled from root).
- **UI Optimization**:
- Scalable and modular feed card components.
- Lazy loading for better performance.
- SF Symbol-based theme transition animations.
- **Documentation**:
- In-app guides.
- Linked GitHub repo and external docs.

### Changed
- Unified media playback system to ensure only one video plays at a time.
- Optimized chat views to prevent layout glitches during tab switching.
- Improved caching behavior with Kingfisher for S3 media.
- Replaced Lottie overlays in theme selector with SF Symbols for lighter footprint.
