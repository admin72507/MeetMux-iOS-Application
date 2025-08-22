//
//  MarkerCreation.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 09-06-2025.
//

import Foundation
import UIKit
import Kingfisher

class MarkerIconCache {
    static let shared = MarkerIconCache()
    
    // Cache for different marker types
    private var defaultMarkerIcon: UIImage?
    private var eventMarkerIcon: UIImage?
    private var activityMarkerIcon: UIImage?
    private var meetupMarkerIcon: UIImage?
    
    // Cache for profile image markers
    private var profileImageCache: [String: UIImage] = [:]
    
    private init() {}
    
    func getDefaultMarkerIcon() -> UIImage {
        if let cached = defaultMarkerIcon {
            return cached
        }
        let icon = createCustomMarkerIcon(color: UIColor.systemPink)
        defaultMarkerIcon = icon
        return icon
    }
    
    func getMarkerIcon(for postType: String?) -> UIImage {
        switch postType {
            case "event":
                if let cached = eventMarkerIcon {
                    return cached
                }
                let icon = createCustomMarkerIcon(color: .systemOrange)
                eventMarkerIcon = icon
                return icon
                
            case "activity":
                if let cached = activityMarkerIcon {
                    return cached
                }
                let icon = createCustomMarkerIcon(color: .systemGreen)
                activityMarkerIcon = icon
                return icon
                
            case "meetup":
                if let cached = meetupMarkerIcon {
                    return cached
                }
                let icon = createCustomMarkerIcon(color: .systemPurple)
                meetupMarkerIcon = icon
                return icon
                
            default:
                return getDefaultMarkerIcon()
        }
    }
    
    // NEW: Method to get profile image marker
    func getProfileMarkerIcon(imageUrl: String, completion: @escaping (UIImage) -> Void) {
        // Check cache first
        if let cached = profileImageCache[imageUrl] {
            completion(cached)
            return
        }
        
        // Download image with Kingfisher
        guard let url = URL(string: imageUrl) else {
            completion(getDefaultMarkerIcon())
            return
        }
        
        KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
            switch result {
                case .success(let value):
                    let markerIcon = self?.createProfileMarkerIcon(profileImage: value.image) ?? self?.getDefaultMarkerIcon()
                    if let icon = markerIcon {
                        self?.profileImageCache[imageUrl] = icon
                        DispatchQueue.main.async {
                            completion(icon)
                        }
                    }
                case .failure(_):
                    DispatchQueue.main.async {
                        completion(self?.getDefaultMarkerIcon() ?? UIImage())
                    }
            }
        }
    }
    
    private func createCustomMarkerIcon(color: UIColor) -> UIImage {
        let markerSize = CGSize(width: 40, height: 48)
        let renderer = UIGraphicsImageRenderer(size: markerSize)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Main circle
            let circleRect = CGRect(x: 4, y: 4, width: 32, height: 32)
            let tipPoint = CGPoint(x: markerSize.width / 2, y: markerSize.height - 4)
            
            cgContext.saveGState()
            
            // Draw circle with gradient effect
            cgContext.setFillColor(color.cgColor)
            cgContext.fillEllipse(in: circleRect)
            
            // Draw triangle tip
            cgContext.move(to: CGPoint(x: circleRect.midX - 8, y: circleRect.maxY))
            cgContext.addLine(to: tipPoint)
            cgContext.addLine(to: CGPoint(x: circleRect.midX + 8, y: circleRect.maxY))
            cgContext.closePath()
            cgContext.fillPath()
            
            cgContext.restoreGState()
            
            // White border
            cgContext.setStrokeColor(UIColor.white.cgColor)
            cgContext.setLineWidth(2)
            cgContext.strokeEllipse(in: circleRect)
            
            // Icon
            let iconRect = circleRect.insetBy(dx: 6, dy: 6)
            if let iconImage = UIImage(systemName: "location.fill") {
                iconImage.withTintColor(.white).draw(in: iconRect)
            }
        }
    }
    
    // NEW: Create marker with profile image
    private func createProfileMarkerIcon(profileImage: UIImage) -> UIImage {
        let markerSize = CGSize(width: 50, height: 60)
        let renderer = UIGraphicsImageRenderer(size: markerSize)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Main circle for profile image
            let circleRect = CGRect(x: 5, y: 5, width: 40, height: 40)
            let tipPoint = CGPoint(x: markerSize.width / 2, y: markerSize.height - 5)
            
            cgContext.saveGState()
            
            // Create circular clipping path for profile image
            cgContext.addEllipse(in: circleRect)
            cgContext.clip()
            
            // Draw profile image
            profileImage.draw(in: circleRect)
            cgContext.restoreGState()
            
            // Draw triangle tip
            cgContext.setFillColor(UIColor.systemPink.cgColor)
            cgContext.move(to: CGPoint(x: circleRect.midX - 10, y: circleRect.maxY))
            cgContext.addLine(to: tipPoint)
            cgContext.addLine(to: CGPoint(x: circleRect.midX + 10, y: circleRect.maxY))
            cgContext.closePath()
            cgContext.fillPath()
            
            // Add white border around circle
            cgContext.setStrokeColor(UIColor.white.cgColor)
            cgContext.setLineWidth(3)
            cgContext.strokeEllipse(in: circleRect)
        }
    }
}
