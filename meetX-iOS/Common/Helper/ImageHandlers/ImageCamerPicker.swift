//
//  KeyboardManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 27-06-2025.
//
import SwiftUI
import UIKit

// MARK: - Camera Picker with Direct Crop
struct CameraPicker: UIViewControllerRepresentable {
    var didFinishPicking: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = context.coordinator
        imagePicker.allowsEditing = true
        imagePicker.showsCameraControls = true
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: CameraPicker
        
        init(parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                picker.dismiss(animated: true) {
                    self.parent.didFinishPicking(editedImage)
                }
            } else if let originalImage = info[.originalImage] as? UIImage {
                // fallback if editing failed
                picker.dismiss(animated: true) {
                    self.parent.didFinishPicking(originalImage)
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
