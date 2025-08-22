//
//  GoogleMapsView.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 01-04-2025.

import SwiftUI
import GoogleMaps
import CoreLocation

struct GoogleMapView: UIViewRepresentable {
    
    @ObservedObject var locationManager: LocationManager
    @Binding var recenterMap: Bool
    var feedItems: [PostItem]
    var onInteraction: ((Bool) -> Void)?
    var selectedFeedItem: PostItem?
    var shouldMoveToSelectedItem: Bool = true // New parameter to control automatic camera movement
    
    @Environment(\.colorScheme) var colorScheme
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapView
        var mapView: GMSMapView?
        private var isInitialLoad = true
        private var lastFeedItemCount = 0
        private var markerMap: [String: GMSMarker] = [:]
        private var isUserInteracting = false
        
        init(parent: GoogleMapView) {
            self.parent = parent
        }
        
        // MARK: - Map Delegate Methods
        func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
            if gesture {
                isUserInteracting = true
                parent.onInteraction?(true)
            }
        }
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {}
        
        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            if isUserInteracting {
                isUserInteracting = false
                parent.onInteraction?(false)
            }
        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            if let userData = marker.userData as? PostItem {
                print("📍 Tapped marker for post: \(userData.caption ?? "Unknown")")
                
                if let lat = userData.latitude, let long = userData.longitude {
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    moveCamera(to: coordinate, zoom: 10.0)
                }
            }
            return false
        }
        
        // MARK: - Camera and Markers Management
        func updateMapWithFeedItems(_ feedItems: [PostItem], mapView: GMSMapView) {
            guard feedItems.count != lastFeedItemCount else { return }
            lastFeedItemCount = feedItems.count
            
            clearAllMarkers(from: mapView)
            guard !feedItems.isEmpty else { return }
            
            var bounds = GMSCoordinateBounds()
            var hasValidCoordinates = false
            
            for item in feedItems {
                if let lat = item.latitude, let long = item.longitude {
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    let marker = createMarker(for: item, at: coordinate)
                    marker.map = mapView
                    markerMap[item.id] = marker
                    bounds = bounds.includingCoordinate(coordinate)
                    hasValidCoordinates = true
                }
            }
            
            if let userLocation = parent.locationManager.userLocation {
                bounds = bounds.includingCoordinate(userLocation.coordinate)
                hasValidCoordinates = true
            }
            
            if hasValidCoordinates && isInitialLoad {
                isInitialLoad = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let padding: CGFloat = 100
                    let update = GMSCameraUpdate.fit(bounds, withPadding: padding)
                    mapView.animate(with: update)
                }
            }
        }
        
        func moveCamera(to coordinate: CLLocationCoordinate2D, zoom: Float = 10.0) {
            guard let mapView = mapView else { return }
            let cameraUpdate = GMSCameraUpdate.setTarget(coordinate, zoom: zoom)
            mapView.animate(with: cameraUpdate)
        }
        
        func recenterToUserLocation() {
            guard let userLocation = parent.locationManager.userLocation else { return }
            moveCamera(to: userLocation.coordinate, zoom: 10.0)
        }
        
        private func createCustomMarkerIcon(imageUrl: String) -> UIImage {
            let markerSize = CGSize(width: 40, height: 40)
            let renderer = UIGraphicsImageRenderer(size: markerSize)
            
            return renderer.image { context in
                let rect = CGRect(origin: .zero, size: markerSize)
                context.cgContext.setFillColor(UIColor.systemBlue.cgColor)
                context.cgContext.fillEllipse(in: rect)
                context.cgContext.setStrokeColor(UIColor.white.cgColor)
                context.cgContext.setLineWidth(2)
                context.cgContext.strokeEllipse(in: rect)
                let placeholderImage = UIImage(systemName: "person.circle.fill")
                placeholderImage?.draw(in: rect.insetBy(dx: 5, dy: 5))
            }
        }
        
        private func createDefaultMarkerIcon(for item: PostItem) -> UIImage {
            let color: UIColor
            switch item.postType {
                case "event": color = .systemOrange
                case "activity": color = .systemGreen
                case "meetup": color = .systemPurple
                default: color = .systemBlue
            }
            return GMSMarker.markerImage(with: color)
        }
        
        private func clearAllMarkers(from mapView: GMSMapView) {
            markerMap.values.forEach { $0.map = nil }
            markerMap.removeAll()
        }
        
        // MARK: - Selected Item Handling
        func highlightSelectedMarker(_ selectedItem: PostItem?, shouldMoveCamera: Bool = true) {
            markerMap.values.forEach { $0.zIndex = 0 }
            if let selectedItem = selectedItem,
               let marker = markerMap[selectedItem.id] {
                marker.zIndex = 1000
                if shouldMoveCamera, let lat = selectedItem.latitude, let long = selectedItem.longitude {
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    moveCamera(to: coordinate, zoom: 10.0)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        let mapView = GMSMapView()
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = false
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = true
        mapView.delegate = context.coordinator
        context.coordinator.mapView = mapView
        
        if let userLocation = locationManager.userLocation {
            let camera = GMSCameraPosition.camera(
                withLatitude: userLocation.coordinate.latitude,
                longitude: userLocation.coordinate.longitude,
                zoom: 15.0
            )
            mapView.camera = camera
        }
        
        // 👇 Apply map style based on light/dark mode
        let styleName = colorScheme == .dark ? "mapDark" : "mapLight"
        if let url = Bundle.main.url(forResource: styleName, withExtension: "json") {
            do {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: url)
            } catch {
                print("❌ Failed to load map style: \(error)")
            }
        } else {
            print("❌ Could not find \(styleName).json in bundle")
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        if recenterMap {
            context.coordinator.recenterToUserLocation()
        }
        context.coordinator.updateMapWithFeedItems(feedItems, mapView: uiView)
        context.coordinator.highlightSelectedMarker(selectedFeedItem)
    }
}

// Updated extension to handle profile images
extension GoogleMapView.Coordinator {
    
    // Updated createMarker method with profile image support
    func createMarker(for item: PostItem, at coordinate: CLLocationCoordinate2D) -> GMSMarker {
        let marker = GMSMarker(position: coordinate)
        marker.title = item.user?.name ?? "Unknown User"
        marker.snippet = item.caption ?? ""
        marker.userData = item
        
        // Set default icon first
        marker.icon = MarkerIconCache.shared.getMarkerIcon(for: item.postType)
        
        // Try to load profile image if available
        if let profileImageUrl = item.user?.profilePicUrl, !profileImageUrl.isEmpty {
            MarkerIconCache.shared.getProfileMarkerIcon(imageUrl: profileImageUrl) { [weak marker] profileIcon in
                marker?.icon = profileIcon
            }
        }
        
        return marker
    }
}
