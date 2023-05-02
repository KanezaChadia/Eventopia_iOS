//
//  ImageHelper.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 4/28/23.
//

import Foundation
import UIKit
import PhotosUI

protocol GetImageDelegate {
    func getImageFromUrl(imageUrl: String) -> UIImage
}

protocol GetPhotoCameraPermissionsDelegate {
    func getPhotosPermissions() async -> Bool
    func getCameraPermissions() async -> Bool
}

class GetImageHelper: GetImageDelegate, GetPhotoCameraPermissionsDelegate {
    
    
    func getImageFromUrl(imageUrl: String) -> UIImage {
        // Get event image.
        var eventImage = UIImage(named: "logo_placeholder")
        
        // Check that imageUrl contains a URL string by checking for "http" in the string.
        if imageUrl.contains("http"),
           let url = URL(string: imageUrl),
           // Create URLComponent object to convert URL from "http" (not secure) to "https" (secure).
           var urlComp = URLComponents(url: url, resolvingAgainstBaseURL: false) {

            urlComp.scheme = "https"

            if let secureURL = urlComp.url {
                // Retrieve image from secureURL created above.
                do {
                    eventImage = UIImage(data: try Data.init(contentsOf: secureURL))!
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
        
        return eventImage!
    }
    
    func getPhotosPermissions() async -> Bool {
        
            let authorizationStatus = PHPhotoLibrary.authorizationStatus()
            
            switch authorizationStatus {
            case .authorized:
                return true
                
            case .notDetermined:
                let status = Task.init { () -> Bool in
                    return await PHPhotoLibrary.requestAuthorization(for: .readWrite) == .authorized
                }
                
                return await status.value
                
            case .limited:
                print("limited")
                return false
                
            case .restricted, .denied:
                // Present alert to notify user that photo library access is needed.
                print("restricted or denied")
                return false

            @unknown default:
                print("something else")
                // Present alert to notify user that photo library access status is unknown.
                return false
            }
    }
    
    func getCameraPermissions() async -> Bool {
        
            let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            
            switch authorizationStatus {
            case .authorized:
                return true
                
            case .notDetermined:
                let status = Task.init { () -> Bool in
                    return await AVCaptureDevice.requestAccess(for: .video)
                }
                
                return await status.value

            case .restricted, .denied:
                print("restricted or denied")
                // Present alert to notify user that camera access is needed.
                return false
                
            @unknown default:
                print("something else")
                // Present alert to notify user that camera access status is unknown.
                return false
            }
    }
    

    
    
}


extension UIImage {
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )

        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return scaledImage
    }
}
