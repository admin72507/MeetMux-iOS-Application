////
////  CustomMarkerScene.swift
////  meetX-iOS
////
////  Created by Karthick Thavasimuthu on 02-04-2025.
////
import UIKit
import GoogleMaps
import Kingfisher


final class CustomMarkerHandler {
    
    static func renderViewAsImage(view: UIView) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        return renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
    }
    
    static func addCustomMarker(to mapView: GMSMapView, at coordinate: CLLocationCoordinate2D, imageURL: String, title: String, snippet: String) {
        
        let markerView = CustomMarkerView(imageURL: imageURL)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let markerImage = self.renderViewAsImage(view: markerView) {
                let marker = GMSMarker()
                marker.position = coordinate
                marker.title = title
                marker.snippet = snippet
                marker.icon = markerImage
                marker.map = mapView
                
                marker.appearAnimation = .pop
                marker.tracksInfoWindowChanges = true // ✅ Ensures updates work
            } else {
                print("⚠️ Failed to render marker view as UIImage")
            }
        }
    }
}

class CustomMarkerView: UIView {
    
    private let containerView = UIView()
    private let innerPaddingView = UIView()
    private let imageView = UIImageView()
    
    init(imageURL: String) {
        super.init(frame: CGRect(x: 0, y: 0, width: 60, height: 75)) // Adjusted height for pin
        
        setupContainerView()
        setupInnerPaddingView()
        setupImageView()
        setupPinShape()
        loadImage(from: imageURL)
    }
    
    private func setupContainerView() {
        containerView.frame = CGRect(x: 5, y: 5, width: 50, height: 50) // Outer circle with border
        containerView.layer.cornerRadius = containerView.bounds.width / 2
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.blue.cgColor
        containerView.layer.masksToBounds = true
        applyGradientBackground()
        addSubview(containerView)
    }
    
    private func setupInnerPaddingView() {
        let padding: CGFloat = 4 // Adjust padding here
        innerPaddingView.frame = CGRect(
            x: padding,
            y: padding,
            width: containerView.bounds.width - 2 * padding,
            height: containerView.bounds.height - 2 * padding
        )
        innerPaddingView.backgroundColor = .white // Padding color
        innerPaddingView.layer.cornerRadius = innerPaddingView.bounds.width / 2
        innerPaddingView.layer.masksToBounds = true
        containerView.addSubview(innerPaddingView)
    }
    
    private func setupImageView() {
        imageView.frame = innerPaddingView.bounds
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = innerPaddingView.bounds.width / 2
        imageView.layer.masksToBounds = true
        innerPaddingView.addSubview(imageView)
    }
    
    private func setupPinShape() {
        let pinHeight: CGFloat = 10
        let pinWidth: CGFloat = 14
        
        let pinPath = UIBezierPath()
        pinPath.move(to: CGPoint(x: (self.bounds.width - pinWidth) / 2, y: containerView.frame.maxY))
        pinPath.addLine(to: CGPoint(x: self.bounds.width / 2, y: containerView.frame.maxY + pinHeight))
        pinPath.addLine(to: CGPoint(x: (self.bounds.width + pinWidth) / 2, y: containerView.frame.maxY))
        pinPath.close()
        
        let pinLayer = CAShapeLayer()
        pinLayer.path = pinPath.cgPath
        pinLayer.fillColor = UIColor.blue.cgColor
        layer.addSublayer(pinLayer)
    }
    
    private func applyGradientBackground() {
        let gradientLayer = ThemeManager.purpleCAGradient
        gradientLayer.frame = containerView.bounds
        gradientLayer.cornerRadius = containerView.bounds.width / 2
        containerView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func loadImage(from url: String) {
        if let url = URL(string: url) {
            imageView.kf.setImage(with: url) { result in
                switch result {
                    case .success:
                        self.setNeedsDisplay()
                    case .failure:
                        self.setPlaceholderImage()
                }
            }
        } else {
            setPlaceholderImage()
        }
    }
    
    private func setPlaceholderImage() {
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .bold)
        imageView.image = UIImage(systemName: "person.circle.fill", withConfiguration: config)
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
