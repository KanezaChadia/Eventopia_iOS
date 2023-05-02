//
//  Image.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 5/1/23.
//

import Foundation
import UIKit
import Firebase

class Image {
    // Stored properties.
    var image: UIImage?
    var imgUrl: String
    var userId: String
    
    // Computed properties.
    var userName: String {
        get {
            
            return "You"
         
        }
    }
    
    var userProfilePic: UIImage {
        get {
            
            return CurrentUser.currentUser?.profilePic ?? UIImage(named: "logo_placeholder")!
        }
    }
    
    // Initializer.
    init(image: UIImage? = nil, imgUrl: String, userId: String) {
        self.image = image
        self.imgUrl = imgUrl
        self.userId = userId
    }
}
