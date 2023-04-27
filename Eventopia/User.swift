//
//  User.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 4/25/23.
//

import Foundation

import Foundation
import UIKit

class User {
    // Stored properties.
    var profilePic: UIImage?
    var firstName: String
    var lastName: String
    var email: String
    var addDate: Date
    //var friends: [Friend]?
    var userEvents: [Event]?
    var recentSearches: [String]?
    
    // Computed property.
    var fullName: String {
        get {
            return "\(firstName) \(lastName)"
        }
    }
    
    // Initializer.
    init(profilePic: UIImage? = nil, firstName: String, lastName: String, email: String, addDate: Date, userEvents: [Event]? = nil, recentSearches: [String]? = nil) {
        self.profilePic = profilePic
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.addDate = addDate
        //self.friends = friends
        self.userEvents = userEvents
        self.recentSearches = recentSearches
    }
}
